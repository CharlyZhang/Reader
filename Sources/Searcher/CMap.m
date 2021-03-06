#import "CMap.h"

static NSSet *sharedOperators = nil;
static NSCharacterSet *sharedTagSet = nil;
static NSCharacterSet *sharedTokenDelimimerSet = nil;
static NSString *kOperatorKey = @"CurrentOperator";

NSValue *rangeValue(unsigned int from, unsigned int to)
{
	return [NSValue valueWithRange:NSMakeRange(from, to-from)];
}

@implementation Operator

+ (Operator *)operatorWithStart:(NSString *)start end:(NSString *)end handler:(SEL)handler
{
	Operator *op = [[[Operator alloc] init] autorelease];
	op.start = start;
	op.end = end;
	op.handler = handler;
	return op;
}

@synthesize start, end, handler;
@end

@implementation CharacterRangeMapping

@synthesize type;

- (id)initWithType:(CharacterRangeMappingType)t forRange:(NSRange)r
{
    if (self = [super init]) {
        type = t;
        range = r;
        values = [[NSMutableArray alloc]init];
        completed = NO;
    }
    return self;
}

- (void)addValue:(NSNumber*)value
{
    [values addObject:value];
}

- (void)finishAdd                          ///for MAPPING_TYPE_N_N
{
    completed = YES;
}

- (unichar)valueForCID:(unichar)cid
{
    NSNumber *value;
    if (type == MAPPING_TYPE_N_1) {
        value = [values objectAtIndex:0];
        return cid - range.location + [value intValue];
        
    } else if (type == MAPPING_TYPE_N_N) {
        if (cid - range.location + 1 > [values count]) {
            NSLog(@"Error, <from> <to> <offsetrange>, offsetrange is shorter");
        } else {
            value = [values objectAtIndex: (cid - range.location)];
            return [value intValue];
        }
    }
    
    return 0;
}

- (void)dealloc
{
    [values release];
    [super dealloc];
}
@end


@interface CMap ()
- (void)handleCodeSpaceRange:(NSString *)string;
- (void)handleCharacter:(NSString *)string;
- (void)handleCharacterRange:(NSString *)string;
- (void)parse:(NSString *)cMapString;
@property (readonly) NSCharacterSet *tokenDelimiterSet;
@property (nonatomic, retain) NSMutableDictionary *context;
@property (nonatomic, readonly) NSCharacterSet *tagSet;
@property (nonatomic, readonly) NSSet *operators;
@end

@implementation CMap

- (id)initWithString:(NSString *)string
{
	if ((self = [super init]))
	{
		[self parse:string];
	}
	return self;
}

- (id)initWithPDFStream:(CGPDFStreamRef)stream
{
	NSData *data = (NSData *) CGPDFStreamCopyData(stream, nil);
	NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    id obj = [self initWithString:text];
    [text release];
    [data release];
    return obj;
}

- (BOOL)isInCodeSpaceRange:(unichar)cid
{
	for (NSValue *rangeValue in self.codeSpaceRanges)
	{
		NSRange range = [rangeValue rangeValue];
		if (cid >= range.location && cid <= NSMaxRange(range))
		{
			return YES;
		}
	}
	return NO;
}

/**!
 * Returns the unicode value mapped by the given character ID
 */
- (unichar)unicodeCharacter:(unichar)cid
{
	if (![self isInCodeSpaceRange:cid]) return 0;

	NSArray	*mappedRanges = [self.characterRangeMappings allKeys];
	for (NSValue *rangeValue in mappedRanges)
	{
		NSRange range = [rangeValue rangeValue];
		if (cid >= range.location && cid <= NSMaxRange(range))
		{
            CharacterRangeMapping *mapping = [self.characterRangeMappings objectForKey:rangeValue];
            return [mapping valueForCID:cid];
		}
	}
	
	NSArray *mappedValues = [self.characterMappings allKeys];
	for (NSNumber *from in mappedValues)
	{
		if ([from intValue] == cid)
		{
			return [[self.characterMappings objectForKey:from] intValue];
		}
	}
	
	return (unichar) NSNotFound;
}

- (NSSet *)operators
{
	@synchronized (self)
	{
		if (!sharedOperators)
		{
			sharedOperators = [[NSMutableSet alloc] initWithObjects:
							   [Operator operatorWithStart:@"begincodespacerange" 
														end:@"endcodespacerange"
													handler:@selector(handleCodeSpaceRange:)],
							   [Operator operatorWithStart:@"beginbfchar" 
													   end:@"endbfchar" 
												   handler:@selector(handleCharacter:)],
							   [Operator operatorWithStart:@"beginbfrange" 
													   end:@"endbfrange" 
												   handler:@selector(handleCharacterRange:)],
			nil];
		}
		return sharedOperators;
	}
}

#pragma mark -
#pragma mark Scanner

- (Operator *)operatorWithStartingToken:(NSString *)token
{
	for (Operator *op in self.operators)
	{
		if ([op.start isEqualToString:token]) return op;
	}
	return nil;
}

/**!
 * Returns the next token that is not a comment. Only remainder-of-line comments are supported.
 * The scanner is advanced to past the returned token.
 *
 * @param scanner a scanner
 * @return next non-comment token
 */
- (NSString *)tokenByTrimmingComments:(NSScanner *)scanner
{
	NSString *token = nil;
	[scanner scanUpToCharactersFromSet:self.tokenDelimiterSet intoString:&token];

    NSUInteger *len = [token length];
    if (len == 0) {
        if (![scanner isAtEnd]) {
            [scanner setScanLocation:[scanner scanLocation]+1];
        }
        return [self tokenByTrimmingComments:scanner];
    }
    
	static NSString *commentMarker = @"%%";
	NSRange commentMarkerRange = [token rangeOfString:commentMarker];
	if (token && commentMarkerRange.location != NSNotFound)
	{
		[scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet] intoString:nil];
		token = [token substringToIndex:commentMarkerRange.location];
		if (token.length == 0)
		{
			return [self tokenByTrimmingComments:scanner];
		}
	}
	
	return token;
}

/**!
 * Parse a CMap.
 *
 * @param cMapString string representation of a CMap
 */
- (void)parse:(NSString *)cMapString
{
	NSScanner *scanner = [NSScanner scannerWithString:cMapString];
	NSString *token = nil;
	while (![scanner isAtEnd])
	{
		token = [self tokenByTrimmingComments:scanner];

		Operator *operator = [self operatorWithStartingToken:token];
		if (operator)
		{
			// Start a new context
			self.context = [NSMutableDictionary dictionaryWithObject:operator forKey:kOperatorKey];
		}
		else if (self.context)
		{
			operator = [self.context valueForKey:kOperatorKey];
			if ([token isEqualToString:operator.end])
			{
				// End the current context
				self.context = nil;
			}
			else
			{
				// Send input to the current context
				[self performSelector:operator.handler withObject:token];
			}
		}
	}
}


#pragma mark -
#pragma mark Parsing handlers

/**!
 * Trims tag characters from the argument string, and returns the parsed integer value of the string.
 *
 * @param tagString string representing a hexadecimal number, possibly within tags
 */
- (unsigned int)valueOfTag:(NSString *)tagString
{
	unsigned int numericValue = 0;
	tagString = [tagString stringByTrimmingCharactersInSet:self.tagSet];
	[[NSScanner scannerWithString:tagString] scanHexInt:&numericValue];
	return numericValue;
}

/**!
 * Code space ranges are pairs of hex numbers:
 *	<from> <to>
 */
- (void)handleCodeSpaceRange:(NSString *)string
{
	static NSString *rangeLowerBound = @"MIN";
	NSNumber *value = [NSNumber numberWithInt:[self valueOfTag:string]];
	NSNumber *low = [self.context valueForKey:rangeLowerBound];

	if (!low)
	{
		[self.context setValue:value forKey:rangeLowerBound];
		return;
	}
	
	[self.codeSpaceRanges addObject:rangeValue([low intValue], [value intValue])];
	[self.context removeObjectForKey:rangeLowerBound];
}

/**!
 * Character mappings appear in pairs:
 *	<from> <to>
 */
- (void)handleCharacter:(NSString *)character
{
	NSNumber *value = [NSNumber numberWithInt:[self valueOfTag:character]];
	static NSString *origin = @"Origin";
	NSNumber *from = [self.context valueForKey:origin];
	if (!from)
	{
		[self.context setValue:value forKey:origin];
		return;
	}
	[self.characterMappings setObject:value forKey:from];
	[self.context removeObjectForKey:origin];
}

/**!
 * Ranges appear on the triplet form:
 *	<from> <to> <offset>
 */
- (void)handleCharacterRange:(NSString *)token
{
    int state = 0;
    NSRange checkRange;
    
    checkRange = [token rangeOfString:@"["];
    if (checkRange.location != NSNotFound) {
        state = 1;
        token = [token substringFromIndex:checkRange.location+checkRange.length];
    } else {
        checkRange = [token rangeOfString:@"]" options:NSBackwardsSearch];
        if (checkRange.location != NSNotFound) {
            state = -1;
            token = [token substringToIndex:checkRange.location];
        }
    }
    
	NSNumber *value = [NSNumber numberWithInt:[self valueOfTag:token]];
	static NSString *from = @"From";
	static NSString *to = @"To";
	NSNumber *fromValue = [self.context valueForKey:from];
	NSNumber *toValue = [self.context valueForKey:to];
	if (!fromValue)
	{
		[self.context setValue:value forKey:from];
		return;
	}
	else if (!toValue)
	{
		[self.context setValue:value forKey:to];
		return;
	}
    
	NSValue *range = rangeValue([fromValue intValue], [toValue intValue]);
    CharacterRangeMapping *mapping = [self.characterRangeMappings objectForKey:range];
    if (!mapping) {
        if (state == 0) {
            mapping = [[CharacterRangeMapping alloc]initWithType:MAPPING_TYPE_N_1 forRange:[range rangeValue]];
        } else if (state == 1){
            mapping = [[CharacterRangeMapping alloc]initWithType:MAPPING_TYPE_N_N forRange:[range rangeValue]];
        } else {
            NSLog(@"Error, <from> <to> <offsetrange>, no range beginning");
        }
    }
    if(state != -1) [mapping addValue:value];
    else            [mapping finishAdd];
    
    if (state == -1 || mapping.type == MAPPING_TYPE_N_1) {
        [self.context removeObjectForKey:from];
        [self.context removeObjectForKey:to];
    }
    
    [self.characterRangeMappings setObject:mapping forKey:range];
}

#pragma mark -
#pragma mark Accessor methods

- (NSCharacterSet *)tagSet {
	if (!sharedTagSet) {
		sharedTagSet = [[NSCharacterSet characterSetWithCharactersInString:@"<>"] retain];
	}
	return sharedTagSet;
}

- (NSCharacterSet *)tokenDelimiterSet {
	if (!sharedTokenDelimimerSet) {
        NSMutableCharacterSet *mcs = [[NSMutableCharacterSet characterSetWithCharactersInString:@">"] retain];
        [mcs formUnionWithCharacterSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        sharedTokenDelimimerSet = mcs;

	}
	return sharedTokenDelimimerSet;
}

- (NSMutableArray *)codeSpaceRanges {
	if (!codeSpaceRanges) {
		codeSpaceRanges = [[NSMutableArray alloc] init];
	}
	return codeSpaceRanges;
}

- (NSMutableDictionary *)characterMappings {
	if (!characterMappings) {
		characterMappings = [[NSMutableDictionary alloc] init];
	}
	return characterMappings;
}

- (NSMutableDictionary *)characterRangeMappings {
	if (!characterRangeMappings) {
		self.characterRangeMappings = [NSMutableDictionary dictionary];
	}
	return characterRangeMappings;
}

- (void)dealloc
{
	[offsets release];
	[codeSpaceRanges release];
	[super dealloc];
}

@synthesize operators, context;
@synthesize codeSpaceRanges, characterMappings, characterRangeMappings;
@end

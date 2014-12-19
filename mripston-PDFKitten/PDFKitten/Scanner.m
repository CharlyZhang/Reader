#import "Scanner.h"
#import "Util.h"

#pragma mark 

@interface Scanner ()

#pragma mark - Text showing

// Text-showing operators
void Tj(CGPDFScannerRef scanner, void *info);
void quot(CGPDFScannerRef scanner, void *info);
void doubleQuot(CGPDFScannerRef scanner, void *info);
void TJ(CGPDFScannerRef scanner, void *info);

#pragma mark Text positioning

// Text-positioning operators
void Td(CGPDFScannerRef scanner, void *info);
void TD(CGPDFScannerRef scanner, void *info);
void Tm(CGPDFScannerRef scanner, void *info);
void TStar(CGPDFScannerRef scanner, void *info);

#pragma mark Text state

// Text state operators
void BT(CGPDFScannerRef scanner, void *info);
void Tc(CGPDFScannerRef scanner, void *info);
void Tw(CGPDFScannerRef scanner, void *info);
void Tz(CGPDFScannerRef scanner, void *info);
void TL(CGPDFScannerRef scanner, void *info);
void Tf(CGPDFScannerRef scanner, void *info);
void Ts(CGPDFScannerRef scanner, void *info);

#pragma mark Graphics state

// Special graphics state operators
void q(CGPDFScannerRef scanner, void *info);
void Q(CGPDFScannerRef scanner, void *info);
void cm(CGPDFScannerRef scanner, void *info);

@property (nonatomic, retain) Selection *currentSelection;
@property (nonatomic, readonly) RenderingState *currentRenderingState;
@property (nonatomic, readonly) Font *currentFont;
@property (nonatomic, readonly) CGPDFDocumentRef pdfDocument;
@property (nonatomic, copy) NSURL *documentURL;

/* Returts the operator callbacks table for scanning page stream */
@property (nonatomic, readonly) CGPDFOperatorTableRef operatorTable;

@end

#pragma mark

@implementation Scanner


#pragma mark - Properties

- (NSMutableString*)content
{
    if (!_content) {
        _content = [[NSMutableString alloc]init];
    }
    
    return _content;
}

#pragma mark - Initialization

- (id)initWithDocument:(CGPDFDocumentRef)document
{
	if ((self = [super init]))
	{
		pdfDocument = CGPDFDocumentRetain(document);
		self.content = [NSMutableString string];
	}
	return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
	if ((self = [super init]))
	{
		self.documentURL = [NSURL fileURLWithPath:path];
	}
	return self;
}

#pragma mark Scanner state accessors

- (RenderingState *)currentRenderingState
{
	return [self.renderingStateStack topRenderingState];
}

- (Font *)currentFont
{
	return self.currentRenderingState.font;
}

- (CGPDFDocumentRef)pdfDocument
{
	if (!pdfDocument)
	{
		pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef)self.documentURL);
	}
	return pdfDocument;
}

/* The operator table used for scanning PDF pages */
- (CGPDFOperatorTableRef)operatorTable
{
	if (operatorTable)
	{
		return operatorTable;
	}
	
	operatorTable = CGPDFOperatorTableCreate();

	// Text-showing operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tj", Tj);
	CGPDFOperatorTableSetCallback(operatorTable, "\'", quot);
	CGPDFOperatorTableSetCallback(operatorTable, "\"", doubleQuot);
	CGPDFOperatorTableSetCallback(operatorTable, "TJ", TJ);
	
	// Text-positioning operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tm", Tm);
	CGPDFOperatorTableSetCallback(operatorTable, "Td", Td);		
	CGPDFOperatorTableSetCallback(operatorTable, "TD", TD);
	CGPDFOperatorTableSetCallback(operatorTable, "T*", TStar);
	
	// Text state operators
	CGPDFOperatorTableSetCallback(operatorTable, "Tw", Tw);
	CGPDFOperatorTableSetCallback(operatorTable, "Tc", Tc);
	CGPDFOperatorTableSetCallback(operatorTable, "TL", TL);
	CGPDFOperatorTableSetCallback(operatorTable, "Tz", Tz);
	CGPDFOperatorTableSetCallback(operatorTable, "Ts", Ts);
	CGPDFOperatorTableSetCallback(operatorTable, "Tf", Tf);
	
	// Graphics state operators
	CGPDFOperatorTableSetCallback(operatorTable, "cm", cm);
	CGPDFOperatorTableSetCallback(operatorTable, "q", q);
	CGPDFOperatorTableSetCallback(operatorTable, "Q", Q);
	
	CGPDFOperatorTableSetCallback(operatorTable, "BT", BT);
	
	return operatorTable;
}

/* Create a font dictionary given a PDF page */
- (FontCollection *)fontCollectionWithPage:(CGPDFPageRef)page
{
	CGPDFDictionaryRef dict = CGPDFPageGetDictionary(page);
	if (!dict)
	{
		NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing");
		return nil;
	}
	CGPDFDictionaryRef resources;
	if (!CGPDFDictionaryGetDictionary(dict, "Resources", &resources))
	{
		NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing Resources dictionary");
		return nil;	
	}
	CGPDFDictionaryRef fonts;
	if (!CGPDFDictionaryGetDictionary(resources, "Font", &fonts)) return nil;

#ifdef DEBUG    /// show all the items in fonts dictionary
    int level = 0;
    CGPDFDictionaryApplyFunction(fonts,didScanDict,&level);
#endif
	FontCollection *collection = [[FontCollection alloc] initWithFontDictionary:fonts];
	return [collection autorelease];
}

/* Scan the given page of the current document */
- (void)scanDocumentPage:(NSUInteger)pageNumber
{
	CGPDFPageRef page = CGPDFDocumentGetPage(self.pdfDocument, pageNumber);
    [self scanPage:page];
}

#pragma mark Start scanning

- (void)scanPage:(CGPDFPageRef)page
{
	// Return immediately if no keyword set
	if (!keyword) return;
    
    [self.stringDetector reset];
    [self.content setString:@""];
    
    self.stringDetector.keyword = self.keyword;

    // Initialize font collection (per page)
	self.fontCollection = [self fontCollectionWithPage:page];
    
	CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(page);
	CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, self.operatorTable, self);
	CGPDFScannerScan(scanner);
	CGPDFScannerRelease(scanner); scanner = nil;
	CGPDFContentStreamRelease(contentStream); contentStream = nil;
}


#pragma mark StringDetectorDelegate

- (void)detector:(StringDetector *)detector didScanCharacter:(unichar)character
{
	RenderingState *state = [self currentRenderingState];
	CGFloat width = [self.currentFont widthOfCharacter:character withFontSize:state.fontSize];
	width /= 1000;
	width += state.characterSpacing;
	if (character == 32)
	{
		width += state.wordSpacing;
	}
	[state translateTextPosition:CGSizeMake(width, 0)];
}

- (void)detector:(StringDetector *)detector didStartMatchingString:(NSString *)string
{
	Selection *sel = [[Selection alloc] initWithStartState:self.currentRenderingState];
	self.currentSelection = sel;
	[sel release];
}

- (void)detector:(StringDetector *)detector foundString:(NSString *)needle
{	
	RenderingState *state = [[self renderingStateStack] topRenderingState];
	[self.currentSelection finalizeWithState:state];

	if (self.currentSelection)
	{
		[self.selections addObject:self.currentSelection];
		self.currentSelection = nil;
	}
}

#pragma mark Line Content

- (void)didScanOneLine
{
    int selNum = [self.selections count];
    
    /// set current line content to the past unset selections
    for (int i = selNum-1; i >= 0; i--) {
        Selection *sel = [self.selections objectAtIndex:i];
        if (sel.lineContent)    break;
        
        sel.lineContent = [NSString stringWithString:self.content];
    }
    
    [self.content setString:@""];
}

#pragma mark - Scanner callbacks

void BT(CGPDFScannerRef scanner, void *info)
{
	[[(Scanner *)info currentRenderingState] setTextMatrix:CGAffineTransformIdentity replaceLineMatrix:YES];
}

/* Pops the requested number of values, and returns the number of values popped */
// !!!: Make sure this is correct, then use it
int popIntegers(CGPDFScannerRef scanner, CGPDFInteger *buffer, size_t length)
{
    bzero(buffer, length);
    CGPDFInteger value;
    int i = 0;
    while (i < length)
    {
        if (!CGPDFScannerPopInteger(scanner, &value)) break;
        buffer[i] = value;
        i++;
    }
    return i;
}

#pragma mark Text showing operators

void didScanSpace(float value, Scanner *scanner)
{
    float width = [scanner.currentRenderingState convertToUserSpace:value];
    [scanner.currentRenderingState translateTextPosition:CGSizeMake(-width, 0)];
    if (abs(value) >= [scanner.currentRenderingState.font widthOfSpace])
    {
        [scanner.stringDetector reset];
        //NSLog(@"didScanSpace and reset %f",value);
        [scanner.content appendString:@" "];
    }
}

/* Called any time the scanner scans a string */
void didScanString(CGPDFStringRef pdfString, Scanner *scanner)
{
	NSString *string = [[scanner stringDetector] appendPDFString:pdfString withFont:[scanner currentFont]];
	[[scanner content] appendString:string];
}

/* Show a string */
void Tj(CGPDFScannerRef scanner, void *info)
{
	CGPDFStringRef pdfString = nil;
	if (!CGPDFScannerPopString(scanner, &pdfString)) return;
	didScanString(pdfString, info);
}

/* Equivalent to operator sequence [T*, Tj] */
void quot(CGPDFScannerRef scanner, void *info)
{
	TStar(scanner, info);
	Tj(scanner, info);
}

/* Equivalent to the operator sequence [Tw, Tc, '] */
void doubleQuot(CGPDFScannerRef scanner, void *info)
{
	Tw(scanner, info);
	Tc(scanner, info);
	quot(scanner, info);
}

/* Array of strings and spacings */
void TJ(CGPDFScannerRef scanner, void *info)
{
	CGPDFArrayRef array = nil;
	CGPDFScannerPopArray(scanner, &array);
    size_t count = CGPDFArrayGetCount(array);
	for (int i = 0; i < count; i++)
	{
		CGPDFObjectRef object = nil;
		CGPDFArrayGetObject(array, i, &object);
		CGPDFObjectType type = CGPDFObjectGetType(object);
        switch (type)
        {
            case kCGPDFObjectTypeString:
            {
                CGPDFStringRef pdfString;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &pdfString))
                {
                    didScanString(pdfString, info);
#ifdef DEBUG
//                    Scanner *scanner = (Scanner*)info;
//                    NSString *string = [[scanner stringDetector] appendPDFString:pdfString withFont:[scanner currentFont]];
//                    NSLog(@" - %@",string);
#endif
                }
                break;
            }
            case kCGPDFObjectTypeReal:
            {
                CGPDFReal tx;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeReal, &tx))
                {
                    didScanSpace(tx, info);
                }
                break;
            }
            case kCGPDFObjectTypeInteger:
            {
                CGPDFInteger tx;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &tx))
                {
                    didScanSpace(tx, info);
                }
                break;
            }
            default:
                NSLog(@"Scanner: TJ: Unsupported type: %d", type);
                break;
        }
	}
}

#pragma mark Text positioning operators

/* Move to start of next line */
void Td(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal tx = 0, ty = 0;
	CGPDFScannerPopNumber(scanner, &ty);
	CGPDFScannerPopNumber(scanner, &tx);
	[[(Scanner *)info currentRenderingState] newLineWithLeading:-ty indent:tx save:NO];
#ifdef DEBUG
    NSLog(@"Td -- %@",[(Scanner *)info content]);
#endif
    [(Scanner *)info didScanOneLine];
}

/* Move to start of next line, and set leading */
void TD(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal tx, ty;
	if (!CGPDFScannerPopNumber(scanner, &ty)) return;
	if (!CGPDFScannerPopNumber(scanner, &tx)) return;
	[[(Scanner *)info currentRenderingState] newLineWithLeading:-ty indent:tx save:YES];
    
#ifdef DEBUG
    NSLog(@"TD -- %@",[(Scanner *)info content]);
#endif
    [(Scanner *)info didScanOneLine];
}

/* Set line and text matrixes */
void Tm(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal a, b, c, d, tx, ty;
	if (!CGPDFScannerPopNumber(scanner, &ty)) return;
	if (!CGPDFScannerPopNumber(scanner, &tx)) return;
	if (!CGPDFScannerPopNumber(scanner, &d)) return;
	if (!CGPDFScannerPopNumber(scanner, &c)) return;
	if (!CGPDFScannerPopNumber(scanner, &b)) return;
	if (!CGPDFScannerPopNumber(scanner, &a)) return;
	CGAffineTransform t = CGAffineTransformMake(a, b, c, d, tx, ty);
	[[(Scanner *)info currentRenderingState] setTextMatrix:t replaceLineMatrix:YES];

#ifdef DEBUG
    NSLog(@"Tm -- %@",[(Scanner *)info content]);
#endif
    [(Scanner *)info didScanOneLine];
}

/* Go to start of new line, using stored text leading */
void TStar(CGPDFScannerRef scanner, void *info)
{
	[[(Scanner *)info currentRenderingState] newLine];
}

#pragma mark Text State operators

/* Set character spacing */
void Tc(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal charSpace;
	if (!CGPDFScannerPopNumber(scanner, &charSpace)) return;
	[[(Scanner *)info currentRenderingState] setCharacterSpacing:charSpace];
}

/* Set word spacing */
void Tw(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal wordSpace;
	if (!CGPDFScannerPopNumber(scanner, &wordSpace)) return;
	[[(Scanner *)info currentRenderingState] setWordSpacing:wordSpace];
}

/* Set horizontal scale factor */
void Tz(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal hScale;
	if (!CGPDFScannerPopNumber(scanner, &hScale)) return;
	[[(Scanner *)info currentRenderingState] setHorizontalScaling:hScale];
}

/* Set text leading */
void TL(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal leading;
	if (!CGPDFScannerPopNumber(scanner, &leading)) return;
	[[(Scanner *)info currentRenderingState] setLeadning:leading];
}

/* Font and font size */
void Tf(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal fontSize;
	const char *fontName;
	if (!CGPDFScannerPopNumber(scanner, &fontSize)) return;
	if (!CGPDFScannerPopName(scanner, &fontName)) return;
	
	RenderingState *state = [(Scanner *)info currentRenderingState];
	Font *font = [[(Scanner *)info fontCollection] fontNamed:[NSString stringWithUTF8String:fontName]];
	[state setFont:font];
	[state setFontSize:fontSize];
}

/* Set text rise */
void Ts(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal rise;
	if (!CGPDFScannerPopNumber(scanner, &rise)) return;
	[[(Scanner *)info currentRenderingState] setTextRise:rise];
}


#pragma mark Graphics state operators

/* Push a copy of current rendering state */
void q(CGPDFScannerRef scanner, void *info)
{
	RenderingStateStack *stack = [(Scanner *)info renderingStateStack];
	RenderingState *state = [[(Scanner *)info currentRenderingState] copy];
	[stack pushRenderingState:state];
	[state release];
}

/* Pop current rendering state */
void Q(CGPDFScannerRef scanner, void *info)
{
	[[(Scanner *)info renderingStateStack] popRenderingState];
}

/* Update CTM */
void cm(CGPDFScannerRef scanner, void *info)
{
	CGPDFReal a, b, c, d, tx, ty;
	if (!CGPDFScannerPopNumber(scanner, &ty)) return;
	if (!CGPDFScannerPopNumber(scanner, &tx)) return;
	if (!CGPDFScannerPopNumber(scanner, &d)) return;
	if (!CGPDFScannerPopNumber(scanner, &c)) return;
	if (!CGPDFScannerPopNumber(scanner, &b)) return;
	if (!CGPDFScannerPopNumber(scanner, &a)) return;
	
	RenderingState *state = [(Scanner *)info currentRenderingState];
	CGAffineTransform t = CGAffineTransformMake(a, b, c, d, tx, ty);
	state.ctm = CGAffineTransformConcat(state.ctm, t);
}


#pragma mark -
#pragma mark Memory management

- (RenderingStateStack *)renderingStateStack
{
	if (!renderingStateStack)
	{
		renderingStateStack = [[RenderingStateStack alloc] init];
	}
	return renderingStateStack;
}

- (StringDetector *)stringDetector
{
	if (!stringDetector)
	{
		stringDetector = [[StringDetector alloc] initWithKeyword:self.keyword];
		stringDetector.delegate = self;
	}
	return stringDetector;
}

- (NSMutableArray *)selections
{
	if (!selections)
	{
		selections = [[NSMutableArray alloc] init];
	}
	return selections;
}

- (void)dealloc
{
	CGPDFOperatorTableRelease(operatorTable);
	[currentSelection release];
	[fontCollection release];
	[renderingStateStack release];
	[keyword release]; keyword = nil;
	[stringDetector release];
	[documentURL release]; documentURL = nil;
	CGPDFDocumentRelease(pdfDocument); pdfDocument = nil;
	[_content release];
    [selections release];
	[super dealloc];
}


#define kHeaderLength 6
+ (NSString*)getStringFromStream:(CGPDFStreamRef) stream
{
    unsigned char buf[4096];
    
    NSString* ret = NULL;
    NSData *data = (NSData *) CGPDFStreamCopyData(stream, nil);
    
    // ASCII segment length (little endian)
    unsigned char *bytes = (uint8_t *) [data bytes];
    if (bytes[0] == 0x80)
    {
        size_t asciiTextLength = bytes[2] | bytes[3] << 8 | bytes[4] << 16 | bytes[5] << 24;
        NSData *textData = [[NSData alloc] initWithBytes:bytes+kHeaderLength length:asciiTextLength];
        ret = [[NSString alloc] initWithData:textData encoding:NSASCIIStringEncoding];
        [textData release];
    }
    else
    {
        ret = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        memcpy(buf, bytes, 4096);
    }
    
    [data release];
    
#ifdef DEBUG
    NSLog(@"%@",ret);
#endif
    return ret;
}

+ (NSString*)getStringFromDict:(CGPDFDictionaryRef)dict atKey:(NSString*)key
{
    NSString* ret = NULL;
    
    /// get the key
    const char* kKey = [key cStringUsingEncoding:NSASCIIStringEncoding];
    
    /// get the stream
    CGPDFStreamRef stream;
    if (CGPDFDictionaryGetStream(dict, kKey, &stream))
    {
        ret = [self getStringFromStream:stream];
    }
    
    NSLog(@"Key(%@):%@",key,ret);
    
    return ret;
}

+ (void)printDocument:(CGPDFDocumentRef) pdfDocument atPageNo:(NSUInteger)pageNumber
{
    CGPDFPageRef page = CGPDFDocumentGetPage(pdfDocument, pageNumber);
    
    CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(page);
    CFArrayRef streamArr = CGPDFContentStreamGetStreams(contentStream);
    
    CFIndex num = CFArrayGetCount(streamArr);
    for (CFIndex i=0; i<num; i++) {
        CGPDFStreamRef s = (CGPDFStreamRef)CFArrayGetValueAtIndex(streamArr, i);
        [self getStringFromStream:s];
    }
}

#define C_LOG
/* Applier function for dictionary dictionaries */
void didScanDict(const char *key, CGPDFObjectRef object, void *levelPtr)
{
    CGPDFObjectType itemType = CGPDFObjectGetType(object);
    int level = *(int*)levelPtr + 1;
    
    CGPDFDictionaryRef dict;
    CGPDFBoolean boolean;
    CGPDFInteger integer;
    CGPDFReal real;
    const char * name;
    CGPDFStringRef pdfString = NULL;
    const unsigned char *string;
    CGPDFArrayRef array;
    CGPDFStreamRef stream;
    
    /// padding the leading
    NSString *leadStr = [@"" stringByPaddingToLength:level withString:@" " startingAtIndex:0];
    
    switch (itemType) {
        case kCGPDFObjectTypeDictionary:
#ifndef C_LOG
            NSLog(@"%@%s(Dictionary):",leadStr,key);
#else
            for (int i=0; i<level; i++) printf(" ");
            printf("%s(Dictionary):\n",key);
#endif
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict)){
                /// show all the items in page dictionary
                CGPDFDictionaryApplyFunction(dict,didScanDict,&level);
            }
            break;
            
        case kCGPDFObjectTypeNull:
#ifndef C_LOG
            NSLog(@"%@%s(Null)",leadStr,key);
#else
            for (int i=0; i<level; i++) printf(" ");
            printf("%s(Null)\n",key);
#endif
            break;
        case kCGPDFObjectTypeBoolean:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeBoolean, &boolean)){
#ifndef C_LOG
                NSLog(@"%@%s(Bool):%d",leadStr,key,boolean);
#else
                for (int i=0; i<level; i++) printf(" ");
                printf("%s(Bool):%d\n",key,boolean);
#endif
            }
            break;
        case kCGPDFObjectTypeInteger:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &integer)){
                
#ifndef C_LOG
                NSLog(@"%@%s(Integer):%ld",leadStr,key,integer);
#else
                for (int i=0; i<level; i++) printf(" ");
                printf("%s(Integer):%ld\n",key,integer);
#endif
            }
            break;
        case kCGPDFObjectTypeReal:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeReal, &real)){
#ifndef C_LOG
                NSLog(@"%@%s(Real):%f",leadStr,key,real);
#else
                for (int i=0; i<level; i++) printf(" ");
                printf("%s(Real):%f\n",key,real);
#endif
            }
            break;
        case kCGPDFObjectTypeName:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeName, &name)){
#ifndef C_LOG
                NSLog(@"%@%s(Name):%s",leadStr,key,name);
#else
                for (int i=0; i<level; i++) printf(" ");
                printf("%s(Name):%s\n",key,name);
#endif
            }
            break;
        case kCGPDFObjectTypeString:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &pdfString)){
                string = CGPDFStringGetBytePtr(pdfString);
#ifndef C_LOG
                NSLog(@"%@%s(String):%s",leadStr,key,string);
#else
                for (int i=0; i<level; i++) printf(" ");
                printf("%s(String):%s\n",key,string);
#endif
                
            }
            break;
        case kCGPDFObjectTypeArray:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeArray, &array)){
#ifndef C_LOG
                NSLog(@"%@%s(Array) len - %zu:",leadStr,key,CGPDFArrayGetCount(array));
#else
                for (int i=0; i<level; i++) printf(" ");
                printf("%s(Array) len - %zu:\n",key,CGPDFArrayGetCount(array));
#endif
                // if (strcmp(key, "DescendantFonts") != 0)  break;
                
                for (int index = 0; index < CGPDFArrayGetCount(array) ; index++)
                {
                    CGPDFObjectRef obj;
                    if (CGPDFArrayGetObject(array, index, &obj)){
                        char indKey[16];
                        sprintf(indKey, "%d",index);
                        didScanDict(indKey, obj, &level);
                    }
                }
                
            }
            break;
        case kCGPDFObjectTypeStream:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeStream, &stream)){
                
                NSData *data = (NSData *) CGPDFStreamCopyData(stream, nil);
#ifndef C_LOG
                NSLog(@"%@%s(Stream): len - %ld",leadStr,key, (unsigned long)[data length]);
#else
                for (int i=0; i<level; i++) printf(" ");
                printf("%s(Stream): len - %ld\n",key, (unsigned long)[data length]);
#endif
                
                // ASCII segment length (little endian)
                unsigned char *bytes = (uint8_t *) [data bytes];
                NSString *ret;
                if (bytes[0] == 0x80)
                {
                    size_t asciiTextLength = bytes[2] | bytes[3] << 8 | bytes[4] << 16 | bytes[5] << 24;
                    NSData *textData = [[NSData alloc] initWithBytes:bytes+6 length:asciiTextLength];
                    ret = [[NSString alloc] initWithData:textData encoding:NSASCIIStringEncoding];
                    
                    [textData release];
                }
                else
                {
                    ret = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
                }
                NSLog(@"%@ :%@",leadStr,ret);
#ifndef C_LOG
                NSLog(@"%@%s(Integer):%ld",leadStr,key,integer);
#else
                for (int i=0; i<level; i++) printf(" ");
                printf("%s(Integer):%ld\n",key,integer);
#endif
                [ret release];
                
            }
            break;
            
        default:
            break;
    }
}

@synthesize documentURL, keyword, stringDetector, fontCollection, renderingStateStack, currentSelection, selections /* rawTextContent */, content = _content;
@end

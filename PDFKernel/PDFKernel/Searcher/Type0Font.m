#import "Type0Font.h"
#import "CIDType0Font.h"
#import "CIDType2Font.h"


@interface Type0Font ()
@property (nonatomic, readonly) NSMutableArray *descendantFonts;
@end

@implementation Type0Font

/* Initialize with font dictionary */
- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict
{
	if ((self = [super initWithFontDictionary:dict]))
	{
        /// retreive the CMap
        [self setCMapWithFontDictionary:dict];
        
		CGPDFArrayRef dFonts;
		if (CGPDFDictionaryGetArray(dict, "DescendantFonts", &dFonts))
		{
			NSUInteger count = CGPDFArrayGetCount(dFonts);
			for (NSInteger i = 0; i < count; i++)
			{
				CGPDFDictionaryRef fontDict;
				if (!CGPDFArrayGetDictionary(dFonts, i, &fontDict)) continue;
				const char *subtype;
				if (!CGPDFDictionaryGetName(fontDict, "Subtype", &subtype)) continue;
#ifdef SHOW_FONT_INFO
				NSLog(@"Descendant font type %s", subtype);
#endif
				if (strcmp(subtype, "CIDFontType0") == 0)
				{
					// Add descendant font of type 0
					CIDType0Font *font = [[CIDType0Font alloc] initWithFontDictionary:fontDict];
					if (font) [self.descendantFonts addObject:font];
					[font release];
				}
				else if (strcmp(subtype, "CIDFontType2") == 0)
				{
					// Add descendant font of type 2
					CIDType2Font *font = [[CIDType2Font alloc] initWithFontDictionary:fontDict];
                    font.CMapName = self.CMapName;
					if (font) [self.descendantFonts addObject:font];
					[font release];
				}
			}
		}
	}
	return self;
}

/* Custom implementation, using descendant fonts */
- (CGFloat)widthOfCharacter:(unichar)characher withFontSize:(CGFloat)fontSize
{
	for (Font *font in self.descendantFonts)
	{
		CGFloat width = [font widthOfCharacter:characher withFontSize:fontSize];
		if (width > 0) return width;
	}
	return self.defaultWidth;
}

- (NSDictionary *)ligatures
{
    return [[self.descendantFonts lastObject] ligatures];
}

- (FontDescriptor *)fontDescriptor {
	Font *descendantFont = [self.descendantFonts lastObject];
	return descendantFont.fontDescriptor;
}

- (CGFloat)minY
{
	Font *descendantFont = [self.descendantFonts lastObject];
	return [descendantFont.fontDescriptor descent];
}

/* Highest point of any character */
- (CGFloat)maxY
{
	Font *descendantFont = [self.descendantFonts lastObject];
	return [descendantFont.fontDescriptor ascent];
}

- (NSString *)stringWithPDFString:(CGPDFStringRef)pdfString
{
	if (self.toUnicode)
	{
		size_t stringLength = CGPDFStringGetLength(pdfString);
		const unsigned char *characterCodes = CGPDFStringGetBytePtr(pdfString);
		NSMutableString *unicodeString = [NSMutableString string];
		
        for (NSInteger i = 0; i < stringLength; i+=2)
		{
			unichar characterCode = characterCodes[i] << 8 | characterCodes[i+1];
			unichar characterSelector = [self.toUnicode unicodeCharacter:characterCode];
            [unicodeString appendFormat:@"%C", characterSelector];
		}
		return unicodeString;
	}
	else if ([self.descendantFonts count] > 0)
	{
		Font *descendantFont = [self.descendantFonts lastObject];
		return [descendantFont stringWithPDFString:pdfString];
	}
	return @"";
}

- (NSString *)cidWithPDFString:(CGPDFStringRef)pdfString
{
    if (self.toUnicode)
    {
        size_t stringLength = CGPDFStringGetLength(pdfString);
        const unsigned char *characterCodes = CGPDFStringGetBytePtr(pdfString);
        NSMutableString *cidString = [NSMutableString string];
        
        for (NSInteger i = 0; i < stringLength; i+=2)
        {
            unichar characterCode = characterCodes[i] << 8 | characterCodes[i+1];
            [cidString appendFormat:@"%C", characterCode];
        }
        return cidString;
    }
    /// return the pdfString, if there exists no toUnicode CMap, in which case cid is meaningless
    else if ([self.descendantFonts count] > 0)
    {
        Font *descendantFont = [self.descendantFonts lastObject];
        return [descendantFont stringWithPDFString:pdfString];
    }
    
    return @"";
}

#pragma mark - CMap Mapping
/* Set predefined CMap, given a font dictionary */
- (void)setCMapWithFontDictionary:(CGPDFDictionaryRef)dict
{
    CGPDFObjectRef CMapObject;
    if (!CGPDFDictionaryGetObject(dict, "Encoding", &CMapObject)) return;
    [self setCMapWithCMapObject:CMapObject];
}

/* Set CMap with name or dictionary */
- (void)setCMapWithCMapObject:(CGPDFObjectRef)object
{
    CGPDFObjectType type = CGPDFObjectGetType(object);
    
    /* Encoding entity is predefined */
    if (type == kCGPDFObjectTypeName)
    {
        const char *name;
        if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeName, &name)) return;
        
        /// GB2312-2000
        if (strcmp(name, "GBK-EUC-H") == 0 ||
            strcmp(name, "GBK-EUC-V") == 0 ||
            strcmp(name, "GBKp-EUC-H") == 0 ||
            strcmp(name, "GBKp-EUC-V") == 0 ||
            strcmp(name, "GBK2K-H") == 0 ||
            strcmp(name, "GBK2K-V") == 0 )
        {
            CMapName = @"GB2312-2000";
        }
        /// GB2312-80
        else if (strcmp(name, "GB-EUC-H") == 0 ||
                 strcmp(name, "GB-EUC-V") == 0 ||
                 strcmp(name, "GBpc-EUC-H") == 0 ||
                 strcmp(name, "GBpc-EUC-V") == 0 )
        {
            // What is MacExpertEncoding ??
            CMapName = @"GB2312-80";
        }
        else
        {
            /// TO DO: Deal with other predefined CMap
        }
        
        return;
    }
    
    /* Only accept stream objects */
    if (type != kCGPDFObjectTypeStream) return;
    
    /// TO DO: Deal with the stream CMap
    
    
    
}

#pragma mark -
#pragma mark Memory Management

- (NSMutableArray *)descendantFonts
{
	if (!descendantFonts)
	{
		descendantFonts = [[NSMutableArray alloc] init];
	}
	return descendantFonts;
}

- (void)dealloc
{
	[descendantFonts release];
	[super dealloc];
}

@end

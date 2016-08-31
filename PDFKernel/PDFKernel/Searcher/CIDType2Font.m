#import "CIDType2Font.h"


@implementation CIDType2Font

- (void)setCIDToGIDMapWithDictionary:(CGPDFDictionaryRef)dict
{
	CGPDFObjectRef object = nil;
    if (!CGPDFDictionaryGetObject(dict, "CIDToGIDMap", &object)) {
        identity = YES;         /// default value is identity
        return;
    }
	CGPDFObjectType type = CGPDFObjectGetType(object);
	if (type == kCGPDFObjectTypeName)
	{
		const char *mapName;
		if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeName, &mapName)) return;
		identity = YES;
	}
	else if (type == kCGPDFObjectTypeStream)
	{
		CGPDFStreamRef stream = nil;
		if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeStream, &stream)) return;
		NSData *data = (NSData *) CGPDFStreamCopyData(stream, nil);
#ifdef SHOW_FONT_INFO
		NSLog(@"CIDType2Font: no implementation for CID mapping with stream (%d bytes)", [data length]);
#endif
		[data release];
	}
}


- (void)setCIDSystemInfoWithDictionary:(CGPDFDictionaryRef)dict
{
	CGPDFDictionaryRef cidSystemInfo;
	if (!CGPDFDictionaryGetDictionary(dict, "CIDSystemInfo", &cidSystemInfo)) return;

	CGPDFStringRef registry;
	if (!CGPDFDictionaryGetString(cidSystemInfo, "Registry", &registry)) return;

	CGPDFStringRef ordering;
	if (!CGPDFDictionaryGetString(cidSystemInfo, "Ordering", &ordering)) return;
	
	CGPDFInteger supplement;
	if (!CGPDFDictionaryGetInteger(cidSystemInfo, "Supplement", &supplement)) return;
	
	NSString *registryString = (NSString *) CGPDFStringCopyTextString(registry);
	NSString *orderingString = (NSString *) CGPDFStringCopyTextString(ordering);
	
	cidSystemString = [NSString stringWithFormat:@"%@ (%@) %ld", registryString, orderingString, supplement];
#ifdef SHOW_FONT_INFO
	NSLog(@"%@", cidSystemString);
#endif
    
	[registryString release];
	[orderingString release];
}

- (id)initWithFontDictionary:(CGPDFDictionaryRef)dict
{
	if ((self = [super initWithFontDictionary:dict]))
	{
		[self setCIDToGIDMapWithDictionary:dict];
		[self setCIDSystemInfoWithDictionary:dict];
	}
	return self;
}

/// return CID, from showed text character
- (NSString *)stringWithPDFString:(CGPDFStringRef)pdfString
{
	unichar *characterIDs = (unichar *) CGPDFStringGetBytePtr(pdfString);

    /// check the CIDSystemInfo
    NSRange range = [cidSystemString rangeOfString:@"GB"];
    if (range.location != NSNotFound) {
        NSStringEncoding enc;
        if ([CMapName isEqualToString:@"GB2312-2000"]) {
            enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
        }
        else if([CMapName isEqualToString:@"GB2312-80"]){
            enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_2312_80);
        }
        NSString *str = [NSString stringWithCString:(const char *)characterIDs encoding:enc];
        return str;
    }
    else {
        NSUInteger length = CGPDFStringGetLength(pdfString) / sizeof(unichar);
        NSMutableString *unicodeString = [NSMutableString string];
        int magicalOffset = ([self isIdentity] ? 0 : 30);
        for (NSInteger i = 0; i < length; i++)
        {
            unichar unicodeValue = characterIDs[i] + magicalOffset;
            [unicodeString appendFormat:@"%C", unicodeValue];
        }
        return unicodeString;
    }
}

@synthesize identity;
@end

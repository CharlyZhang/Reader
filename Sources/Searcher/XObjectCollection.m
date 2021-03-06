//
//  XObjectCollection.m
//  PDFKitten
//
//  Created by CharlyZhang on 14/12/24.
//  Copyright (c) 2014年 Chalmers Göteborg. All rights reserved.
//

#import "XObjectCollection.h"
#undef DEBUG

const char* kXObjectSubtypeKey = "Subtype";
const char* kTypeFormKey = "Form";

@implementation XObjectCollection

/* Applier function for xobject dictionaries */
void didScanXObject(const char *key, CGPDFObjectRef object, void *collection)
{
    if (!CGPDFObjectGetType(object) == kCGPDFObjectTypeDictionary) return;
    CGPDFStreamRef stream;
    if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeStream, &stream)) return;
    
    /// only add Form XObject
    CGPDFDictionaryRef dict;
    if (!CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict)) return;
    const char *subtype = nil;
    CGPDFDictionaryGetName(dict, kXObjectSubtypeKey, &subtype);
    if (!strcmp(subtype, kTypeFormKey)) return;
    
    
    XObject *xobject = [[XObject alloc] init];
    xobject.stream = stream;
    
    NSString *name = [NSString stringWithUTF8String:key];
    [(NSMutableDictionary *)collection setObject:xobject forKey:name];
    
    [xobject release];
#ifdef DEBUG
    NSLog(@" %s: %@", key, xobject);
#endif
}

/* Initialize with a XObject collection dictionary */
- (id)initWithXObjectDictionary:(CGPDFDictionaryRef)dict
{
    if ((self = [super init]))
    {
#ifdef SHOW_FONT_INFO
        NSLog(@"Xobject Collection (%lu)", CGPDFDictionaryGetCount(dict));
#endif
        xobjects = [[NSMutableDictionary alloc] init];
        // Enumerate the XObject resource dictionary
        CGPDFDictionaryApplyFunction(dict, didScanXObject, xobjects);
        
        NSMutableArray *namesArray = [NSMutableArray array];
        for (NSString *name in [xobjects allKeys])
        {
            [namesArray addObject:name];
        }
        
        names = [[namesArray sortedArrayUsingSelector:@selector(compare:)] retain];
    }
    return self;
}

/* Returns a copy of the XObjects dictionary */
- (NSDictionary *)fontsByName
{
    return [NSDictionary dictionaryWithDictionary:xobjects];
}

/* Return the specified xobject */
- (XObject *)xobjectNamed:(NSString *)xobjectName
{
    return [xobjects objectForKey:xobjectName];
}

#pragma mark - Memory Management

- (void)dealloc
{
    [names release];
    [xobjects release];
    [super dealloc];
}

@synthesize names;
@end


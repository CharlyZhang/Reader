//
//  Util.m
//  PDFKitten
//
//  Created by tangsl on 14/12/19.
//  Copyright (c) 2014年 Chalmers Göteborg. All rights reserved.
//

#import "Util.h"


@implementation Util


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
    
    return [ret autorelease];
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
    
#ifndef C_LOG
    /// padding the leading
    NSString *leadStr = [@"" stringByPaddingToLength:level withString:@" " startingAtIndex:0];
#endif
    switch (itemType) {
        case kCGPDFObjectTypeDictionary:
#ifndef C_LOG
            NSLog(@"%@%s(Dictionary):",leadStr,key);
#else
            for (NSInteger i=0; i<level; i++) printf(" ");
            printf("%s(Dictionary):\n",key);
#endif
            /// if the dictionary is "Parent", just ignore it to avoid infinate recursive searching
            static BOOL firstParent = NO;
            if (strcmp(key, "Parent") == 0) {
                if (!firstParent)
                    break;
                 else
                    firstParent = NO;
            }
            
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeDictionary, &dict)){
                /// show all the items in page dictionary
                size_t count = CGPDFDictionaryGetCount(dict);
#ifndef C_LOG
                NSLog(@"%@dictionary count: %ld",leadStr,count);
#else
                for (NSInteger i=0; i<level; i++) printf(" ");
                printf("dictionary count: %ld\n",count);
#endif
                CGPDFDictionaryApplyFunction(dict,didScanDict,&level);
            }
            break;
            
        case kCGPDFObjectTypeNull:
#ifndef C_LOG
            NSLog(@"%@%s(Null)",leadStr,key);
#else
            for (NSInteger i=0; i<level; i++) printf(" ");
            printf("%s(Null)\n",key);
#endif
            break;
        case kCGPDFObjectTypeBoolean:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeBoolean, &boolean)){
#ifndef C_LOG
                NSLog(@"%@%s(Bool):%d",leadStr,key,boolean);
#else
                for (NSInteger i=0; i<level; i++) printf(" ");
                printf("%s(Bool):%d\n",key,boolean);
#endif
            }
            break;
        case kCGPDFObjectTypeInteger:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &integer)){
                
#ifndef C_LOG
                NSLog(@"%@%s(Integer):%ld",leadStr,key,integer);
#else
                for (NSInteger i=0; i<level; i++) printf(" ");
                printf("%s(Integer):%ld\n",key,integer);
#endif
            }
            break;
        case kCGPDFObjectTypeReal:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeReal, &real)){
#ifndef C_LOG
                NSLog(@"%@%s(Real):%f",leadStr,key,real);
#else
                for (NSInteger i=0; i<level; i++) printf(" ");
                printf("%s(Real):%f\n",key,real);
#endif
            }
            break;
        case kCGPDFObjectTypeName:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeName, &name)){
#ifndef C_LOG
                NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                NSString *str = [NSString stringWithCString:(const char *)name encoding:enc];
                NSLog(@"%@%s(Name):%@",leadStr,key,str);
#else
                
                for (NSInteger i=0; i<level; i++) printf(" ");
                printf("%s(Name):%s\n",key,name);
//                NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                //NSString *str = [NSString stringWithCString:(const char *)name encoding:enc];
                //NSLog(@"%s(Name):%@",key,str);
                
#endif
            }
            break;
        case kCGPDFObjectTypeString:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &pdfString)){
                string = CGPDFStringGetBytePtr(pdfString);
#ifndef C_LOG
                NSLog(@"%@%s(String):%s",leadStr,key,string);
#else
                for (NSInteger i=0; i<level; i++) printf(" ");
                printf("%s(String):%s\n",key,string);
#endif
                
            }
            break;
        case kCGPDFObjectTypeArray:
            if (CGPDFObjectGetValue(object, kCGPDFObjectTypeArray, &array)){
#ifndef C_LOG
                NSLog(@"%@%s(Array) len - %zu:",leadStr,key,CGPDFArrayGetCount(array));
#else
                for (NSInteger i=0; i<level; i++) printf(" ");
                printf("%s(Array) len - %zu:\n",key,CGPDFArrayGetCount(array));
#endif
                /// skip the repeat Annots to avoid infinate recursive searching
                static BOOL firstAnnots = YES;
                if (strcmp(key, "Annots") == 0) {
                    if (!firstAnnots)
                        break;
                    else
                        firstAnnots = NO;
                }

                
                for (NSInteger index = 0; index < CGPDFArrayGetCount(array) ; index++)
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
                for (NSInteger i=0; i<level; i++) printf(" ");
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
#ifndef C_LOG
                NSLog(@"%@ %@",leadStr,ret);
#else
                for (NSInteger i=0; i<level; i++) printf(" ");
                printf(" %s\n",(char*)bytes);
#endif
                [ret release];
                
            }
            break;
            
        default:
            break;
    }
}

+ (void)printDictionary:(CGPDFDictionaryRef)dict
{
    int level = 0;
    size_t count = CGPDFDictionaryGetCount(dict);
#ifndef C_LOG
    NSLog(@"dictionary(level%d) count: %ld",level,count);
#else
    printf("dictionary(level%d) count: %ld\n",level,count);
#endif
    
    CGPDFDictionaryApplyFunction(dict,didScanDict,&level);
}

@end

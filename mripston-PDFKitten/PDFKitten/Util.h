//
//  Util.h
//  PDFKitten
//
//  Created by tangsl on 14/12/19.
//  Copyright (c) 2014年 Chalmers Göteborg. All rights reserved.
//

#import <Foundation/Foundation.h>

void didScanDict(const char *key, CGPDFObjectRef object, void *levelPtr);

@interface Util : NSObject

+ (NSString*)getStringFromStream:(CGPDFStreamRef) stream;
+ (NSString*)getStringFromDict:(CGPDFDictionaryRef)dict atKey:(NSString*)key;
+ (void)printDocument:(CGPDFDocumentRef) pdfDocument atPageNo:(NSUInteger)pageNumber;

@end

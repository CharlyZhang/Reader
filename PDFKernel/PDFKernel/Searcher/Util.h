//
//  Util.h
//  PDFKitten
//
//  Created by tangsl on 14/12/19.
//  Copyright (c) 2014年 Chalmers Göteborg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

void didScanDict(const char *key, CGPDFObjectRef object, void *levelPtr);

@interface Util : NSObject

//获取stream表示的字符串
+ (NSString*)getStringFromStream:(CGPDFStreamRef) stream;
//获取字典某key表示的字符串
+ (NSString*)getStringFromDict:(CGPDFDictionaryRef)dict atKey:(NSString*)key;
//打印pdf文档某页的结构信息
+ (void)printDocument:(CGPDFDocumentRef) pdfDocument atPageNo:(NSUInteger)pageNumber;
//打印pdf某中某字典表示的文档信息
+ (void)printDictionary:(CGPDFDictionaryRef)dict;
@end

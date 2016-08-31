//
//  XObjectCollection.h
//  PDFKitten
//
//  Created by tangsl on 14/12/24.
//  Copyright (c) 2014年 Chalmers Göteborg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XObject.h"
@interface XObjectCollection : NSObject{
    NSMutableDictionary *xobjects;
    NSArray *names;
}

/* Initialize with a XObject collection dictionary */
- (id)initWithXObjectDictionary:(CGPDFDictionaryRef)dict;

/* Return the specified XObject */
- (XObject *)xobjectNamed:(NSString *)xobjectName;

@property (nonatomic, readonly) NSDictionary *xobjectsByName;

@property (nonatomic, readonly) NSArray *names;

@end

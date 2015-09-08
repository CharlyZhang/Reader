//
//  XObject.h
//  PDFKitten
//
//  Created by tangsl on 14/12/24.
//  Copyright (c) 2014年 Chalmers Göteborg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

@interface XObject : NSObject

@property (nonatomic) CGPDFStreamRef stream;

@end

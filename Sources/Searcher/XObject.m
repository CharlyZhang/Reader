//
//  XObject.m
//  PDFKitten
//
//  Created by tangsl on 14/12/24.
//  Copyright (c) 2014年 Chalmers Göteborg. All rights reserved.
//

#import "XObject.h"

@implementation XObject

- (NSString*)description
{
    NSData *data = (NSData *) CGPDFStreamCopyData(self.stream, nil);
    
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
    
    return [ret autorelease];

}

@end

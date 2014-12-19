/*
 *	A composite font is one of the following types:
 *		- Type0
 *		- CIDType0Font
 *		- CIDType2Font
 *
 *	Composite fonts have the following specific traits:
 *		- Default glyph width
 *
 */

#import <Foundation/Foundation.h>
#import "CFont.h"

@interface CompositeFont : Font {
    CGFloat defaultWidth;
    NSString *cidSystemString;
    NSString *CMapName;         /// for Type0 Font and CIDType2 Font will refer to its parents's CMapName
}

@property (nonatomic, strong) NSString *CMapName;
@property (nonatomic, assign) CGFloat defaultWidth;
@end

//
//  PDFMainScrollView.m
//  E-Publishing
//
//  Created by CharlyZhang on 15/3/2.
//
//

#import "PDFMainScrollView.h"

@implementation PDFMainScrollView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (BOOL)touchesShouldCancelInContentView:(UIView *)view
{
    return [self.mainScrollViewDelegate touchesShouldCancelInMainScrollView:view];
}

@end

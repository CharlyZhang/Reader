//
//  PDFMainScrollView.h
//  E-Publishing
//
//  Created by CharlyZhang on 15/3/2.
//
//

#import <UIKit/UIKit.h>

@protocol PDFMainScrollViewDelegate <NSObject>

@required

- (BOOL)touchesShouldCancelInMainScrollView:(UIView*)view;

@end

@interface PDFMainScrollView : UIScrollView

@property(nonatomic, retain)id<PDFMainScrollViewDelegate> mainScrollViewDelegate;

@end

//
//  PDFThumbsMainToolbar.h
//  E-Publishing
//
//  Created by tangsl on 15/1/20.
//
//


#import <UIKit/UIKit.h>

#import "UIXToolbarView.h"

@class PDFThumbsMainToolbar;

@protocol PDFThumbsMainToolbarDelegate <NSObject>

@required // Delegate protocols

- (void)tappedInToolbar:(PDFThumbsMainToolbar *)toolbar returnButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFThumbsMainToolbar *)toolbar modeControl:(UISegmentedControl *)control;

@end

@interface PDFThumbsMainToolbar : UIXToolbarView

@property (nonatomic, weak, readwrite) id <PDFThumbsMainToolbarDelegate> delegate;

- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title;

@end

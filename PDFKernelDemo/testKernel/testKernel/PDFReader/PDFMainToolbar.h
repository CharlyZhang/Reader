//
//  PDFMainToolbar.h
//  E-Publishing
//
//  Created by CharlyZhang on 15/1/15.
//
//

#import <UIKit/UIKit.h>

#import "UIXToolbarView.h"
#import "PDFConstants.h"

#define TOOLBAR_CUSTOM_BTN_INIT_TAG     0x2324

@class PDFMainToolbar;
@class ReaderDocument;

@protocol PDFMainToolbarDelegate <NSObject>

@required // Delegate protocols

- (void)tappedInToolbar:(PDFMainToolbar *)toolbar returnButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar pageButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar searchButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar thumbsButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar exportButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar printButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar emailButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar markButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar catalogButton:(UIButton *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar switchPOButton:(UISegmentedControl *)button;
- (void)tappedInToolbar:(PDFMainToolbar *)toolbar customButton:(UIButton *)button;


- (void)updateStatusBar;                    ///< update status bar when self.hidden changed

@end

@interface PDFMainToolbar : UIXToolbarView

@property (nonatomic, weak, readwrite) id <PDFMainToolbarDelegate> delegate;
@property (nonatomic, strong, readonly) UIButton* searchButton;
@property (nonatomic, strong, readonly) UIButton* catalogButton;
@property (nonatomic, strong, readonly) NSMutableArray *customButtons;


- (instancetype)initWithFrame:(CGRect)frame document:(ReaderDocument *)document;

- (instancetype)initWithFrame:(CGRect)frame document:(ReaderDocument *)document cofiguration:(NSDictionary*)config;

- (void)setBookmarkState:(BOOL)state;

- (void)hideToolbar;
- (void)showToolbar;

@end

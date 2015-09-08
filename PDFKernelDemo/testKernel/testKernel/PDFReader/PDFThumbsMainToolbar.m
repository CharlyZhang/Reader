//
//  PDFThumbsMainToolbar.m
//  E-Publishing
//
//  Created by tangsl on 15/1/20.
//
//

#import "ReaderConstants.h"
#import "PDFThumbsMainToolbar.h"

@implementation PDFThumbsMainToolbar
{
    UIImageView *backgroundView;            ///< 背景图
}

#pragma mark - Constants

#define BUTTON_X 15.0f
#define BUTTON_Y 12.0f

#define BUTTON_SPACE 15.0f
#define BUTTON_HEIGHT 30.0f

#define BUTTON_FONT_SIZE 15.0f
#define TEXT_BUTTON_PADDING 24.0f

#define SHOW_CONTROL_WIDTH 78.0f
#define ICON_BUTTON_WIDTH 40.0f

#define TITLE_FONT_SIZE 19.0f
#define TITLE_HEIGHT 28.0f

#pragma mark - Properties

@synthesize delegate;

#pragma mark - PDFThumbsMainToolbar instance methods

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame title:nil];
}

- (instancetype)initWithFrame:(CGRect)frame title:(NSString *)title
{
    if ((self = [super initWithFrame:frame]))
    {
        backgroundView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"kernel_bar_bg_h.png"]];
        [self addSubview: backgroundView];
        
        CGFloat viewWidth = self.bounds.size.width; // Toolbar view width
        
#if (READER_FLAT_UI == TRUE) // Option
        UIImage *buttonH = nil; UIImage *buttonN = nil;
#else
        UIImage *buttonH = [[UIImage imageNamed:@"Reader-Button-H"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
        UIImage *buttonN = [[UIImage imageNamed:@"Reader-Button-N"] stretchableImageWithLeftCapWidth:5 topCapHeight:0];
#endif // end of READER_FLAT_UI Option
        
        //BOOL largeDevice = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
        
        const CGFloat buttonSpacing = BUTTON_SPACE; const CGFloat iconButtonWidth = ICON_BUTTON_WIDTH;
        
        CGFloat titleX = BUTTON_X; CGFloat titleWidth = (viewWidth - (titleX + titleX));
        
        CGFloat leftButtonX = BUTTON_X; // Left-side button start X position
        
        UIButton *returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
      //  returnButton.frame = CGRectMake(leftButtonX, BUTTON_Y, iconButtonWidth, BUTTON_HEIGHT);
        [returnButton setImage:[UIImage imageNamed:@"kernel_back"] forState:UIControlStateNormal];
        [returnButton setImage:[UIImage imageNamed:@"kernel_back_s"] forState:UIControlStateHighlighted];
        [returnButton addTarget:self action:@selector(returnButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [returnButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
        [returnButton setBackgroundImage:buttonN forState:UIControlStateNormal];
        returnButton.autoresizingMask = UIViewAutoresizingNone;
        //doneButton.backgroundColor = [UIColor grayColor];
        returnButton.exclusiveTouch = YES;
        returnButton.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:returnButton]; leftButtonX += (iconButtonWidth + buttonSpacing);
        
        titleX += (iconButtonWidth + buttonSpacing); titleWidth -= (iconButtonWidth + buttonSpacing);

        
#if (READER_BOOKMARKS == TRUE) // Option
        
   //     CGFloat showControlX = (viewWidth - (SHOW_CONTROL_WIDTH + buttonSpacing));
        
        NSArray *buttonItems = [NSArray arrayWithObjects:@"全部",@"已添书签页", nil];
        
        //BOOL useTint = [self respondsToSelector:@selector(tintColor)]; // iOS 7 and up
        
        UISegmentedControl *modeControl = [[UISegmentedControl alloc] initWithItems:buttonItems];
        //modeControl.frame = CGRectMake(showControlX, BUTTON_Y, SHOW_CONTROL_WIDTH, BUTTON_HEIGHT);
        modeControl.tintColor = [UIColor whiteColor];//(useTint ? [UIColor blackColor] : [UIColor colorWithWhite:0.8f alpha:1.0f]);
        modeControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        modeControl.selectedSegmentIndex = 0; // Default segment index
        //showControl.backgroundColor = [UIColor grayColor];
        modeControl.exclusiveTouch = YES;
        modeControl.translatesAutoresizingMaskIntoConstraints = NO;
        
        [modeControl addTarget:self action:@selector(modeControlTapped:) forControlEvents:UIControlEventValueChanged];
        
        //modeControl.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self addSubview:modeControl];
        
        titleWidth -= (SHOW_CONTROL_WIDTH + buttonSpacing);
        
        self.autoresizesSubviews = YES;
    
#endif // end of READER_BOOKMARKS Option
        
//        if (largeDevice == YES) // Show document filename in toolbar
//        {
//            CGRect titleRect = CGRectMake(titleX, BUTTON_Y, titleWidth, TITLE_HEIGHT);
//            
//            UILabel *titleLabel = [[UILabel alloc] initWithFrame:titleRect];
//            
//            titleLabel.textAlignment = NSTextAlignmentCenter;
//            titleLabel.font = [UIFont systemFontOfSize:TITLE_FONT_SIZE];
//            titleLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
//            titleLabel.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
//            titleLabel.textColor = [UIColor colorWithWhite:0.0f alpha:1.0f];
//            titleLabel.backgroundColor = [UIColor clearColor];
//            titleLabel.adjustsFontSizeToFitWidth = YES;
//            titleLabel.minimumScaleFactor = 0.75f;
//            titleLabel.text = title;
//#if (READER_FLAT_UI == FALSE) // Option
//            titleLabel.shadowColor = [UIColor colorWithWhite:0.65f alpha:1.0f];
//            titleLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
//#endif // end of READER_FLAT_UI Option
//            
//            [self addSubview:titleLabel];
//        }
        
        [self setConstraintsOfButton:returnButton andControl:modeControl];
    }
    
    return self;
}

#pragma mark - Constraints

- (void)setConstraintsOfButton:(UIButton*) button andControl:(UISegmentedControl*) control
{
    NSDictionary *bindingViews = NSDictionaryOfVariableBindings(button,control);
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-15-[button]" options:nil metrics:nil views:bindingViews]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:[control]-15-|" options:nil metrics:nil views:bindingViews]];
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[button]-8-|" options:nil metrics:nil views:bindingViews]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:control attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:button attribute:NSLayoutAttributeCenterY multiplier:1.0 constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:control attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:nil multiplier:1.0 constant:30]];
}

-(void)layoutSubviews
{
    
    [super layoutSubviews];
    
    if (self.frame.size.width > self.frame.size.height) {
        backgroundView.image = [UIImage imageNamed:@"kernel_bar_bg_h"];
    }
    else{
        backgroundView.image = [UIImage imageNamed:@"kernel_bar_bg_v"];
    }
}

#pragma mark - UISegmentedControl action methods

- (void)modeControlTapped:(UISegmentedControl *)control
{
    [delegate tappedInToolbar:self modeControl:control];
}

#pragma mark - UIButton action methods

- (void)returnButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self returnButton:button];
}

@end

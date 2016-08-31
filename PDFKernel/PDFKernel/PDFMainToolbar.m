//
//	ReaderMainToolbar.m
//	Reader v2.8.2
//
//	Created by Julius Oklamcak on 2011-07-01.
//	Copyright © 2011-2014 Julius Oklamcak. All rights reserved.
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights to
//	use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
//	of the Software, and to permit persons to whom the Software is furnished to
//	do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in all
//	copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//	CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "ReaderConstants.h"
#import "PDFMainToolbar.h"
#import "ReaderDocument.h"

#import <MessageUI/MessageUI.h>

@implementation PDFMainToolbar
{
    UIButton *markButton;
    
    UIButton *searchButton;
    UIButton *catalogButton;
    NSMutableArray *customButtons;
    
    UIImage *markImageN;
    UIImage *markImageY;
    
    NSArray *backgroundImages;
    UIImageView *backgroundView;
}

#pragma mark - Constants

#define BUTTON_X 12.0f
#define BUTTON_Y 22.0f

#define BUTTON_SPACE 12.0f
#define BUTTON_HEIGHT 32.0f

#define BUTTON_FONT_SIZE 15.0f
#define TEXT_BUTTON_PADDING 24.0f

#define ICON_BUTTON_WIDTH 32.0f

#define TITLE_FONT_SIZE 19.0f
#define TITLE_HEIGHT 28.0f

#pragma mark - Properties

@synthesize delegate,catalogButton,searchButton,customButtons;

#pragma mark - ReaderMainToolbar instance methods

- (instancetype)initWithFrame:(CGRect)frame
{
    return [self initWithFrame:frame document:nil];
}

- (instancetype)initWithFrame:(CGRect)frame document:(ReaderDocument *)document
{
    NSDictionary *config = @{};
    
    return [self initWithFrame:frame document:document cofiguration:config];
}


- (instancetype)initWithFrame:(CGRect)frame document:(ReaderDocument *)document cofiguration:(NSDictionary*)config
{
    assert(document != nil); // Must have a valid ReaderDocument
    assert(config != nil);
    
    if ((self = [super initWithFrame:frame]))
    {
        backgroundImages = (NSArray*)[config objectForKey:TOOLBAR_BACKGROUND_IMAGE_KEY];
        if (!backgroundImages) {
            backgroundImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"pdf_topbar_bg_h"],
                          [UIImage imageNamed:@"pdf_topbar_bg_v"], nil];
        }

        backgroundView = [[UIImageView alloc] initWithImage:backgroundImages[0]];
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
        
#if (READER_STANDALONE == FALSE) // Option
        UIButton *returnButton = [UIButton buttonWithType:UIButtonTypeCustom];
        returnButton.frame = CGRectMake(leftButtonX, BUTTON_Y, iconButtonWidth, BUTTON_HEIGHT);
        NSArray *returnBtnImgs = (NSArray*)[config objectForKey:TOOLBAR_BACK_BTN_IMAGES_KEY];
        if (!returnBtnImgs) {
            returnBtnImgs = [NSArray arrayWithObjects:[UIImage imageNamed:@"pdf_exit_N"],
                             [UIImage imageNamed:@"pdf_exit_H"], nil];
        }
        [returnButton setImage: (UIImage*)returnBtnImgs[0] forState:UIControlStateNormal];
        [returnButton setImage: (UIImage*)returnBtnImgs[1] forState:UIControlStateHighlighted];
        [returnButton addTarget:self action:@selector(returnButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [returnButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
        [returnButton setBackgroundImage:buttonN forState:UIControlStateNormal];
        returnButton.autoresizingMask = UIViewAutoresizingNone;
        //doneButton.backgroundColor = [UIColor grayColor];
        returnButton.exclusiveTouch = YES;
        
        [self addSubview:returnButton]; leftButtonX += (iconButtonWidth + buttonSpacing);
        
        titleX += (iconButtonWidth + buttonSpacing); titleWidth -= (iconButtonWidth + buttonSpacing);
        
#endif // end of READER_STANDALONE Option
        
#if (READER_PAGE_MODE == TRUE) // Option
        
        UIFont *pageButtonFont = [UIFont systemFontOfSize:BUTTON_FONT_SIZE];
        NSString *pageButtonText = NSLocalizedString(@"Curl", @"button");
        CGSize pageButtonSize = [pageButtonText sizeWithFont:pageButtonFont];
        CGFloat pageButtonWidth = (pageButtonSize.width + TEXT_BUTTON_PADDING);
        
        UIButton *pageButton = [UIButton buttonWithType:UIButtonTypeCustom];
        pageButton.frame = CGRectMake(leftButtonX, BUTTON_Y, pageButtonWidth, BUTTON_HEIGHT);
        [pageButton setTitleColor:[UIColor colorWithWhite:0.0f alpha:1.0f] forState:UIControlStateNormal];
        [pageButton setTitleColor:[UIColor colorWithWhite:1.0f alpha:1.0f] forState:UIControlStateHighlighted];
        [pageButton setTitle:pageButtonText forState:UIControlStateNormal]; pageButton.titleLabel.font = pageButtonFont;
        [pageButton addTarget:self action:@selector(pageButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [pageButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
        [pageButton setBackgroundImage:buttonN forState:UIControlStateNormal];
        pageButton.autoresizingMask = UIViewAutoresizingNone;
        //doneButton.backgroundColor = [UIColor grayColor];
        pageButton.exclusiveTouch = YES;
        
        pageButton.selected = NO;
        
        [self addSubview:pageButton]; //leftButtonX += (doneButtonWidth + buttonSpacing);
        
        titleX += (doneButtonWidth + buttonSpacing); titleWidth -= (doneButtonWidth + buttonSpacing);
        
#endif // end of READER_PAGE_MODE Option
        
        CGFloat rightButtonX = viewWidth; // Right-side buttons start X position
        
#if (READER_BOOKMARKS == TRUE) // Option
        
        rightButtonX -= (iconButtonWidth + buttonSpacing); // Position
        
        UIButton *flagButton = [UIButton buttonWithType:UIButtonTypeCustom];
        flagButton.frame = CGRectMake(rightButtonX, BUTTON_Y, iconButtonWidth, BUTTON_HEIGHT);
        //[flagButton setImage:[UIImage imageNamed:@"Reader-Mark-N"] forState:UIControlStateNormal];
        
        NSArray *flagBtnImgs = (NSArray*)[config objectForKey:TOOLBAR_FLAG_BTN_IMAGES_KEY];
        if (!flagBtnImgs) {
            flagBtnImgs = [NSArray arrayWithObjects:[UIImage imageNamed:@"pdf_bookmark_N"],
                           [UIImage imageNamed:@"pdf_bookmark_H"],nil];
        }
        
        [flagButton addTarget:self action:@selector(markButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [flagButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
        [flagButton setBackgroundImage:buttonN forState:UIControlStateNormal];
        flagButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        //flagButton.backgroundColor = [UIColor grayColor];
        flagButton.exclusiveTouch = YES;
        
        [self addSubview:flagButton]; titleWidth -= (iconButtonWidth + buttonSpacing);
        
        markButton = flagButton; markButton.enabled = NO; markButton.tag = NSIntegerMin;
        
        
        markImageN = flagBtnImgs[0]; // N image
        markImageY = flagBtnImgs[1]; // Y image
        NSLog(@"%@",flagButton);
        
#endif // end of READER_BOOKMARKS Option
        
        // add custom buttons
        customButtons = [[NSMutableArray alloc]init];
        NSArray *customBtns = (NSArray*)[config objectForKey:TOOLBAR_CUSTOM_BTNS_KEY];
        
        NSUInteger customInd = TOOLBAR_CUSTOM_BTN_INIT_TAG;
        for (NSDictionary *btnConfig in customBtns) {
            rightButtonX -= (iconButtonWidth + buttonSpacing); // Next position
            
            UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
            button.frame = CGRectMake(rightButtonX, BUTTON_Y, iconButtonWidth, BUTTON_HEIGHT);
            NSArray *customBtnImgs = (NSArray*)[btnConfig objectForKey:TOOLBAR_CUSTOM_BTN_IMAGES_KEY];
            if (!customBtnImgs) {
                [button setBackgroundColor:[UIColor redColor]];
                NSLog(@"Warn - custom tool bar button lack background images");
            }
            else {
                [button setImage:(UIImage*)customBtnImgs[0] forState:UIControlStateNormal];
                [button setImage:(UIImage*)customBtnImgs[1] forState:UIControlStateHighlighted];
            }
            [button addTarget:self action:@selector(customButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [button setBackgroundImage:buttonH forState:UIControlStateHighlighted];
            [button setBackgroundImage:buttonN forState:UIControlStateNormal];
            button.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
            button.exclusiveTouch = YES;
            button.tag = customInd++;
            [customButtons addObject:button];
            [self addSubview:button]; titleWidth -= (iconButtonWidth + buttonSpacing);
        }
        
        
        /// thumbs
#if (READER_ENABLE_THUMBS == TRUE) // Option
        
        rightButtonX -= (iconButtonWidth + buttonSpacing); // Next position
        
        UIButton *thumbsButton = [UIButton buttonWithType:UIButtonTypeCustom];
        thumbsButton.frame = CGRectMake(rightButtonX, BUTTON_Y, iconButtonWidth, BUTTON_HEIGHT);
        
        NSArray *thumbBtnImgs = (NSArray*)[config objectForKey:TOOLBAR_THUMB_BTN_IMAGES_KEY];
        if (!thumbBtnImgs) {
            thumbBtnImgs = [NSArray arrayWithObjects:[UIImage imageNamed:@"pdf_thumb_N"],
                            [UIImage imageNamed:@"pdf_thumb_H"], nil];
        }
        
        [thumbsButton setImage:(UIImage*)thumbBtnImgs[0] forState:UIControlStateNormal];
        [thumbsButton setImage:(UIImage*)thumbBtnImgs[1] forState:UIControlStateHighlighted];
        [thumbsButton addTarget:self action:@selector(thumbsButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [thumbsButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
        [thumbsButton setBackgroundImage:buttonN forState:UIControlStateNormal];
        thumbsButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        //exportButton.backgroundColor = [UIColor grayColor];
        thumbsButton.exclusiveTouch = YES;
        
        [self addSubview:thumbsButton]; titleWidth -= (iconButtonWidth + buttonSpacing);
        
#endif // end of READER_ENABLE_THUMBS Option
        
        /// catalog
        rightButtonX -= (iconButtonWidth + buttonSpacing); // Next position
        
        catalogButton = [UIButton buttonWithType:UIButtonTypeCustom];
        catalogButton.frame = CGRectMake(rightButtonX, BUTTON_Y, iconButtonWidth, BUTTON_HEIGHT);
        
        NSArray *catalogBtnImgs = (NSArray*)[config objectForKey:TOOLBAR_CATALOG_BTN_IMAGES_KEY];
        if (!catalogBtnImgs) {
            catalogBtnImgs = [NSArray arrayWithObjects:[UIImage imageNamed:@"pdf_catalog_N"],
                              [UIImage imageNamed:@"pdf_catalog_H"], nil];
        }
        
        [catalogButton setImage:(UIImage*)catalogBtnImgs[0] forState:UIControlStateNormal];
        [catalogButton setImage:(UIImage*)catalogBtnImgs[1] forState:UIControlStateHighlighted];
        
        [catalogButton addTarget:self action:@selector(catalogButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [catalogButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
        [catalogButton setBackgroundImage:buttonN forState:UIControlStateNormal];
        catalogButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        //exportButton.backgroundColor = [UIColor grayColor];
        catalogButton.exclusiveTouch = YES;
        
        [self addSubview:catalogButton]; titleWidth -= (iconButtonWidth + buttonSpacing);
        
        /// search
#if (READER_ENABLE_SEARCH == TRUE) // Option
        
        rightButtonX -= (iconButtonWidth + buttonSpacing); // Position
        
        searchButton = [UIButton buttonWithType:UIButtonTypeCustom];
        searchButton.frame = CGRectMake(rightButtonX, BUTTON_Y, iconButtonWidth, BUTTON_HEIGHT);
        
        NSArray *searchBtnImgs = (NSArray*)[config objectForKey:TOOLBAR_SEARCH_BTN_IMAGES_KEY];
        if (!searchBtnImgs) {
            searchBtnImgs = [NSArray arrayWithObjects:[UIImage imageNamed:@"pdf_search_N"],
                             [UIImage imageNamed:@"pdf_search_H"], nil];
        }
        
        [searchButton setImage:(UIImage*)searchBtnImgs[0] forState:UIControlStateNormal];
        [searchButton setImage:(UIImage*)searchBtnImgs[1] forState:UIControlStateHighlighted];
        [searchButton addTarget:self action:@selector(searchButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
        [searchButton setBackgroundImage:buttonH forState:UIControlStateHighlighted];
        [searchButton setBackgroundImage:buttonN forState:UIControlStateNormal];
        searchButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        //flagButton.backgroundColor = [UIColor grayColor];
        searchButton.exclusiveTouch = YES;
        
        [self addSubview:searchButton]; titleWidth -= (iconButtonWidth + buttonSpacing);
        
#endif // end of READER_ENABLE_SEARCH Option
        
    }
    
    
    return self;
}

- (void)dealloc {
    PDF_RELEASE(customButtons);
    PDF_RELEASE(backgroundView);
    PDF_SUPER_DEALLOC;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (self.frame.size.width > self.frame.size.height) {
        backgroundView.image = backgroundImages[0];
    }
    else{
        backgroundView.image = backgroundImages[1];
    }

}

- (void)setBookmarkState:(BOOL)state
{
#if (READER_BOOKMARKS == TRUE) // Option
    
    if (state != markButton.tag) // Only if different state
    {
        if (self.hidden == NO) // Only if toolbar is visible
        {
            UIImage *image = (state ? markImageY : markImageN);
            
            [markButton setImage:image forState:UIControlStateNormal];
        }
        
        markButton.tag = state; // Update bookmarked state tag
    }
    
    if (markButton.enabled == NO) markButton.enabled = YES;
    
#endif // end of READER_BOOKMARKS Option
}

- (void)updateBookmarkImage
{
#if (READER_BOOKMARKS == TRUE) // Option
    
    if (markButton.tag != NSIntegerMin) // Valid tag
    {
        BOOL state = markButton.tag; // Bookmarked state
        
        UIImage *image = (state ? markImageY : markImageN);
        
        [markButton setImage:image forState:UIControlStateNormal];
    }
    
    if (markButton.enabled == NO) markButton.enabled = YES;
    
#endif // end of READER_BOOKMARKS Option
}

- (void)hideToolbar
{
    if (self.hidden == NO)
    {
        [UIView animateWithDuration:0.25 delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^(void)
         {
             self.alpha = 0.0f;
         }
                         completion:^(BOOL finished)
         {
             self.hidden = YES;
             [delegate updateStatusBar];
         }
         ];
    }
}

- (void)showToolbar
{
    if (self.hidden == YES)
    {
        [self updateBookmarkImage]; // First
        
        [UIView animateWithDuration:0.25 delay:0.0
                            options:UIViewAnimationOptionCurveLinear | UIViewAnimationOptionAllowUserInteraction
                         animations:^(void)
         {
             self.hidden = NO;
             [delegate updateStatusBar];
             self.alpha = 1.0f;
         }
                         completion:NULL
         ];
    }
}

#pragma mark - UIButton action methods

- (void)returnButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self returnButton:button];
}

- (void)thumbsButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self thumbsButton:button];
}

- (void)pageButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self pageButton:button];
}

- (void)searchButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self searchButton:button];
}

- (void)exportButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self exportButton:button];
}

- (void)printButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self printButton:button];
}

- (void)emailButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self emailButton:button];
}

- (void)markButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self markButton:button];
}

- (void)catalogButtonTapped:(UIButton *)button
{
    [delegate tappedInToolbar:self catalogButton:button];
}

- (void)customButtonTapped:(UIButton*)button {
    [delegate tappedInToolbar:self customButton:button];
}

- (void)switchPOButtonTapped:(UISegmentedControl *)button
{
    [delegate tappedInToolbar:self switchPOButton:button];
}

@end

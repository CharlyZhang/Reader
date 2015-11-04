//
//	ReaderViewController.m
//	Reader v2.8.1
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
#import "ReaderViewController.h"
#import "ThumbsViewController.h"
#import "PDFMainToolbar.h"
#import "ReaderMainPagebar.h"
#import "ReaderContentView.h"
#import "ReaderThumbCache.h"
#import "ReaderThumbQueue.h"
#import "ReaderDocumentOutline.h"
#import "PDFCatalogViewController.h"
#import "PDFSearchViewController.h"
#import "Selection.h"
#import "PDFMainScrollView.h"

#import <MessageUI/MessageUI.h>
//#define DEBUG
@interface ReaderViewController () <UIScrollViewDelegate, UIGestureRecognizerDelegate, MFMailComposeViewControllerDelegate, UIDocumentInteractionControllerDelegate,
PDFMainToolbarDelegate, ReaderMainPagebarDelegate, ReaderContentViewDelegate, ThumbsViewControllerDelegate,PDFSearchViewControllerDelegate,PDFMainScrollViewDelegate,
PDFCatalogDelegate,UIPopoverControllerDelegate>

@end

@implementation ReaderViewController
{
    ReaderDocument *document;                               ///< pdf文档
    
    PDFMainScrollView *theScrollView;                       ///< scrollviewl
    
    PDFMainToolbar *mainToolbar;                            ///< 工具栏
    
    ReaderMainPagebar *mainPagebar;
    
    NSMutableDictionary *contentViews;                      ///< 包含所有的contentView (of ReaderContentView)
    
    UIUserInterfaceIdiom userInterfaceIdiom;
    
    NSInteger currentPage, minimumPage, maximumPage;
    
    UIDocumentInteractionController *documentInteraction;
    
    UIPrintInteractionController *printInteraction;
    
    CGFloat scrollViewOutset;
    
    CGSize lastAppearSize;
    
    NSDate *lastHideTime;
    
    BOOL ignoreDidScroll;
    
    UITapGestureRecognizer *singleTapOne, *doubleTapOne;
    
    BOOL isCurrentViewFreezing;                             ///< 当前视图是否冻结
    
    //--- added by CharlyZhang ---
    NSDictionary            *configuration;                 ///< 配置
    /// 自定义按钮
    UIPopoverController     *customPopoverCtrl;            ///< 自定义按钮的popover控制器
    NSMutableArray          *customNaviCtrls;               ///< 自定义按钮的导航控制器
    
    /// 目录
    UIPopoverController     *catalogPopoverController;
    UINavigationController  *catalogNaviController;
    
    /// 搜索
    UIPopoverController     *searchPopoverController;
    UINavigationController  *searchNaviController;
    Selection               *selectedSelection;             ///< 选中的搜索结果
    NSInteger               selectedPageNo;                 ///< 选中结果所在的页面(无跳转搜索结果时为－1，用作状态判断)
}

#pragma mark - Constants

#define STATUS_HEIGHT 20.0f

#define TOOLBAR_HEIGHT 64.0f
#define PAGEBAR_HEIGHT 48.0f

#define SCROLLVIEW_OUTSET_SMALL 4.0f
#define SCROLLVIEW_OUTSET_LARGE 8.0f

#define TAP_AREA_SIZE 48.0f

#pragma mark - Properties

@synthesize delegate,currentPage,document;

- (ReaderContentView*)currentContentView
{
    return [contentViews objectForKey:[NSNumber numberWithInteger:currentPage]];
}

- (UIView*)currentView
{
    return self.currentContentView.theContainerView;
}

#pragma mark - ReaderViewController methods

- (void)updateContentSize:(UIScrollView *)scrollView
{
    CGFloat contentHeight = scrollView.bounds.size.height; // Height
    
    CGFloat contentWidth = (scrollView.bounds.size.width * maximumPage);
    
    scrollView.contentSize = CGSizeMake(contentWidth, contentHeight);
}

- (void)updateContentViews:(UIScrollView *)scrollView
{
    [self updateContentSize:scrollView]; // Update content size first
    
    [contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
     ^(NSNumber *key, ReaderContentView *contentView, BOOL *stop)
     {
         NSInteger page = [key integerValue]; // Page number value
         
         CGRect viewRect = CGRectZero; viewRect.size = scrollView.bounds.size;
         
         viewRect.origin.x = (viewRect.size.width * (page - 1)); // Update X
         
         contentView.frame = CGRectInset(viewRect, scrollViewOutset, 0.0f);
     }
     ];
    
    NSInteger page = currentPage; // Update scroll view offset to current page
    
    CGPoint contentOffset = CGPointMake((scrollView.bounds.size.width * (page - 1)), 0.0f);
    
    if (CGPointEqualToPoint(scrollView.contentOffset, contentOffset) == false) // Update
    {
        scrollView.contentOffset = contentOffset; // Update content offset
    }
    
    [mainToolbar setBookmarkState:[document.bookmarks containsIndex:page]];
    
    [mainPagebar updatePagebar]; // Update page bar
}

- (void)addContentView:(UIScrollView *)scrollView page:(NSInteger)page
{
    CGRect viewRect = CGRectZero; viewRect.size = scrollView.bounds.size;
    
    viewRect.origin.x = (viewRect.size.width * (page - 1)); viewRect = CGRectInset(viewRect, scrollViewOutset, 0.0f);
    
    NSURL *fileURL = document.fileURL; NSString *phrase = document.password; NSString *guid = document.guid; // Document properties
    
    ReaderContentView *contentView = [[ReaderContentView alloc] initWithFrame:viewRect fileURL:fileURL page:page password:phrase]; // ReaderContentView
    
    /// set text search result
    if (page == selectedPageNo) {
        contentView.selection = selectedSelection;
        if (selectedSelection == nil) selectedPageNo = -1;      ///< reset when leave the selected page
        PDF_RELEASE(selectedSelection);
        selectedSelection = nil;
    }
    
    contentView.message = self; [contentViews setObject:contentView forKey:[NSNumber numberWithInteger:page]]; [scrollView addSubview:contentView];
    
    [contentView showPageThumb:fileURL page:page password:phrase guid:guid]; // Request page preview thumb
}

- (void)layoutContentViews:(UIScrollView *)scrollView
{
    /// hide the toolbar
    if ((mainToolbar.alpha > 0.0f) || (mainPagebar.alpha > 0.0f)) {
        [mainToolbar hideToolbar];  [mainPagebar hidePagebar];
    }
    CGFloat viewWidth = scrollView.bounds.size.width; // View width
    
    CGFloat contentOffsetX = scrollView.contentOffset.x; // Content offset X
    
    NSInteger pageB = ((contentOffsetX + viewWidth - 1.0f) / viewWidth); // Pages
    
    NSInteger pageA = (contentOffsetX / viewWidth); pageB += 2; // Add extra pages
    
    if (pageA < minimumPage) pageA = minimumPage; if (pageB > maximumPage) pageB = maximumPage;
    
    NSRange pageRange = NSMakeRange(pageA, (pageB - pageA + 1)); // Make page range (A to B)
    
    NSMutableIndexSet *pageSet = [NSMutableIndexSet indexSetWithIndexesInRange:pageRange];
    
    for (NSNumber *key in [contentViews allKeys]) // Enumerate content views
    {
        NSInteger page = [key integerValue]; // Page number value
        
        if ([pageSet containsIndex:page] == NO
            || page == selectedPageNo       ///< jump to the selected page OR leave the selected page
            ) // Remove content view
        {
            ReaderContentView *contentView = [contentViews objectForKey:key];
            
            [contentView removeFromSuperview]; [contentViews removeObjectForKey:key];
        }
        else // Visible content view - so remove it from page set
        {
            [pageSet removeIndex:page];
        }
    }
    
    NSInteger pages = pageSet.count;
    
    if (pages > 0) // We have pages to add
    {
        NSEnumerationOptions options = 0; // Default
        
        if (pages == 2) // Handle case of only two content views
        {
            if ((maximumPage > 2) && ([pageSet lastIndex] == maximumPage)) options = NSEnumerationReverse;
        }
        else if (pages == 3) // Handle three content views - show the middle one first
        {
            NSMutableIndexSet *workSet = [pageSet mutableCopy]; options = NSEnumerationReverse;
            
            [workSet removeIndex:[pageSet firstIndex]]; [workSet removeIndex:[pageSet lastIndex]];
            
            NSInteger page = [workSet firstIndex]; [pageSet removeIndex:page];
            
            [self addContentView:scrollView page:page];
        }
        
        [pageSet enumerateIndexesWithOptions:options usingBlock: // Enumerate page set
         ^(NSUInteger page, BOOL *stop)
         {
             [self addContentView:scrollView page:page];
         }
         ];
    }
}

- (void)handleScrollViewDidEnd:(UIScrollView *)scrollView
{
    CGFloat viewWidth = scrollView.bounds.size.width; // Scroll view width
    
    CGFloat contentOffsetX = scrollView.contentOffset.x; // Content offset X
    
    NSInteger page = (contentOffsetX / viewWidth); page++; // Page number
    
    if (page != currentPage) // Only if on different page
    {
        currentPage = page; document.pageNumber = [NSNumber numberWithInteger:page];
        
        [contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
         ^(NSNumber *key, ReaderContentView *contentView, BOOL *stop)
         {
             if ([key integerValue] != page){
                 [contentView zoomResetAnimated:NO];
                 [contentView removeEndorseView];
                 [contentView removeNoteView];
             }
         }
         ];
        
        [self.delegate updatePDFCurrentPage:currentPage];
        
        [mainToolbar setBookmarkState:[document.bookmarks containsIndex:page]];
        
        [mainPagebar updatePagebar]; // Update page bar
        
    }
}

- (void)showDocumentPage:(NSInteger)page
{
    if (page != currentPage || selectedSelection) // Only if on different page
    {
        if ((page < minimumPage) || (page > maximumPage)) return;
        
        currentPage = page; document.pageNumber = [NSNumber numberWithInteger:page];
        
        CGPoint contentOffset = CGPointMake((theScrollView.bounds.size.width * (page - 1)), 0.0f);
        
        if (CGPointEqualToPoint(theScrollView.contentOffset, contentOffset) == true)
            [self layoutContentViews:theScrollView];
        else        /// 通过改变contentOffset来触发scrollViewDidScroll，从而调用layoutContentViews，更新contentViews
            [theScrollView setContentOffset:contentOffset];
        
        [contentViews enumerateKeysAndObjectsUsingBlock: // Enumerate content views
         ^(NSNumber *key, ReaderContentView *contentView, BOOL *stop)
         {
             if ([key integerValue] != page){
                 [contentView zoomResetAnimated:NO];
                 [contentView removeEndorseView];
                 [contentView removeNoteView];
             }
         }
         ];
        
        [self.delegate updatePDFCurrentPage:currentPage];
        
        [mainToolbar setBookmarkState:[document.bookmarks containsIndex:page]];
        
        [mainPagebar updatePagebar]; // Update page bar
    }
    
    self.view.frame = [self getCurrentRealFrame];   ///< 这里的controller与模态进来时不一样，viewWillAppear中不能自动更新view的frame，所以手动更新。
}

- (void)showDocument
{
    [self updateContentSize:theScrollView]; // Update content size first
    
    [self showDocumentPage:[document.pageNumber integerValue]]; // Show page
    
    document.lastOpen = [NSDate date]; // Update document last opened date
}

/// 获取当前视图真正大小(保证ios 7以下版本在viewDidLoad中能取得正确view.frame)
-(CGRect)getCurrentRealFrame
{
    float version = [[[UIDevice currentDevice] systemVersion] floatValue];
    if (version >= 8.0) {
        return self.view.bounds;
    }
    
    CGRect frame;
    
    if ([[UIApplication sharedApplication] statusBarOrientation]==UIInterfaceOrientationPortrait||[[UIApplication sharedApplication] statusBarOrientation]==UIInterfaceOrientationPortraitUpsideDown)
    {
        frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    }
    else
    {
        frame = CGRectMake(0,0,[UIScreen mainScreen].bounds.size.height,[UIScreen mainScreen].bounds.size.width);
    }
    
    return frame;
}

- (void)closeDocument
{
    if (printInteraction != nil) [printInteraction dismissAnimated:NO];
    
    [document archiveDocumentProperties]; // Save any ReaderDocument changes
    
    [[ReaderThumbQueue sharedInstance] cancelOperationsWithGUID:document.guid];
    
    [[ReaderThumbCache sharedInstance] removeAllObjects]; // Empty the thumb cache
    
    if ([delegate respondsToSelector:@selector(dismissReaderViewController:)] == YES)
    {
        [delegate dismissReaderViewController:self]; // Dismiss the ReaderViewController
    }
    /// -modified by CharlyZhang
    else if (self.backShelfBlcok)
    {
        self.backShelfBlcok();
    } else
    {
        NSLog(@"backShelfBlock is nil");
    }
    /// -
    //    else // We have a "Delegate must respond to -dismissReaderViewController:" error
    //    {
    //        NSAssert(NO, @"Delegate must respond to -dismissReaderViewController:");
    //    }
}

- (void)updateStatusBar
{
    [self setNeedsStatusBarAppearanceUpdate];
}

- (BOOL)freezeCurrentView
{
    if (isCurrentViewFreezing) return YES;
    if (theScrollView.decelerating) return NO;
    
    isCurrentViewFreezing = YES;
    
    [self.view removeGestureRecognizer:singleTapOne];
    [self.view removeGestureRecognizer:doubleTapOne];
    
    theScrollView.scrollEnabled = NO;
    self.currentContentView.scrollEnabled = NO;
    
    [self.currentContentView zoomResetAnimated:NO];
    self.currentContentView.forbiddenScale = YES;
    
    return YES;
}

- (BOOL)restoreCurrentView
{
    if (!isCurrentViewFreezing) return YES;
    isCurrentViewFreezing = NO;
    
    theScrollView.pagingEnabled = YES;
    [self.view addGestureRecognizer:singleTapOne];
    [self.view addGestureRecognizer:doubleTapOne];
    theScrollView.scrollEnabled = YES;
    self.currentContentView.scrollEnabled = YES;
    self.currentContentView.forbiddenScale = NO;
    
    return YES;
}

- (BOOL)addEndorseView:(UIView *)view needEdit:(BOOL)flag
{
    [mainToolbar hideToolbar];
    [mainPagebar hidePagebar];
    
    if (flag) {
        if ([self.currentContentView viewWithTag:EDIT_TAG]) return NO;
        UIView *oldView = [self.currentView viewWithTag:ENDORSE_TAG];
        if (oldView) {
            [oldView removeFromSuperview];
        };
        
        view.tag = EDIT_TAG;
        [self.currentContentView addSubview:view];
    }
    else {
        UIView *oldView = [self.currentContentView viewWithTag:EDIT_TAG];
        if (oldView) {
            [oldView removeFromSuperview];
        };
        
        oldView = [self.currentView viewWithTag:ENDORSE_TAG];
        
        if (oldView) return NO;
        
        view.tag = ENDORSE_TAG;
        [self.currentView addSubview:view];
    }
    return YES;
    
}

- (BOOL)addNoteView:(UIView *)view needEdit:(BOOL)flag
{
    if (flag) {
        if ([self.currentContentView viewWithTag:EDIT_TAG]) return NO;
        view.tag = EDIT_TAG;
        [self.currentContentView addSubview:view];
    }
    else {
        UIView *oldView = [self.currentContentView viewWithTag:EDIT_TAG];
        if (oldView) {
            [oldView removeFromSuperview];
        };
        
        UIView *noteView = [self.currentView viewWithTag:NOTE_TAG];
        
        if (!noteView){
            noteView = [[UIView alloc]initWithFrame:self.currentView.bounds];
            noteView.tag = NOTE_TAG;
            [self.currentView addSubview:noteView];
            PDF_RELEASE(noteView);
        }
        [noteView addSubview:view];
    }
    
    return YES;
}


- (void)removeEndorseView:(BOOL)isEditing
{
    if (isEditing) {
        UIView *view = [self.currentContentView viewWithTag:EDIT_TAG];
        [view removeFromSuperview];
    }
    else {
        [self.currentContentView removeEndorseView];
    }
}

- (void)removeNoteView:(BOOL)isEditing
{
    if (isEditing) {
        UIView *view = [self.currentContentView viewWithTag:EDIT_TAG];
        [view removeFromSuperview];
    }
    else {
        [self.currentContentView removeNoteView];
    }
}

- (BOOL)addActionController:(UIViewController*)controller for:(NSUInteger)customButtonIndex
{
    if (customButtonIndex >= customNaviCtrls.count) {
        NSLog(@"%s - param is out of legal range!",__func__);
        return NO;
    }
    if (controller == nil) {
        NSLog(@"%s - param is nil!",__func__);
        return NO;
    }
    UINavigationController* naviCtrl = [[UINavigationController alloc]initWithRootViewController:controller];
    [customNaviCtrls replaceObjectAtIndex:customButtonIndex withObject:naviCtrl];
    PDF_RELEASE(naviCtrl);
    return YES;
}

- (void)dismissActionController
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [customPopoverCtrl dismissPopoverAnimated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIViewController methods

- (instancetype)initWithReaderDocument:(ReaderDocument *)object
{
    NSArray *customBtnImgs = [NSArray arrayWithObjects:[UIImage imageNamed:@"pdf_record_N"],
                              [UIImage imageNamed:@"pdf_record_H"], nil];
    NSDictionary *config = @{TOOLBAR_CUSTOM_BTNS_KEY:@[@{TOOLBAR_CUSTOM_BTN_IMAGES_KEY:customBtnImgs}]};
    
    return [self initWithReaderDocument:object configuration:config];
}


- (instancetype)initWithReaderDocument:(ReaderDocument *)object configuration:(NSDictionary*)config
{
    if ((self = [super initWithNibName:nil bundle:nil])) // Initialize superclass
    {
        if ((object != nil) && ([object isKindOfClass:[ReaderDocument class]])) // Valid object
        {
            userInterfaceIdiom = [UIDevice currentDevice].userInterfaceIdiom; // User interface idiom
            
            NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter]; // Default notification center
            
            [notificationCenter addObserver:self selector:@selector(applicationWillResign:) name:UIApplicationWillTerminateNotification object:nil];
            
            [notificationCenter addObserver:self selector:@selector(applicationWillResign:) name:UIApplicationWillResignActiveNotification object:nil];
            
            scrollViewOutset = ((userInterfaceIdiom == UIUserInterfaceIdiomPad) ? SCROLLVIEW_OUTSET_LARGE : SCROLLVIEW_OUTSET_SMALL);
            
            [object updateDocumentProperties]; document = object; // Retain the supplied ReaderDocument object for our use
            
            [ReaderThumbCache touchThumbCacheWithGUID:object.guid]; // Touch the document thumb cache directory
            
            isCurrentViewFreezing = NO;
        }
        else // Invalid ReaderDocument object
        {
            self = nil;
        }
    }
    
    configuration = [NSDictionary dictionaryWithDictionary:config];
    
    // create custom buttons' popoverCtrls
    NSArray *customBtns = (NSArray*) [configuration objectForKey:TOOLBAR_CUSTOM_BTNS_KEY];
    NSUInteger customBtnNumber = customBtns.count;
    
    customNaviCtrls = [[NSMutableArray alloc] initWithCapacity:customBtnNumber];
    for (NSUInteger i = 0; i < customBtnNumber; i++) [customNaviCtrls addObject:[NSNull null]];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    PDF_RELEASE(searchNaviController);
    PDF_RELEASE(searchPopoverController);
    PDF_RELEASE(selectedSelection);
    selectedSelection = nil;
    PDF_RELEASE(catalogNaviController);
    PDF_RELEASE(catalogPopoverController);
    PDF_RELEASE(customNaviCtrls);
    PDF_RELEASE(customPopoverCtrl);
    PDF_RELEASE(doubleTapOne);
    PDF_RELEASE(singleTapOne);
    
    PDF_SUPER_DEALLOC;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    assert(document != nil); // Must have a valid ReaderDocument
    
    self.view.backgroundColor = [UIColor grayColor]; // Neutral gray
    
    self.view.frame = [self getCurrentRealFrame];
    UIView *fakeStatusBar = nil; CGRect viewRect = self.view.bounds; // View bounds
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) // iOS 7+
    {
        if ([self prefersStatusBarHidden] == NO) // Visible status bar
        {
            //            CGRect statusBarRect = viewRect; statusBarRect.size.height = STATUS_HEIGHT;
            //            fakeStatusBar = [[UIView alloc] initWithFrame:statusBarRect]; // UIView
            //            fakeStatusBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            //            fakeStatusBar.backgroundColor = [UIColor blackColor];
            //            fakeStatusBar.contentMode = UIViewContentModeRedraw;
            //            fakeStatusBar.userInteractionEnabled = NO;
            //
            //            viewRect.origin.y += STATUS_HEIGHT; viewRect.size.height -= STATUS_HEIGHT;
        }
    }
    
    CGRect scrollViewRect = CGRectInset(viewRect, -scrollViewOutset, 0.0f);
    theScrollView = [[PDFMainScrollView alloc] initWithFrame:scrollViewRect]; // All
    theScrollView.autoresizesSubviews = NO;
    theScrollView.contentMode = UIViewContentModeRedraw;
    theScrollView.showsHorizontalScrollIndicator = NO;
    theScrollView.showsVerticalScrollIndicator = NO;
    theScrollView.scrollsToTop = NO;
    theScrollView.delaysContentTouches = NO;
    theScrollView.pagingEnabled = YES;
    theScrollView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    theScrollView.backgroundColor = [UIColor clearColor];
    theScrollView.delegate = self;
    theScrollView.mainScrollViewDelegate = self;
    [self.view addSubview:theScrollView];
    
    CGRect toolbarRect = viewRect; toolbarRect.size.height = TOOLBAR_HEIGHT;
    
    
    mainToolbar = [[PDFMainToolbar alloc] initWithFrame:toolbarRect document:document cofiguration:configuration]; // PDFMainToolbar
    mainToolbar.delegate = self; // PDFMainToolbarDelegate
    [self.view addSubview:mainToolbar];
    
#if READER_ENABLE_PAGE_BAR
    CGRect pagebarRect = self.view.bounds; pagebarRect.size.height = PAGEBAR_HEIGHT;
    pagebarRect.origin.y = (self.view.bounds.size.height - pagebarRect.size.height);
    mainPagebar = [[ReaderMainPagebar alloc] initWithFrame:pagebarRect document:document]; // ReaderMainPagebar
    mainPagebar.delegate = self; // ReaderMainPagebarDelegate
    [self.view addSubview:mainPagebar];
#endif
    
    if (fakeStatusBar != nil) [self.view addSubview:fakeStatusBar]; // Add status bar background view
    
    [mainToolbar hideToolbar];  [mainPagebar hidePagebar];
    
    singleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap:)];
    singleTapOne.numberOfTouchesRequired = 1; singleTapOne.numberOfTapsRequired = 1; singleTapOne.delegate = self;
    [self.view addGestureRecognizer:singleTapOne];
    
    doubleTapOne = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
    doubleTapOne.numberOfTouchesRequired = 1; doubleTapOne.numberOfTapsRequired = 2; doubleTapOne.delegate = self;
    [self.view addGestureRecognizer:doubleTapOne];
    
    [singleTapOne requireGestureRecognizerToFail:doubleTapOne]; // Single tap requires double tap to fail
    
    contentViews = [NSMutableDictionary new]; lastHideTime = [NSDate date];
    
    minimumPage = 1; maximumPage = [document.pageCount integerValue];
    
    selectedPageNo = -1;
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (CGSizeEqualToSize(lastAppearSize, CGSizeZero) == false)
    {
        if (CGSizeEqualToSize(lastAppearSize, self.view.bounds.size) == false)
        {
            [self updateContentViews:theScrollView]; // Update content views
        }
        
        lastAppearSize = CGSizeZero; // Reset view size tracking
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (CGSizeEqualToSize(theScrollView.contentSize, CGSizeZero) == true)
    {
        [self performSelector:@selector(showDocument) withObject:nil afterDelay:0.0];
    }
    
#if (READER_DISABLE_IDLE == TRUE) // Option
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
#endif // end of READER_DISABLE_IDLE Option
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    lastAppearSize = self.view.bounds.size; // Track view size
    
#if (READER_DISABLE_IDLE == TRUE) // Option
    
    [UIApplication sharedApplication].idleTimerDisabled = NO;
    
#endif // end of READER_DISABLE_IDLE Option
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (void)viewDidUnload
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    mainToolbar = nil; mainPagebar = nil;
    
    theScrollView = nil; contentViews = nil; lastHideTime = nil;
    
    documentInteraction = nil; printInteraction = nil;
    
    lastAppearSize = CGSizeZero; currentPage = 0;
    
    [super viewDidUnload];
}

- (BOOL)prefersStatusBarHidden
{
    return mainToolbar.hidden;
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (userInterfaceIdiom == UIUserInterfaceIdiomPad)
        if (printInteraction != nil) [printInteraction dismissAnimated:NO];
    
    ignoreDidScroll = YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    if (CGSizeEqualToSize(theScrollView.contentSize, CGSizeZero) == false)
    {
        [self updateContentViews:theScrollView]; lastAppearSize = CGSizeZero;
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
    ignoreDidScroll = NO;
}

- (void)didReceiveMemoryWarning
{
#ifdef DEBUG
    NSLog(@"%s", __FUNCTION__);
#endif
    
    [super didReceiveMemoryWarning];
}

#pragma mark - UIScrollViewDelegate methods

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
#ifdef DEBUG
    NSLog(@"ReaderViewController - scrollViewDidScroll");
#endif
    if (ignoreDidScroll == NO) [self layoutContentViews:scrollView];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
#ifdef DEBUG
    NSLog(@"ReaderViewController - scrollViewDidEndDecelerating");
#endif
    [self handleScrollViewDidEnd:scrollView];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
#ifdef DEBUG
    NSLog(@"ReaderViewController - scrollViewDidEndScrollingAnimation");
#endif
    [self handleScrollViewDidEnd:scrollView];
}


- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
#ifdef DEBUG
    NSLog(@"ReaderViewController - scrollViewDidEndDragging, decelerate - %d",decelerate);
#endif
}

#pragma mark - PDFMainScrollViewController methods

- (BOOL)touchesShouldCancelInMainScrollView:(UIView *)view
{
    //    if ([view isKindOfClass:[SmallNoteView class]]) {
    if (view.superview && view.superview.tag == NOTE_TAG) {
#ifdef DEBUG
        NSLog(@"touchesShouldCancelInMainScrollView - NO");
#endif
        return NO;
    }
#ifdef DEBUG
    NSLog(@"touchesShouldCancelInMainScrollView - YES");
#endif
    return YES;
}

#pragma mark - UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)recognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;                 ///< ! change to YES anytime, for noteViews' moving event
    if ([touch.view isKindOfClass:[UIScrollView class]]) return YES;
    
    return NO;
}

#pragma mark - UIGestureRecognizer action methods

- (void)decrementPageNumber
{
    if ((maximumPage > minimumPage) && (currentPage != minimumPage))
    {
        CGPoint contentOffset = theScrollView.contentOffset; // Offset
        
        contentOffset.x -= theScrollView.bounds.size.width; // View X--
        
        [theScrollView setContentOffset:contentOffset animated:YES];
    }
}

- (void)incrementPageNumber
{
    if ((maximumPage > minimumPage) && (currentPage != maximumPage))
    {
        CGPoint contentOffset = theScrollView.contentOffset; // Offset
        
        contentOffset.x += theScrollView.bounds.size.width; // View X++
        
        [theScrollView setContentOffset:contentOffset animated:YES];
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)recognizer
{
#ifdef DEBUG
    NSLog(@"%s",__FUNCTION__);
#endif
    
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        CGRect viewRect = recognizer.view.bounds; // View bounds
        
        CGPoint point = [recognizer locationInView:recognizer.view]; // Point
        //
        //        CGRect areaRect = CGRectInset(viewRect, TAP_AREA_SIZE, 0.0f); // Area rect
        //
        //        if (CGRectContainsPoint(areaRect, point) == true) // Single tap is inside area
        //        {
        //            NSNumber *key = [NSNumber numberWithInteger:currentPage]; // Page number key
        //
        //            ReaderContentView *targetView = [contentViews objectForKey:key]; // View
        //
        //            id target = [targetView processSingleTap:recognizer]; // Target object
        //
        //            if (target != nil) // Handle the returned target object
        //            {
        //                if ([target isKindOfClass:[NSURL class]]) // Open a URL
        //                {
        //                    NSURL *url = (NSURL *)target; // Cast to a NSURL object
        //
        //                    if (url.scheme == nil) // Handle a missing URL scheme
        //                    {
        //                        NSString *www = url.absoluteString; // Get URL string
        //
        //                        if ([www hasPrefix:@"www"] == YES) // Check for 'www' prefix
        //                        {
        //                            NSString *http = [[NSString alloc] initWithFormat:@"http://%@", www];
        //
        //                            url = [NSURL URLWithString:http]; // Proper http-based URL
        //                        }
        //                    }
        //
        //                    if ([[UIApplication sharedApplication] openURL:url] == NO)
        //                    {
        //#ifdef DEBUG
        //                        NSLog(@"%s '%@'", __FUNCTION__, url); // Bad or unknown URL
        //#endif
        //                    }
        //                }
        //                else // Not a URL, so check for another possible object type
        //                {
        //                    if ([target isKindOfClass:[NSNumber class]]) // Goto page
        //                    {
        //                        NSInteger number = [target integerValue]; // Number
        //
        //                        [self showDocumentPage:number]; // Show the page
        //                    }
        //                }
        //            }
        //            else // Nothing active tapped in the target content view
        //            {
        //                if ([lastHideTime timeIntervalSinceNow] < -0.75) // Delay since hide
        //                {
        //                    if ((mainToolbar.alpha < 1.0f) || (mainPagebar.alpha < 1.0f)) // Hidden
        //                    {
        //                        [mainToolbar showToolbar]; [mainPagebar showPagebar]; // Show
        //                    }
        //                }
        //            }
        //
        //            return;
        //        }
        
        //        if (!mainToolbar.hidden) {
        //            [mainToolbar hideToolbar];  [mainPagebar hidePagebar];
        //            return;
        //        }
        
        CGRect nextPageRect = viewRect;
        nextPageRect.size.width = viewRect.size.width / 3;
        nextPageRect.origin.x = (viewRect.size.width / 3) * 2;
        
        if (CGRectContainsPoint(nextPageRect, point) == true) // page++
        {
            [self incrementPageNumber]; return;
        }
        
        CGRect prevPageRect = viewRect;
        prevPageRect.size.width = viewRect.size.width / 3;
        
        if (CGRectContainsPoint(prevPageRect, point) == true) // page--
        {
            [self decrementPageNumber]; return;
        }
        
        if (!mainToolbar.hidden) {
            [mainToolbar hideToolbar];  [mainPagebar hidePagebar];
            return;
        }
    }
}

- (void)handleDoubleTap:(UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateRecognized)
    {
        CGRect viewRect = recognizer.view.bounds; // View bounds
        
        CGPoint point = [recognizer locationInView:recognizer.view]; // Point
        
        CGRect zoomArea = CGRectInset(viewRect, TAP_AREA_SIZE, TAP_AREA_SIZE); // Area
        
        if (CGRectContainsPoint(zoomArea, point) == true) // Double tap is inside zoom area
        {
            if (mainToolbar.hidden) {
                [mainToolbar showToolbar]; [mainPagebar showPagebar];
            }
            else {
                [mainToolbar hideToolbar]; [mainPagebar hidePagebar];
            }
        }
    }
}

- (IBAction)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer {
    NSInteger page = [document.pageNumber integerValue];
    NSInteger maxPage = [document.pageCount integerValue];
    NSInteger minPage = 1; // Minimum
    CGPoint location = [recognizer locationInView:self.view];
    // [self showImageWithText:@"swipe" atPoint:location];
    
    if (recognizer.direction == UISwipeGestureRecognizerDirectionLeft) {
        location.x -= 220.0;
        NSLog(@"Swip Left");
        
        if ((maxPage > minPage) && (page != maxPage))
        {
            [self TurnPageRight];
        }
        
        
    }
    else {
        location.x += 220.0;
        NSLog(@"Swip Right");
        
        if ((maxPage > minPage) && (page != minPage))
        {
            [self TurnPageLeft];
        }
        
    }
}
-(void)TurnPageLeft{
    CATransition *transition = [CATransition animation];
    [transition setDelegate:self];
    [transition setDuration:0.5f];
    
    [transition setSubtype:kCATransitionFromRight];
    [transition setType:@"pageUnCurl"];
    [self.view.layer addAnimation:transition forKey:@"UnCurlAnim"];
    
    [self showDocumentPage:currentPage-1];
    
}
-(void)TurnPageRight{
    CATransition *transition = [CATransition animation];
    [transition setDelegate:self];
    [transition setDuration:0.5f];
    
    [transition setSubtype:@"fromRight"];
    [transition setType:@"pageCurl"];
    [self.view.layer addAnimation:transition forKey:@"CurlAnim"];
    
    [self showDocumentPage:currentPage+1];
}

#pragma mark - ReaderContentViewDelegate methods

- (void)contentView:(ReaderContentView *)contentView touchesBegan:(NSSet *)touches
{
    //    if ((mainToolbar.alpha > 0.0f) || (mainPagebar.alpha > 0.0f))
    //    {
    //        if (touches.count == 1) // Single touches only
    //        {
    //            UITouch *touch = [touches anyObject]; // Touch info
    //
    //            CGPoint point = [touch locationInView:self.view]; // Touch location
    //
    //            CGRect areaRect = CGRectInset(self.view.bounds, TAP_AREA_SIZE, TAP_AREA_SIZE);
    //
    //            if (CGRectContainsPoint(areaRect, point) == false) return;
    //        }
    //
    //        [mainToolbar hideToolbar]; [mainPagebar hidePagebar]; // Hide
    //
    //        lastHideTime = [NSDate date]; // Set last hide time
    //    }
}

#pragma mark - ReaderMainToolbarDelegate methods

- (void)tappedInToolbar:(PDFMainToolbar *)toolbar returnButton:(UIButton *)button
{
#if (READER_STANDALONE == FALSE) // Option
    
    [self closeDocument]; // Close ReaderViewController
    
#endif // end of READER_STANDALONE Option
}


- (void)tappedInToolbar:(PDFMainToolbar *)toolbar pageButton:(UIButton *)button
{
#if (READER_PAGE_MODE == TRUE) // Option
    
    if ([button isSelected]) {
        button.selected=NO;
        theScrollView.scrollEnabled=YES;
        
        for (UIGestureRecognizer *recView in [self.view gestureRecognizers]) {
            if ([recView isKindOfClass:[UISwipeGestureRecognizer class]]) {
                [self.view removeGestureRecognizer:recView];
            }
        }
        
        [button setTitleColor:[UIColor colorWithWhite:0.0f alpha:1.0f] forState:UIControlStateNormal];
    }
    else{
        button.selected=YES;
        theScrollView.scrollEnabled=NO;
        
        UISwipeGestureRecognizer *swipeLeftRecognizerLeft=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
        swipeLeftRecognizerLeft.direction=UISwipeGestureRecognizerDirectionLeft;
        [self.view addGestureRecognizer:swipeLeftRecognizerLeft];
        
        UISwipeGestureRecognizer *swipeLeftRecognizerRight=[[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
        swipeLeftRecognizerRight.direction=UISwipeGestureRecognizerDirectionRight;
        [self.view addGestureRecognizer:swipeLeftRecognizerRight];
        [button setTitleColor:[UIColor colorWithRed:102/255.0 green:102/255.0 blue:255/255.0 alpha:1.0f] forState:UIControlStateNormal];
        
    }
    
#endif // end of READER_PAGE_MODE Option
}

- (void)tappedInToolbar:(PDFMainToolbar *)toolbar searchButton:(UIButton *)button
{
#if (READER_ENABLE_SEARCH == TRUE) // Option
    
    if (!searchNaviController) {
        PDFSearchViewController *searchController = [[PDFSearchViewController alloc]initWithReaderDocument:document atPage:currentPage];
        searchController.delegate = self;
        searchNaviController = [[UINavigationController alloc]initWithRootViewController:searchController];
        PDF_RELEASE(searchController);
    } else {
        PDFSearchViewController *searchController = (PDFSearchViewController*)[searchNaviController topViewController];
        searchController.currentPage = currentPage;
    }
    
    if (isPad) {
        if (!searchPopoverController) {
            searchPopoverController = [[UIPopoverController alloc]initWithContentViewController:searchNaviController];
            searchPopoverController.delegate = self;
        }
        
        [searchPopoverController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else {
        [self presentViewController:searchNaviController animated:YES completion:nil];
    }
    
#endif // end of READER_ENABLE_SEARCH Option
    
}

- (void)tappedInToolbar:(PDFMainToolbar *)toolbar thumbsButton:(UIButton *)button
{
#if (READER_ENABLE_THUMBS == TRUE) // Option
    
    if (printInteraction != nil) [printInteraction dismissAnimated:NO];
    
    ThumbsViewController *thumbsViewController = [[ThumbsViewController alloc] initWithReaderDocument:document configuration:configuration];
    
    thumbsViewController.title = self.title; thumbsViewController.delegate = self; // ThumbsViewControllerDelegate
    
    thumbsViewController.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    thumbsViewController.modalPresentationStyle = UIModalPresentationFullScreen;
    
    [self presentViewController:thumbsViewController animated:NO completion:NULL];
    
#endif // end of READER_ENABLE_THUMBS Option
}

- (void)tappedInToolbar:(PDFMainToolbar *)toolbar exportButton:(UIButton *)button
{
    if (printInteraction != nil) [printInteraction dismissAnimated:YES];
    
    NSURL *fileURL = document.fileURL; // Document file URL
    
    documentInteraction = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    
    documentInteraction.delegate = self; // UIDocumentInteractionControllerDelegate
    
    [documentInteraction presentOpenInMenuFromRect:button.bounds inView:button animated:YES];
}

- (void)tappedInToolbar:(PDFMainToolbar *)toolbar printButton:(UIButton *)button
{
    if ([UIPrintInteractionController isPrintingAvailable] == YES)
    {
        NSURL *fileURL = document.fileURL; // Document file URL
        
        if ([UIPrintInteractionController canPrintURL:fileURL] == YES)
        {
            printInteraction = [UIPrintInteractionController sharedPrintController];
            
            UIPrintInfo *printInfo = [UIPrintInfo printInfo];
            printInfo.duplex = UIPrintInfoDuplexLongEdge;
            printInfo.outputType = UIPrintInfoOutputGeneral;
            printInfo.jobName = document.fileName;
            
            printInteraction.printInfo = printInfo;
            printInteraction.printingItem = fileURL;
            printInteraction.showsPageRange = YES;
            
            if (userInterfaceIdiom == UIUserInterfaceIdiomPad) // Large device printing
            {
                [printInteraction presentFromRect:button.bounds inView:button animated:YES completionHandler:
                 ^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
                 {
#ifdef DEBUG
                     if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
#endif
                 }
                 ];
            }
            else // Handle printing on small device
            {
                [printInteraction presentAnimated:YES completionHandler:
                 ^(UIPrintInteractionController *pic, BOOL completed, NSError *error)
                 {
#ifdef DEBUG
                     if ((completed == NO) && (error != nil)) NSLog(@"%s %@", __FUNCTION__, error);
#endif
                 }
                 ];
            }
        }
    }
}

- (void)tappedInToolbar:(PDFMainToolbar *)toolbar emailButton:(UIButton *)button
{
    if ([MFMailComposeViewController canSendMail] == NO) return;
    
    if (printInteraction != nil) [printInteraction dismissAnimated:YES];
    
    unsigned long long fileSize = [document.fileSize unsignedLongLongValue];
    
    if (fileSize < 15728640ull) // Check attachment size limit (15MB)
    {
        NSURL *fileURL = document.fileURL; NSString *fileName = document.fileName;
        
        NSData *attachment = [NSData dataWithContentsOfURL:fileURL options:(NSDataReadingMapped|NSDataReadingUncached) error:nil];
        
        if (attachment != nil) // Ensure that we have valid document file attachment data available
        {
            MFMailComposeViewController *mailComposer = [MFMailComposeViewController new];
            
            [mailComposer addAttachmentData:attachment mimeType:@"application/pdf" fileName:fileName];
            
            [mailComposer setSubject:fileName]; // Use the document file name for the subject
            
            mailComposer.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            mailComposer.modalPresentationStyle = UIModalPresentationFormSheet;
            
            mailComposer.mailComposeDelegate = self; // MFMailComposeViewControllerDelegate
            
            [self presentViewController:mailComposer animated:YES completion:NULL];
        }
    }
}

- (void)tappedInToolbar:(PDFMainToolbar *)toolbar markButton:(UIButton *)button
{
#if (READER_BOOKMARKS == TRUE) // Option
    
    if (printInteraction != nil) [printInteraction dismissAnimated:YES];
    
    if ([document.bookmarks containsIndex:currentPage]) // Remove bookmark
    {
        [document.bookmarks removeIndex:currentPage]; [mainToolbar setBookmarkState:NO];
        
    }
    else // Add the bookmarked page number to the bookmark index set
    {
        [document.bookmarks addIndex:currentPage]; [mainToolbar setBookmarkState:YES];
    }
    
#endif // end of READER_BOOKMARKS Option
}


- (void)tappedInToolbar:(PDFMainToolbar *)toolbar catalogButton:(UIButton *)button
{
    if (!catalogNaviController) {
        PDFCatalogViewController *catalogController = [[PDFCatalogViewController alloc]initWithReaderDocument:document configuration:configuration];
        catalogController.delegate = self;
        catalogNaviController =[[UINavigationController alloc]initWithRootViewController:catalogController];
        PDF_RELEASE(catalogController);
    }
    
    if (isPad) {
        if (!catalogPopoverController) {
            catalogPopoverController = [[UIPopoverController alloc]initWithContentViewController:catalogNaviController];
            catalogPopoverController.delegate = self;
        }
        
        [catalogPopoverController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else{
        [self presentViewController:catalogNaviController animated:YES completion:nil];
    }
    
}

- (void)tappedInToolbar:(PDFMainToolbar *)toolbar customButton:(UIButton *)button
{
    NSUInteger buttonTag = button.tag - TOOLBAR_CUSTOM_BTN_INIT_TAG;
    assert(buttonTag >= 0 && buttonTag < customNaviCtrls.count);
    
    // add default ctrl
    if ((NSNull *)customNaviCtrls[buttonTag] == [NSNull null]) {
        UIViewController *ctrl = [[UIViewController alloc]init];
        UINavigationController* naviCtrl = [[UINavigationController alloc]initWithRootViewController:ctrl];
        [customNaviCtrls replaceObjectAtIndex:buttonTag withObject:naviCtrl];
        PDF_RELEASE(naviCtrl);
        PDF_RELEASE(ctrl);
    }
    
    [self.delegate pdfCustomActionControllerWillAppearFor:buttonTag];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        if (customPopoverCtrl) PDF_RELEASE(customPopoverCtrl);
        customPopoverCtrl = [[UIPopoverController alloc] initWithContentViewController:customNaviCtrls[buttonTag]];
        customPopoverCtrl.delegate = self;
        [customPopoverCtrl presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    }
    else {
        [self presentViewController:customNaviCtrls[buttonTag] animated:YES completion:nil];
    }
}


- (void)tappedInToolbar:(PDFMainToolbar *)toolbar switchPOButton:(UISegmentedControl *)button
{
}


#pragma mark - PDFCatalogDelegate methods

-(void)didSelectCatalogToPage:(NSInteger)pageNumber
{
    [self showDocumentPage:pageNumber];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [catalogPopoverController dismissPopoverAnimated:YES];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - UIPopoverControllerDelegate methods
- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if ([popoverController.contentViewController isKindOfClass:[UINavigationController class]]){
        UIViewController *viewCtrl = [(UINavigationController*) popoverController.contentViewController topViewController];
        
        if ([viewCtrl isKindOfClass:[PDFSearchViewController class]]) {
            PDFSearchViewController *searchController = (PDFSearchViewController*)viewCtrl;
            [searchController pauseSearching];
        }
        else if ([popoverController isEqual:customPopoverCtrl]) {
            for (int i = 0; i < customNaviCtrls.count; i++) {
                if ([popoverController.contentViewController isEqual:customNaviCtrls[i]]) {
                    [self.delegate pdfCustomActionControllerDiddissmissFor:i];
                    break;
                }
            }
        }
    }
    
    [mainToolbar hideToolbar]; [mainPagebar hidePagebar];
}

/// for IOS 7
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 70000
- (void)popoverController:(UIPopoverController *)popoverController willRepositionPopoverToRect:(inout CGRect *)rect inView:(inout UIView **)view {
    
    if ([popoverController.contentViewController isKindOfClass:[UINavigationController class]]){
        UIViewController *viewCtrl = [(UINavigationController*) popoverController.contentViewController topViewController];
        if ([viewCtrl isKindOfClass:[PDFCatalogViewController class]]) {
            *rect = mainToolbar.catalogButton.frame;
        }
        if ([viewCtrl isKindOfClass:[PDFSearchViewController class]]) {
            *rect = mainToolbar.searchButton.frame;
        }
        else {
            for (int i = 0; i < customNaviCtrls.count; i++) {
                if ([popoverController.contentViewController isEqual:customNaviCtrls[i]]) {
                    *rect = [(UIButton*)mainToolbar.customButtons[i] frame];
                }
            }
        }
    }
}
#endif

#pragma mark - MFMailComposeViewControllerDelegate methods

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error
{
#ifdef DEBUG
    if ((result == MFMailComposeResultFailed) && (error != NULL)) NSLog(@"%@", error);
#endif
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - UIDocumentInteractionControllerDelegate methods

- (void)documentInteractionControllerDidDismissOpenInMenu:(UIDocumentInteractionController *)controller
{
    documentInteraction = nil;
}

#pragma mark - ThumbsViewControllerDelegate methods

- (void)thumbsViewController:(ThumbsViewController *)viewController gotoPage:(NSInteger)page
{
#if (READER_ENABLE_THUMBS == TRUE) // Option
    
    [self showDocumentPage:page];
    
#endif // end of READER_ENABLE_THUMBS Option
}

- (void)dismissThumbsViewController:(ThumbsViewController *)viewController
{
#if (READER_ENABLE_THUMBS == TRUE) // Option
    
    [self dismissViewControllerAnimated:NO completion:NULL];
    
#endif // end of READER_ENABLE_THUMBS Option
}

#pragma mark - ReaderMainPagebarDelegate methods

- (void)pagebar:(ReaderMainPagebar *)pagebar gotoPage:(NSInteger)page
{
    [self showDocumentPage:page];
}

#pragma mark - UIApplication notification methods

- (void)applicationWillResign:(NSNotification *)notification
{
    [document archiveDocumentProperties]; // Save any ReaderDocument changes
    
    if (userInterfaceIdiom == UIUserInterfaceIdiomPad) if (printInteraction != nil) [printInteraction dismissAnimated:NO];
}

#pragma mark - PDFSearchViewControllerDelegate methods

- (void)selectSearchResult:(Selection *)selection
{
    selectedPageNo = selection.pageNo;
    selectedSelection = [selection copy];
    [self showDocumentPage:selection.pageNo];
    
    if (isPad) {
        [searchPopoverController dismissPopoverAnimated:YES];
    }
    else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end

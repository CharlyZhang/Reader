//
//  PDFSearchViewController.m
//  E-Publishing
//
//  Created by 李 雷川 on 14/12/26.
//
//  Modified by CharlyZhang on 15/2/8

#import "PDFSearchViewController.h"
#import "ReaderDocument.h"
#import "Searcher.h"
#import "Selection.h"
#import "PDFConstants.h"

#define UPDATE_DYNAMIC 1
#define PAGE_PER_THREAD 40          ///< 每个线程处理的页面数

#define NAVIGATOR_HEIGHT    64
#define SEARCHBAR_HEIGHT    44
#define CANCEL_BTN_WIDTH    84
#define CELL_HEIGHT         96
#define VIEW_WIDTH          320
//#define DEBUG_SEARCH_UI

@interface PDFSearchViewController ()<UITableViewDelegate,UITableViewDataSource,
UISearchBarDelegate,UISearchDisplayDelegate,SearcherDelegate>
{
    ReaderDocument* document;
    NSInteger currentPage;                          ///< 进入时的当前页码
    UITableView *tableview;
    UISearchBar *searchBar;
    UIView *searchView;                             ///< 将搜索条放在一个UIView上
    
    NSUInteger  currentResultsNumber;               ///< 当前搜索结果的数目
    BOOL searching;                                 ///< 是否开始搜索
}

@property(nonatomic, strong) Searcher           *searcher;
@property(nonatomic, strong) UITableView        *tableview;

@end

@implementation PDFSearchViewController
@synthesize currentPage;

#pragma mark - Properties

@synthesize tableview;

- (Searcher *)searcher
{
    if (!_searcher)
    {
        _searcher = [[Searcher alloc] initWithDocument:document];
        _searcher.delegate = self;
    }
    return _searcher;
}

#pragma mark - Initialization
- (id)initWithReaderDocument:(ReaderDocument*)object atPage:(NSInteger)pageNo
{
    if (self = [super init]) {
        document = object;
        currentPage = pageNo;
        searching = NO;
    }
    return self;
}

#pragma mark - PDFSearchViewController methods

- (void)pauseSearching
{
    [self.searcher pause];
}

- (void)cancelAction:(id)sender
{
    [searchBar resignFirstResponder];
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)printFrame:(UIView*)view for:(NSString*)name
{
    CGRect frame = view.frame;
    NSLog(@"%@\t(%0.0f,%0.0f,%0.0f,%0.0f)",name,frame.origin.x,frame.origin.y,frame.size.width,frame.size.height);
}


- (void)printDebugFrameWhen:(NSString*)debugName
{
#ifdef DEBUG_SEARCH_UI
    NSLog(@"Debug - %@",debugName);
    [self printFrame:self.navigationController.navigationBar for:@"navigatorBar"];
    [self printFrame:searchView for:@"searchView"];
    [self printFrame:searchBar for:@"searchBar"];
    [self printFrame:self.view for:@"self.view"];
    [self printFrame:tableview for:@"tableview"];
    printf("\n");
#endif
}

- (void)adjustSearchViewWidth
{
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        CGRect frame = searchView.frame;
        frame.size.width = CGRectGetWidth(self.view.frame) - CANCEL_BTN_WIDTH;
        searchView.frame = frame;
    }
}

#pragma mark - UIViewController methods

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        searchView =[[UIView alloc]initWithFrame:CGRectMake(0, 0,CGRectGetWidth(self.view.frame) - CANCEL_BTN_WIDTH, SEARCHBAR_HEIGHT)];
        UINavigationBar *bar = [self.navigationController navigationBar];
        CGRect frame = bar.frame;
        frame.size.height = NAVIGATOR_HEIGHT;
        bar.frame = frame;

//        searchView =[[UIView alloc]init];

        UIBarButtonItem *cancelButtonItem = [[UIBarButtonItem alloc]initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelAction:)];
        self.navigationItem.rightBarButtonItem = cancelButtonItem;
        PDF_RELEASE(cancelButtonItem);
        UIBarButtonItem *searchButtonItem = [[UIBarButtonItem alloc]initWithCustomView:searchView];
        self.navigationItem.leftBarButtonItem = searchButtonItem;
        PDF_RELEASE(searchButtonItem);
        
//        NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(searchView);
//        NSDictionary *metrics = @{@"padding":@20,@"barHeight":@44,@"cancelWidth":@84};
//        NSArray *constraints = [NSLayoutConstraint
//                                constraintsWithVisualFormat:@"V:|-padding-[searchView(barHeight)]-|"
//                                options:0
//                                metrics:metrics
//                                views:viewsDictionary];
//        
//        constraints = [constraints arrayByAddingObjectsFromArray:[NSLayoutConstraint
//                                                                 constraintsWithVisualFormat:@"H:|-[searchView]-cancelWidth-|"
//                                                                 options:0
//                                                                 metrics:metrics
//                                                                 views:viewsDictionary]];
//        
//        [searchView addConstraints:constraints];

    }
    else {
        searchView =[[UIView alloc]initWithFrame:CGRectMake(0,0,VIEW_WIDTH,SEARCHBAR_HEIGHT)];
        self.navigationItem.titleView = searchView;
        
        [self setPreferredContentSize:CGSizeMake(VIEW_WIDTH, 0)];
    }

//  CGFloat width = CGRectGetWidth(self.view.frame);
   // searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, searchView.frame.size.width,SEARCHBAR_HEIGHT)];
    searchBar = [[UISearchBar alloc]init];
    [searchBar setPlaceholder:@"请输入检索词"];
    searchBar.delegate = self;
    //searchBar.showsScopeBar= NO;
    searchBar.translucent = YES;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    //searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"本页",@"全文", nil];
    searchBar.selectedScopeButtonIndex = 1;
    [searchBar sizeToFit];
    [searchView addSubview:searchBar];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(searchBar);
    NSArray *constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"V:|-0-[searchBar]-0-|"
                            options:0
                            metrics:nil
                            views:viewsDictionary];

    constraints = [constraints arrayByAddingObjectsFromArray:[NSLayoutConstraint
                                                              constraintsWithVisualFormat:@"H:|-0-[searchBar]-0-|"
                                                              options:0
                                                              metrics:nil
                                                              views:viewsDictionary]];
    
    [searchView addConstraints:constraints];

  //  tableview = [[UITableView alloc]initWithFrame:CGRectMake(0, 0,  self.view.bounds.size.width, self.view.bounds.size.height)];
    tableview = [[UITableView alloc]init];
    tableview.estimatedRowHeight = CELL_HEIGHT;
    tableview.delegate = self;
    tableview.dataSource = self;
    tableview.bounces = YES;
    tableview.showsHorizontalScrollIndicator = NO;
    tableview.showsVerticalScrollIndicator = YES;
    tableview.translatesAutoresizingMaskIntoConstraints = NO;
    //tableview.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.view addSubview:tableview];
    
    viewsDictionary = NSDictionaryOfVariableBindings(tableview);
    constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"V:|-0-[tableview]-0-|"
                            options:0
                            metrics:nil
                            views:viewsDictionary];
    
    constraints = [constraints arrayByAddingObjectsFromArray:[NSLayoutConstraint
                                                              constraintsWithVisualFormat:@"H:|-0-[tableview]-0-|"
                                                              options:0
                                                              metrics:nil
                                                              views:viewsDictionary]];
    
    [self.view addConstraints:constraints];

    //[self setPreferredContentSize:CGSizeMake(VIEW_WIDTH, SEARCHBAR_HEIGHT)];
    
    currentResultsNumber = 0;
}

- (void)viewWillAppear:(BOOL)animated
{
    [self printDebugFrameWhen:@"viewWillAppear"];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(){
        @try {
            [self.searcher resume];
        }
        @catch (NSException *exception) {
            NSLog(@"PDF resume searching Error : %@",exception);
        }
    });
}
-(void)viewDidAppear:(BOOL)animated
{
    [self adjustSearchViewWidth];
    
    [self printDebugFrameWhen:@"viewDidAppear"];

    [searchBar becomeFirstResponder];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation duration:(NSTimeInterval)duration
{
    if (isPad == NO) [self printDebugFrameWhen:@"willRotation before adjust"];
    [self adjustSearchViewWidth];
    if (isPad == NO) [self printDebugFrameWhen:@"willRotation after adjust"];
}

- (BOOL)prefersStatusBarHidden
{
    return NO;
}

#pragma mark - SearchDelegate methods
- (void)updateSearchResults
{
    currentResultsNumber = self.searcher.searchResults.count;
    
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 8.0) {
        [self.tableview beginUpdates];
        [self.tableview insertRowsAtIndexPaths:self.searcher.updateIndexPath withRowAnimation:UITableViewRowAnimationTop];
        [self.tableview endUpdates];
    }
    else {
        [self.tableview reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    //NSLog(@"rows number %d",currentResultsNumber);
    return currentResultsNumber + 1;

}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == currentResultsNumber) {
        return 64;
    }
    
    Selection *selection = self.searcher.searchResults[indexPath.row];
    
    CGSize constraint = CGSizeMake(CGRectGetWidth(tableView.frame) - 72, 32.0f);
    CGSize constraint1 = CGSizeMake(CGRectGetWidth(tableView.frame) - 24, 64.0f);
    
    
    NSAttributedString *attributedText = [[NSAttributedString alloc]initWithString:selection.sectionTitle attributes:@{
                                                                                                     NSFontAttributeName:[UIFont systemFontOfSize:15.0f]
                                                                                                     }];
    NSAttributedString *attributedText1 = [[NSAttributedString alloc]initWithString:selection.lineContent attributes:@{
                                                                                                     NSFontAttributeName:[UIFont systemFontOfSize:15.0f]
                                                                                                     }];
    
    

    CGRect rect = [attributedText boundingRectWithSize:constraint
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];
    CGRect rect1 = [attributedText1 boundingRectWithSize:constraint1
                                               options:NSStringDrawingUsesLineFragmentOrigin
                                               context:nil];

    PDF_RELEASE(attributedText);
    PDF_RELEASE(attributedText1);
    return rect.size.height + rect1.size.height + 12.0f;
    
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

        
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SearchResultCell"];
    NSMutableAttributedString *attrString;
    
    if (!cell) {
        	cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SearchResultCell"];
#ifdef DEBUG
        static int cellNum = 0;
        NSLog(@"searchResultCell %2d - %@",++cellNum,cell);
#endif
        [self makeCellSubViews:cell];
    }
    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:100];
    UILabel *contentLabel = (UILabel *)[cell.contentView viewWithTag:101];
    UILabel *pageNumLabel = (UILabel *)[cell.contentView viewWithTag:102];
    
    if (indexPath.row ==  currentResultsNumber) {
        titleLabel.text = @"";
        pageNumLabel.text = @"";
        NSString *content;
        if (!self.searcher.running) {
            if(currentResultsNumber == 0)
                if(searching) content = @"已完成搜索，未找到搜索结果";
                else          content = @"";
            else    content = [NSString stringWithFormat:@"已完成搜索，找到%lu个匹配项",(unsigned long)currentResultsNumber];
        }
        else {
            if (!self.searcher.pausing) {
                content = @"正在搜索...";
            }
            else {
                content = [NSString stringWithFormat:@"载入更多...,找到%lu个匹配项",(unsigned long)currentResultsNumber];
            }
        }
    
        attrString = [[NSMutableAttributedString alloc] initWithString:content];
        [attrString addAttribute:NSFontAttributeName
                           value:[UIFont boldSystemFontOfSize:20]
                           range:NSMakeRange(0, [content length])];
        contentLabel.attributedText = attrString;
        PDF_RELEASE(attrString);
        return  cell;
    }
    
    Selection *selection = self.searcher.searchResults[indexPath.row];
    
    if (selection.sectionTitle) {
        titleLabel.text = selection.sectionTitle;
    }
    
    if (selection.lineContent) {	
        attrString = [[NSMutableAttributedString alloc] initWithString:selection.lineContent];
        NSUInteger strLen = [selection.lineContent length];
        NSRange range = NSMakeRange(0, 0);
        
        for (NSUInteger i = 0; i <= selection.indexOfLineContent; i ++) {
            NSRange searchRange = NSMakeRange(range.location + range.length, strLen - range.location - range.length);
            range = [selection.lineContent rangeOfString:self.searcher.keyWord
                                                 options:NSCaseInsensitiveSearch
                                                   range:searchRange];
            if (range.location == NSNotFound) {
                NSLog(@"Error - Only %lu keywords in lineContent,while the number should be at least %d",(unsigned long)i,selection.indexOfLineContent);
                break;
            }
        }
        
        [attrString addAttribute:NSForegroundColorAttributeName
                           value:[UIColor orangeColor]
                           range:range];
        contentLabel.attributedText = attrString;
        PDF_RELEASE(attrString);
    }
    pageNumLabel.text = [NSString
                         stringWithFormat:@"%ld",selection.pageNo];
  
   // NSLog(@"get cell");
    return cell;
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
//    if (indexPath.row == currentResultsNumber) {
//        return;
//    }
//    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:100];
//    UILabel *contentLabel = (UILabel *)[cell.contentView viewWithTag:101];
//    NSLog(@"titleLabel frame is:%f,%f,%f,%f",titleLabel.frame.origin.x,titleLabel.frame.origin.y,titleLabel.frame.size.width,titleLabel.frame.size.height);
//    NSLog(@"contentLabel frame is:%f,%f,%f,%f",contentLabel.frame.origin.x,contentLabel.frame.origin.y,contentLabel.frame.size.width,contentLabel.frame.size.height);
}


-(void)makeCellSubViews:(UITableViewCell *)cell {
    
   // cell.contentView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UILabel * titleLabel = [[UILabel alloc]init];
    [cell.contentView addSubview:titleLabel];
    titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    titleLabel.font =[UIFont systemFontOfSize:15.f];
    titleLabel.textColor = [UIColor blackColor];
    titleLabel.tag = 100;
    PDF_RELEASE(titleLabel);
    
    
    UILabel *contentLabel = [[UILabel alloc]init];
    [cell.contentView addSubview:contentLabel];
    contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
    contentLabel.font =[UIFont systemFontOfSize:15.f];
    contentLabel.textColor = [UIColor blackColor];
    contentLabel.tag = 101;
    contentLabel.numberOfLines = 0;
    PDF_RELEASE(contentLabel);
    
    
    
    UILabel * pageNumLabel = [[UILabel alloc]init];
    [cell.contentView addSubview:pageNumLabel];
    pageNumLabel.translatesAutoresizingMaskIntoConstraints = NO;
    pageNumLabel.font =[UIFont systemFontOfSize:13.f];
    pageNumLabel.textColor = [UIColor lightGrayColor];
    pageNumLabel.tag = 102;
    PDF_RELEASE(pageNumLabel);
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(pageNumLabel,contentLabel,titleLabel);
    
    NSDictionary *metrics = @{@"padding":@(12)};
    
    
    NSArray *constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"H:|-padding-[titleLabel]-[pageNumLabel(<=48)]-padding-|"
                            options:0
                            metrics:metrics
                            views:viewsDictionary];
    
    constraints = [constraints arrayByAddingObjectsFromArray:
                   [NSLayoutConstraint
                    constraintsWithVisualFormat:@"H:|-padding-[contentLabel]-padding-|"
                    options:0
                    metrics:metrics
                    views:viewsDictionary]];
    
    constraints = [constraints arrayByAddingObjectsFromArray:
                   [NSLayoutConstraint
                    constraintsWithVisualFormat:@"V:|-6-[titleLabel(<=32)][contentLabel(<=64)]"
                    options:0
                    metrics:nil
                    views:viewsDictionary]];
    constraints = [constraints arrayByAddingObjectsFromArray:
                   [NSLayoutConstraint
                    constraintsWithVisualFormat:@"V:|-6-[pageNumLabel]"
                    options:0
                    metrics:nil
                    views:viewsDictionary]];
    
    [cell.contentView addConstraints:constraints];
    
    
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    if (indexPath.row == currentResultsNumber) {
        if (self.searcher.running && self.searcher.pausing) {
            [self.searcher moreResults];
        }
    }
    else {
        Selection *selection = self.searcher.searchResults[indexPath.row];
        
        [self.delegate selectSearchResult:selection];
    }
}


#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar1
{
    NSString *searchingText = [searchBar text];
    NSString *searchingScope = @"全文";//[[searchBar scopeButtonTitles] objectAtIndex:[searchBar selectedScopeButtonIndex]];
    searching = YES;
    
    if (isPad) {
        if ([searchingText length]>0) {
            [self setPreferredContentSize:CGSizeMake(VIEW_WIDTH, CELL_HEIGHT*4)];
        }
        else{
            [self setPreferredContentSize:CGSizeMake(VIEW_WIDTH, 0)];
        }
    }
    
    self.searcher.keyWord = searchingText;
    NSLog(@"Searching %@ within %@",searchingText,searchingScope);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    if ([searchingScope isEqualToString:@"本页"]) {
        [self.searcher scanDocumentPage:currentPage];
    }
    else if ([searchingScope isEqualToString:@"全文"]){
        dispatch_async(queue, ^(){
            @try {
                [self.searcher start];
            }
            @catch (NSException *exception) {
                NSLog(@"PDF start searching Error : %@",exception);
            }
            
        });
    }

    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    searching = NO;
    [self.searcher pause];      ///< pause firstly to avoid inserting new selection after reset
    self.searcher.keyWord = @"";
    [self.searcher reset];
    currentResultsNumber = 0;
    [self.tableview reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    searching = NO;
    [self.searcher pause];
    self.searcher.keyWord = @"";
    [self.searcher reset];
    currentResultsNumber = 0;
    [self.tableview reloadData];
}

#pragma mark - Memory Management
- (void)dealloc
{
    PDF_RELEASE(_searcher);
    PDF_RELEASE(searchBar);
    PDF_RELEASE(tableview);
    PDF_SUPER_DEALLOC;
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

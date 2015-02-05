//
//  ReaderSearchController.m
//  Readder
//
//  Created by CharlyZhang on 15/1/22
//
//

#import "ReaderSearchController.h"
#import "ReaderDocument.h"
#import "Searcher.h"
#import "Selection.h"

#define UPDATE_DYNAMIC 1
#define PAGE_PER_THREAD 40          ///< 每个线程处理的页面数

#define SEARCHBAR_HEIGHT    44
#define CELL_HEIGHT         96
#define VIEW_WIDTH          320

@interface ReaderSearchController ()<UITableViewDelegate,UITableViewDataSource,
UISearchBarDelegate,UISearchDisplayDelegate,SearcherDelegate>
{
    ReaderDocument* document;
    NSInteger currentPage;                          ///< 进入时的当前页码
    UITableView *tableview;
    UISearchBar *searchBar;
}

@property(nonatomic, strong) Searcher           *searcher;
@property(nonatomic, strong) UITableView        *tableview;

@end

@implementation ReaderSearchController

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
    }
    return self;
}

#pragma mark - PDFSearchViewController methods

- (void)pauseSearching
{
    [self.searcher pause];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
//    CGFloat width = CGRectGetWidth(self.view.frame);
    searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, VIEW_WIDTH,SEARCHBAR_HEIGHT)];
    [searchBar setPlaceholder:@"输入一个关键词"];
    searchBar.delegate = self;
    searchBar.showsScopeBar= NO;
    searchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"本页",@"全文", nil];
    searchBar.selectedScopeButtonIndex = 1;
    [searchBar sizeToFit];
    [self.view addSubview:searchBar];
    
    tableview = [[UITableView alloc]initWithFrame:CGRectMake(0, SEARCHBAR_HEIGHT,  VIEW_WIDTH, CELL_HEIGHT*4)];
    tableview.estimatedRowHeight = CELL_HEIGHT;
    tableview.delegate = self;
    tableview.dataSource = self;
    [self.view addSubview:tableview];
    
    [self setPreferredContentSize:CGSizeMake(VIEW_WIDTH, SEARCHBAR_HEIGHT)];
//    self.pdfReader.updateSearchResult  = ^(NSArray *results){
//        dispatch_async(dispatch_get_main_queue(), ^{
//            self.searchResults =  results;
//            [self.tableView reloadData];
//        });
//    };
}

- (void)viewWillAppear:(BOOL)animated
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^(){
        [self.searcher resume];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - SearchDelegate methods
- (void)updateSearchResults
{
    [self.tableview insertRowsAtIndexPaths:self.searcher.updateIndexPath withRowAnimation:UITableViewRowAnimationTop];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.searcher.searchResults.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
        [self makeCellSubViews:cell];
    }
    Selection *selection = self.searcher.searchResults[indexPath.row];

    UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:100];
    UILabel *contentLabel = (UILabel *)[cell.contentView viewWithTag:101];
    UILabel *pageNumLabel = (UILabel *)[cell.contentView viewWithTag:102];

    if (selection.sectionTitle) {
        titleLabel.text = selection.sectionTitle;
    }
    if (selection.lineContent) {
            NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc] initWithString:selection.lineContent];
        NSRange range  = [selection.lineContent rangeOfString:self.searcher.keyWord
                                                      options:NSCaseInsensitiveSearch];
        [attrString addAttribute:NSForegroundColorAttributeName
                           value:[UIColor orangeColor]
                           range:range];
        contentLabel.attributedText = attrString;
        PDF_RELEASE(attrString);
    }
    pageNumLabel.text = [NSString
                         stringWithFormat:@"%d",selection.pageNo];
  
    return cell;
}

-(void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath{
    //UILabel *titleLabel = (UILabel *)[cell.contentView viewWithTag:100];
    //UILabel *contentLabel = (UILabel *)[cell.contentView viewWithTag:101];
    //NSLog(@"titleLabel frame is:%f,%f,%f,%f",titleLabel.frame.origin.x,titleLabel.frame.origin.y,titleLabel.frame.size.width,titleLabel.frame.size.height);
    //NSLog(@"contentLabel frame is:%f,%f,%f,%f",contentLabel.frame.origin.x,contentLabel.frame.origin.y,contentLabel.frame.size.width,contentLabel.frame.size.height);
}


-(void)makeCellSubViews:(UITableViewCell *)cell {
    
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
    Selection *selection = self.searcher.searchResults[indexPath.row];
    
    [self.delegate selectSearchResult:selection];
}


#pragma mark - UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar1
{
    NSString *searchingText = [searchBar text];
    NSString *searchingScope = [[searchBar scopeButtonTitles] objectAtIndex:[searchBar selectedScopeButtonIndex]];
    
    if ([searchingText length]>0) {
        [self setPreferredContentSize:CGSizeMake(VIEW_WIDTH, SEARCHBAR_HEIGHT + CELL_HEIGHT*4)];
    }
    else{
        [self setPreferredContentSize:CGSizeMake(VIEW_WIDTH, SEARCHBAR_HEIGHT)];
    }

    
    self.searcher.keyWord = searchingText;
    NSLog(@"Searching %@ within %@",searchingText,searchingScope);
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    if ([searchingScope isEqualToString:@"本页"]) {
        [self.searcher scanDocumentPage:currentPage];
    }
    else if ([searchingScope isEqualToString:@"全文"]){
        dispatch_async(queue, ^(){
            [self.searcher start];
        });
    }
    
    
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.searcher pause];      ///< pause firstly to avoid inserting new selection after reset
    [self.searcher reset];
    [self.tableview reloadData];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    [self.searcher pause];
    [self.searcher reset];
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

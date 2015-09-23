//
//  PDFCatalogViewController.m
//  E-Publishing
//
//  Created by allen on 14-6-23.
//
//

#import "PDFCatalogViewController.h"
#import "PDFCatalogTableViewCell.h"
#import "ReaderDocument.h"
#import "ReaderDocumentOutline.h"
#import "PDFConstants.h"

//#define DEBUG_SHOW_CELL
@interface PDFCatalogViewController ()
{
    NSArray                 *outlinesArray;
    UITableView             *contentView;
    ReaderDocument          *document;                               ///< pdf文档
    NSArray                 *iconImages;                             ///< 目录图标前的图片
}

@end

@implementation PDFCatalogViewController

- (id)initWithReaderDocument:(ReaderDocument*)object configuration:(NSDictionary*)config
{
    if (self = [super init]) {
        document = object;
        iconImages = (NSArray*)[config objectForKey:CATALOG_TITLE_IMAGES_KEY];
        if (!iconImages) {
            iconImages = [NSArray arrayWithObjects:[UIImage imageNamed:@"pdf_catalog_title"],
                                            [UIImage imageNamed:@"pdf_catalog_subtitle"], nil];
        }
        
        outlinesArray = [[NSArray alloc] initWithArray:[ReaderDocumentOutline outlineFromFileURL:document.fileURL password:document.password]];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationController.navigationBarHidden = NO;
    self.title = @"目录";
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(exit:)];
        self.navigationItem.rightBarButtonItem = doneButtonItem;
        PDF_RELEASE(doneButtonItem);
    }
    
    contentView = [[UITableView alloc]initWithFrame:self.view.bounds style:UITableViewStylePlain];
    contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    contentView.delegate = self;
    contentView.dataSource = self;
    [self.view addSubview:contentView];
    PDF_RELEASE(contentView);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [outlinesArray count];
}



- (PDFCatalogTableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CustomCellIdentifier = @"CustomCell";
//    [tableView registerClass:[PDFCatalogTableViewCell class]
//      forCellReuseIdentifier:CustomCellIdentifier];
    PDFCatalogTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CustomCellIdentifier];
    if (cell == nil) {
        cell = PDF_AUTORELEASE([[PDFCatalogTableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"CustomCell" withImages:iconImages]);

#ifdef DEBUG_SHOW_CELL
        static int cellNum = 0;
        NSLog(@"%d - %@",cellNum++, cell);
#endif
        
    }
    
     //NSLog(@"%@",cell);
    
    cell.CataNode = (DocumentOutlineEntry *)[outlinesArray objectAtIndex:indexPath.row];
    
    return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DocumentOutlineEntry *entry =(DocumentOutlineEntry *)[outlinesArray objectAtIndex:indexPath.row];
    NSInteger index = entry.level + 1;
    
    
    
    
//    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:entry.title];
//
//    NSRange range = NSMakeRange(0, attrStr.length);
//    NSDictionary *dic = [entry.title attributesAtIndex:0 effectiveRange:&range];   // 获取该段attributedString的属性字典
//    // 计算文本的大小
//    CGSize textSize = [entry.title boundingRectWithSize:textView.bounds.size // 用于计算文本绘制时占据的矩形块
//                                                  options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading // 文本绘制时的附加选项
//                                               attributes:dic        // 文字的属性
//                                                  context:nil].size; // context上下文。包括一些信息，
    
    
    CGSize constraint = CGSizeMake(CGRectGetWidth(tableView.frame) - 64.0f,60.0f);
    NSAttributedString *attributedText ;
    
    if (index == 1) {
        attributedText = [[NSAttributedString alloc]initWithString:entry.title attributes:@{
                                                                                             NSFontAttributeName:[UIFont systemFontOfSize:15.0f]
                                                                                             }];
    }
    else{
        attributedText = [[NSAttributedString alloc]initWithString:entry.title attributes:@{
                                                                                             NSFontAttributeName:[UIFont systemFontOfSize:13.0f]
                                                                                            }];
    }
    NSLog(@"entry.title is:%@",entry.title);
    NSStringDrawingOptions options =  NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading;
    CGRect rect = [attributedText boundingRectWithSize:constraint
                                               options:options
                                               context:nil];
    
    float height = rect.size.height  + 24.0f;
    NSLog(@"height is:%f",height);
    //return 64.0f;
    return height;
}


#pragma mark tabel view delegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PDFCatalogTableViewCell *cell = (PDFCatalogTableViewCell *)[contentView cellForRowAtIndexPath:indexPath];
   [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self.delegate didSelectCatalogToPage:[(NSNumber*)cell.CataNode.target intValue]];
}

-(void)exit:(id)sender{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{
        
    }];
}


-(void)dealloc
{
    PDF_RELEASE(outlinesArray); outlinesArray = nil;
    PDF_SUPER_DEALLOC;
}

@end

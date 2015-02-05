//
//  Searcher.m
//  E-Publishing
//
//  Created by CharlyZhang on 15/1/28.
//
//

#import "Searcher.h"
#import "CGPDFDocument.h"
#import "ReaderDocument.h"
#import "ReaderDocumentOutline.h"
#import "Scanner.h"

#define PAGE_PER_THREAD     40
//#define USE_MUTIL_THREAD

#define CAN_SEARCH   0x1111         ///< 可以搜索
#define NO_SEARCH    0x0000         ///< 不可搜索

@interface Searcher()
{
    ReaderDocument* document;
    CGPDFDocumentRef pdfDocRef;                     ///< 打开的pdf
    NSInteger pageCount;                            ///< pdf的页码总数
    NSString *keywordLastAllSearched;               ///< 上次全文搜索的关键词
    BOOL running;                                   ///< 是否正在搜索
    bool pausing;                                   ///< 是否暂停
    NSUInteger scanningPage;                        ///< 搜索到的页面
}

@property (nonatomic, retain) NSMutableArray* documentOutlines;                 ///< pdf文档的目录

@property (nonatomic, retain, readwrite) NSMutableArray *searchResults;
@property (nonatomic, retain, readwrite) NSMutableArray *updateIndexPath;       ///< 更新对搜索结果位置
@property (nonatomic, assign, readwrite) BOOL running;
@property (nonatomic, retain)  NSConditionLock *lock;
@end


@implementation Searcher

#pragma mark - Properties
@synthesize running;

- (NSMutableArray*)searchResults
{
    if (!_searchResults) {
        _searchResults = [[NSMutableArray alloc]init];
    }
    return _searchResults;
}

- (NSMutableArray*)updateIndexPath
{
    if (!_updateIndexPath) {
        _updateIndexPath = [[NSMutableArray alloc]init];
    }
    return _updateIndexPath;
}

- (NSMutableArray*)documentOutlines
{
    if (!_documentOutlines) {
        NSArray *originalOutlines =[ReaderDocumentOutline outlineFromFileURL:document.fileURL password:document.password];
        _documentOutlines = [[NSMutableArray alloc] initWithCapacity:[originalOutlines count]];
        
        for (DocumentOutlineEntry* value in originalOutlines) {
            
            DocumentOutlineEntry *entry = [[DocumentOutlineEntry alloc]
                                           initWithTitle:value.title target:value.target level:value.level];
            [_documentOutlines addObject:entry];
            PDF_RELEASE(entry);
        }
        // PDF_RELEASE(originalOutlines);  ///< ARC文件copy出来的对象由该文件
    }
    
    return _documentOutlines;
}

- (NSConditionLock*)lock
{
    if (!_lock) {
        _lock = [[NSConditionLock alloc]initWithCondition:CAN_SEARCH];
    }
    return _lock;
}
#pragma mark - Initialization

- (id)initWithDocument:(ReaderDocument*)object
{
    if(self = [super init]){
        document = object;
        pdfDocRef = CGPDFDocumentCreateUsingUrl((__bridge CFURLRef)document.fileURL,document.password);
        pageCount = CGPDFDocumentGetNumberOfPages(pdfDocRef);
        running = NO;
        pausing = NO;
    }
    
    return self;
}

#pragma mark - Search methods

/* Start scanning a particular document pages */
- (void)scanDocumentPage:(NSInteger)pageNo
{
    Scanner *scanner = [[Scanner alloc] init];
    [self reset];
    running = YES;
    [self scanDocumentPage:pageNo use:scanner];
    running = NO;
    PDF_RELEASE(scanner);
}


/* Start scanning a particular document pages */
- (void)scanDocumentPage:(NSInteger)pageNo use:(Scanner*)scanner
{
    scanner.keyword = self.keyWord;
    
    CGPDFPageRef page = CGPDFDocumentGetPage(pdfDocRef, pageNo);
    
    [scanner scanPage:page];
    
    int selNum = [scanner.selections count];
    NSString *currSectionTitle = [self catalogTitleAtPageNumber:pageNo];

    [self.lock lockWhenCondition:CAN_SEARCH];
//    NSLog(@"begin searching");
    [self.updateIndexPath removeAllObjects];
    /// set current pageNo and sectionTitle to the past unset selections
    for (int i = 0; i < selNum; i++) {
        Selection *sel = [scanner.selections objectAtIndex:i];
        if (sel.pageNo > 0)    continue;
        
        sel.pageNo = pageNo;
        if (currSectionTitle == nil) {
            currSectionTitle =[NSString stringWithFormat:@"第%d页",pageNo];
        }
        sel.sectionTitle = currSectionTitle;
        
        NSIndexPath *path = [NSIndexPath indexPathForRow:self.searchResults.count inSection:0];
        [self.updateIndexPath addObject:path];
        [self.searchResults addObject:sel];
    }
//    NSLog(@"end searching");
//    NSLog(@"searching num :%2d",self.searchResults.count);
    
    if (self.updateIndexPath.count >0) {
        //NSLog(@"update unlock with condition");
        [self.lock unlockWithCondition:NO_SEARCH];
        dispatch_async(dispatch_get_main_queue(), ^(){
            [self.lock lock];
            //NSLog(@"begin update");
            [self.delegate updateSearchResults];
            //NSLog(@"end update");
            [self.lock unlockWithCondition:CAN_SEARCH];
        });
        
    } else {
        //NSLog(@"update unlock");
        [self.lock unlockWithCondition:CAN_SEARCH];
    }
}

/* Start scanning all document pages asynchronizely*/
- (void)scanDocument
{
    NSDate *startTime = [NSDate date];
    
#ifndef USE_MUTIL_THREAD
    Scanner *scanner = [[Scanner alloc]init];
    for (; scanningPage <= pageCount; scanningPage++){
        if(running && !pausing) {
            @autoreleasepool {
              //  NSLog(@"page %2d",scanningPage);
                [self scanDocumentPage:scanningPage use:scanner];
            }
        }
        else break;
    }
    NSDate *endTime = [NSDate date];
    NSLog(@"completed in %f time",[endTime timeIntervalSinceDate:startTime]);
    PDF_RELEASE(scanner);
#else   ///< use mutil-threads tech to search
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    /// before searching
    size_t threadNum = pageCount/PAGE_PER_THREAD;
    if (threadNum*PAGE_PER_THREAD < pageCount) threadNum ++;
    
    /// search pdf coocurrently
    dispatch_apply(threadNum, queue, ^(size_t index){
        //NSLog(@"searching index %zu",index+1);
        [self searchPDFInThread:index forKey:self.keyWord];
    });
    
    /// after searching
    NSDate *endTime = [NSDate date];
    NSLog(@"completed in %f time",[endTime timeIntervalSinceDate:startTime]);
#endif
}

- (void)searchPDFInThread:(size_t)index forKey:(NSString*)keyword
{
    Scanner *scanner = [[Scanner alloc]init];
    
    scanner.keyword = keyword;
   
    for (int i = 0; i < PAGE_PER_THREAD; i ++)
    {
        size_t pageNo = (index*PAGE_PER_THREAD) + i + 1;
        if (pageNo > pageCount) break;      ///< for the last thread
        
        CGPDFPageRef page = CGPDFDocumentGetPage(pdfDocRef, pageNo);
        
        [scanner scanPage:page];
        
        int selNum = [scanner.selections count];
        NSString *currSectionTitle = [self catalogTitleAtPageNumber:pageNo];
        
        /// set current pageNo and sectionTitle to the past unset selections
        for (int j = selNum-1; j >= 0; j--) {
            Selection *sel = [scanner.selections objectAtIndex:j];
            if (sel.pageNo > 0)    break;
            
            sel.pageNo = pageNo;
            if (currSectionTitle == nil) {
                currSectionTitle =[NSString stringWithFormat:@"第%zu页",pageNo];
            }
            sel.sectionTitle = currSectionTitle;
        }
    }
    
    if (scanner.selections.count >0) {
        dispatch_async(dispatch_get_main_queue(), ^(){
            NSUInteger baseIndex;
            for (baseIndex = 0; baseIndex < self.searchResults.count; baseIndex ++) {
                if ([(Selection*)self.searchResults[baseIndex] pageNo] > index*PAGE_PER_THREAD+1) break;
            }
            
            [self.updateIndexPath removeAllObjects];
            for (int i=0; i<scanner.selections.count; i++) {
                [self.searchResults insertObject:[scanner.selections objectAtIndex:i] atIndex:baseIndex+i];
                NSIndexPath *path = [NSIndexPath indexPathForRow:baseIndex+i inSection:0];
                [self.updateIndexPath addObject:path];
            }
            
            [self.delegate updateSearchResults];
        });
    }
    
    PDF_RELEASE(scanner);
}

/// 返回特定页所在的章节标题(找当前页最后一个标题)
- (NSString*)catalogTitleAtPageNumber:(NSInteger)pageNo
{
    DocumentOutlineEntry *current = nil;
    for (DocumentOutlineEntry *item in self.documentOutlines)
    {
        if ([(NSNumber*)item.target integerValue] <= pageNo)
            current = item;
        else
            break;
    }
    return current.title;
}

- (void)start
{
    if([self.keyWord isEqualToString:keywordLastAllSearched]) return;
    
    PDF_RELEASE(keywordLastAllSearched);
    keywordLastAllSearched = PDF_RETAIN(self.keyWord);
   
    [self reset];
    running = YES;
    
    [self scanDocument];
    
    if(!pausing) running = NO;
}

- (void)pause
{
    pausing = YES;
}

- (void)resume
{
    if (!running) return;
    
    self.keyWord = keywordLastAllSearched;
    pausing = NO;
    [self scanDocument];
    if(!pausing) running = NO;
}

- (void)reset
{
    running = NO;
    pausing = NO;
    scanningPage = 1;
    [self.searchResults removeAllObjects];
}

#pragma mark - Memory Management

- (void)dealloc
{
    CGPDFDocumentRelease(pdfDocRef);
    PDF_RELEASE(_documentOutlines);
    PDF_RELEASE(_searchResults);
    PDF_RELEASE(_lock);
    PDF_SUPER_DEALLOC;
}

@end

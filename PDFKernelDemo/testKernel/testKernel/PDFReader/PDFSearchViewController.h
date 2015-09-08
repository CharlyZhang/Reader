//
//  PDFSearchViewController.h
//  E-Publishing
//
//  Created by 李 雷川 on 14/12/26.
//
//  Modified by CharlyZhang on 15/1/22

#import <UIKit/UIKit.h>

@class ReaderDocument;
@class Selection;

@protocol PDFSearchViewControllerDelegate <NSObject>

@required

- (void)selectSearchResult:(Selection*)selection;   ///< 处理选中某条Selection

@end

@interface PDFSearchViewController : UIViewController

@property (nonatomic, assign) id <PDFSearchViewControllerDelegate> delegate;
@property (nonatomic, assign) NSInteger currentPage;                          ///< 进入时的当前页码

- (id)initWithReaderDocument:(ReaderDocument*)object atPage:(NSInteger)pageNo;

- (void)pauseSearching;                             ///< 暂停搜索

@end

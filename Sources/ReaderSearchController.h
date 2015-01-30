//
//  ReaderSearchController.h
//  Readder
//
//  Created by CharlyZhang on 15/1/22

#import <UIKit/UIKit.h>

@class ReaderDocument;
@class Selection;

@protocol ReaderSearchControllerDelegate <NSObject>

@required

- (void)selectSearchResult:(Selection*)selection;   ///< 处理选中某条Selection

@end

@interface ReaderSearchController : UIViewController

@property (nonatomic, assign) id <ReaderSearchControllerDelegate> delegate;

- (id)initWithReaderDocument:(ReaderDocument*)object atPage:(NSInteger)pageNo;

- (void)pauseSearching;                             ///< 暂停搜索
@end

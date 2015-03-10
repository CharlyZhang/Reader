//
//  Searcher.h
//  E-Publishing
//
//  Created by CharlyZhang on 15/1/28.
//
//

#import <Foundation/Foundation.h>

@class ReaderDocument;

@protocol SearcherDelegate <NSObject>

@required
- (void)updateSearchResults;      ///< update the UI when get the new result

@end

@interface Searcher : NSObject

@property (nonatomic, retain, readonly) NSMutableArray *searchResults;
@property (nonatomic, retain, readonly) NSMutableArray *updateIndexPath;     ///< 更新对搜索结果位置
@property (nonatomic, assign) id<SearcherDelegate> delegate;                 ///< required when scanning document asynchronizely
@property (nonatomic, retain) NSString       *keyWord;                       ///< 关键词
@property (atomic, assign, readonly) BOOL running;
@property (atomic, assign, readonly) BOOL pausing;

- (id)initWithDocument:(ReaderDocument*)object;

/* Start scanning all document pages asynchronizely*/
//- (void)scanDocument;

/* Start scanning a particular document pages */
- (void)scanDocumentPage:(NSInteger)pageNo;

/* request more results, return NO when no more */
- (BOOL)moreResults;

/// for scan the whole book
- (void)start;          ///< start searching
- (void)pause;          ///< pause searching
- (void)resume;         ///< resume from pause
- (void)reset;

@end

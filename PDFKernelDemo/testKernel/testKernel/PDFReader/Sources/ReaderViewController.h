//
//	ReaderViewController.h
//	Reader v2.8.0
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

#import <UIKit/UIKit.h>

#import "ReaderDocument.h"
#import "ReaderContentView.h"

@class ReaderViewController;

@protocol PDFControllerDelegate <NSObject>

@required // Delegate protocols

- (void)dismissReaderViewController:(ReaderViewController *)viewController;

- (void)updatePDFCurrentPage:(NSInteger) currentPage;                       ///< 更新当前页处理

- (void)pdfCustomActionControllerWillAppearFor:(NSInteger)index;
- (void)pdfCustomActionControllerDiddissmissFor:(NSInteger)index;

@end

@interface ReaderViewController : UIViewController

@property (nonatomic, weak, readwrite) id <PDFControllerDelegate> delegate;
@property (nonatomic,copy) dispatch_block_t backShelfBlcok;              ///< 返回书架的block
@property (nonatomic, strong) NSString* pdfId;                           ///< pdf书籍在本地id

@property (nonatomic,strong,readonly)UIView* currentView;                ///< 当前的ContentView所包含的theContainerView
@property (nonatomic,strong)ReaderContentView* currentContentView;       ///< 当前的ContentView

@property (nonatomic,strong) ReaderDocument *document;                   ///< pdf文档

@property (nonatomic,readonly)NSInteger currentPage;                     ///< 当前页码

- (instancetype)initWithReaderDocument:(ReaderDocument *)object;
- (instancetype)initWithReaderDocument:(ReaderDocument *)object configuration:(NSDictionary*)config;

- (BOOL)freezeCurrentView;                               ///< 冻结当前视图
- (BOOL)restoreCurrentView;                              ///< 恢复当前视图
- (BOOL)addEndorseView:(UIView*)view needEdit:(BOOL)flag;///< 添加一个批注到当前视图
- (void)removeEndorseView:(BOOL)isEditing;

- (BOOL)addNoteView:(UIView*)view needEdit:(BOOL)flag;   ///< 添加一个便签到当前视图
- (void)removeNoteView:(BOOL)isEditing;

// 添加自定义按钮的弹出控制器
- (BOOL)addActionController:(UIViewController*)controller for:(NSUInteger)customButtonIndex;
- (void)dismissActionController;

- (void)showDocumentPage:(NSInteger)page;

@end

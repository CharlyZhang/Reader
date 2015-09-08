//
//  PDFCatalogViewController.h
//  E-Publishing
//
//  Created by allen on 14-6-23.
//
//

#import <UIKit/UIKit.h>
#import "PDFCatalogTableViewCell.h"

@class ReaderDocument;

@protocol PDFCatalogDelegate <NSObject>

-(void)didSelectCatalogToPage:(NSInteger)pageNumber;

@end

@interface PDFCatalogViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property(nonatomic,assign) id<PDFCatalogDelegate> delegate;

- (id)initWithReaderDocument:(ReaderDocument*)object;

@end



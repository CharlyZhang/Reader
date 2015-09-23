//
//  PDFCatalogTableViewCell.h
//  E-Publishing
//
//  Created by allen on 14-6-23.
//
//

#import <UIKit/UIKit.h>
#import "ReaderDocumentOutline.h"

@interface PDFCatalogTableViewCell : UITableViewCell

@property(nonatomic, retain) DocumentOutlineEntry *CataNode;

@property(nonatomic,retain) UIImageView   *icon;
@property(nonatomic,retain) UILabel      *title;
@property(nonatomic,retain) UIImageView   *subIcon;
@property(nonatomic,retain) UILabel      *subTitle;
@property(nonatomic,retain) UILabel      *pageNumber;

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier withImages:(NSArray*)configImages;
@end

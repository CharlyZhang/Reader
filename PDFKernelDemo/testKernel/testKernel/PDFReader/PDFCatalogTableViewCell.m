//
//  PDFCatalogTableViewCell.m
//  E-Publishing
//
//  Created by allen on 14-6-23.
//
//

#import "PDFCatalogTableViewCell.h"
#import "PDFConstants.h"

@interface PDFCatalogTableViewCell()

@end

@implementation PDFCatalogTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self addSubViews];
        [self constraintSubviews];
    }
    return self;
}

-(void)addSubViews{
    _icon = [[UIImageView alloc]init];
    [self.contentView addSubview:_icon];
    _subIcon = [[UIImageView alloc]init];
    [self.contentView addSubview:_subIcon];
    _title = [[UILabel alloc]init];
    _title.textAlignment = NSTextAlignmentLeft;
    _title.lineBreakMode = NSLineBreakByWordWrapping;
    _title.numberOfLines = 0;
    _title.font = [UIFont systemFontOfSize:15];
    [self.contentView addSubview:_title];
    _subTitle= [[UILabel alloc]init];
    _subTitle.textAlignment = NSTextAlignmentLeft;
    _subTitle.lineBreakMode = NSLineBreakByWordWrapping;
    _subTitle.numberOfLines = 0;
    _subTitle.font = [UIFont systemFontOfSize:13];
    [self.contentView addSubview:_subTitle];
    
    _pageNumber = [[UILabel alloc]init];
    _pageNumber.textAlignment = NSTextAlignmentRight;
    _pageNumber.font = [UIFont systemFontOfSize:11];
    _pageNumber.textColor = [UIColor lightGrayColor];
    [self.contentView addSubview:_pageNumber];

    _icon.image = [UIImage imageNamed:@"PDFKernel.bundle/EPUB_MainTitle_Icon.png"];
    _subIcon.image = [UIImage imageNamed:@"PDFKernel.bundle/EPUB_NextTitle_Icon.png"];

}

-(void)constraintSubviews{

    _icon.translatesAutoresizingMaskIntoConstraints = NO;
    _subIcon.translatesAutoresizingMaskIntoConstraints = NO;
    _pageNumber.translatesAutoresizingMaskIntoConstraints = NO;
    _subTitle.translatesAutoresizingMaskIntoConstraints = NO;
    _title.translatesAutoresizingMaskIntoConstraints = NO;
    
    NSNumber *mainIconLeftPadding = [NSNumber numberWithFloat: 8];
    NSNumber *subIconLeftPadding = [NSNumber numberWithFloat: 20];
    NSNumber *iconWidth = [NSNumber numberWithFloat:_icon.image.size.width];
    NSNumber *subIconWidth = [NSNumber numberWithFloat:_subIcon.image.size.width];
    
    NSDictionary *viewsDictionary = NSDictionaryOfVariableBindings(self.contentView,_pageNumber,_title,_icon,_subIcon,_subTitle);
    NSDictionary *metricsDic = NSDictionaryOfVariableBindings(mainIconLeftPadding,subIconLeftPadding,iconWidth,subIconWidth);

    
    NSArray *constraints = [NSLayoutConstraint
                            constraintsWithVisualFormat:@"H:|-mainIconLeftPadding-[_icon(iconWidth)]"
                            options:0
                            metrics:metricsDic
                            views:viewsDictionary];
    constraints = [constraints arrayByAddingObjectsFromArray:
                   [NSLayoutConstraint
                    constraintsWithVisualFormat:@"H:|-subIconLeftPadding-[_subIcon(subIconWidth)]"
                    options:0
                    metrics:metricsDic
                    views:viewsDictionary]];
    
    constraints = [constraints arrayByAddingObjectsFromArray:
                   [NSLayoutConstraint
                    constraintsWithVisualFormat:@"H:[_pageNumber]-|"
                    options:0
                    metrics:metricsDic
                    views:viewsDictionary]];
    
    
    constraints = [constraints arrayByAddingObjectsFromArray:
                   [NSLayoutConstraint
                    constraintsWithVisualFormat:@"H:[_icon]-[_title]-[_pageNumber]"
                    options:0
                    metrics:metricsDic
                    views:viewsDictionary]];
    
    constraints = [constraints arrayByAddingObjectsFromArray:
                   [NSLayoutConstraint
                    constraintsWithVisualFormat:@"H:[_subIcon]-[_subTitle]-[_pageNumber]"
                    options:0
                    metrics:metricsDic
                    views:viewsDictionary]];
    

    

    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_icon
                                                attribute:NSLayoutAttributeCenterY
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.contentView
                                                attribute:NSLayoutAttributeCenterY
                                               multiplier:1.0
                                                 constant:0]];
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_subIcon
                                                attribute:NSLayoutAttributeCenterY
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.contentView
                                                attribute:NSLayoutAttributeCenterY
                                               multiplier:1.0
                                                 constant:0]];
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_title
                                                attribute:NSLayoutAttributeCenterY
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.contentView
                                                attribute:NSLayoutAttributeCenterY
                                               multiplier:1.0
                                                 constant:0]];
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_pageNumber
                                                attribute:NSLayoutAttributeCenterY
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.contentView
                                                attribute:NSLayoutAttributeCenterY
                                               multiplier:1.0
                                                 constant:0]];
    
    constraints = [constraints arrayByAddingObject:
                   [NSLayoutConstraint constraintWithItem:_subTitle
                                                attribute:NSLayoutAttributeCenterY
                                                relatedBy:NSLayoutRelationEqual
                                                   toItem:self.contentView
                                                attribute:NSLayoutAttributeCenterY
                                               multiplier:1.0
                                                 constant:0]];

    [self.contentView addConstraints:constraints];
}

-(void)setCataNode:(DocumentOutlineEntry *)node
{
    PDF_RELEASE(_CataNode release);
    _CataNode = PDF_RETAIN(node);

    NSInteger index = _CataNode.level + 1;
    _title.text = @"";
    _subTitle.text = @"";

    if (index == 1) {
        _title.text = _CataNode.title;;
        _subIcon.hidden = YES;
        _subTitle.hidden = YES;
        _icon.hidden = NO;
        _title.hidden = NO;
    }
    else{
        _subTitle.text = _CataNode.title;;
        _icon.hidden = YES;
        _title.hidden = YES;
        _subIcon.hidden = NO;
        _subTitle.hidden = NO;
    }
    _pageNumber.text = [NSString stringWithFormat:@"%d", [(NSNumber*)_CataNode.target intValue] ];
}


- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    if (highlighted) {
        self.backgroundColor = [UIColor lightGrayColor];
    }
    else{
        self.backgroundColor = [UIColor whiteColor];
    }
}
-(void)dealloc
{
    if (_CataNode) {
        PDF_RELEASE(_CataNode); _CataNode = nil;
    }
    if (_icon) {
        PDF_RELEASE(_icon); _icon = nil;
    }
    if (_title) {
        PDF_RELEASE(_title); _title = nil;
    }
    if (_subIcon) {
        PDF_RELEASE(_subIcon); _subIcon = nil;
    }
    if (_subTitle) {
        PDF_RELEASE(_subTitle); _subTitle = nil;
    }
    if (_pageNumber) {
        PDF_RELEASE(_pageNumber);  _pageNumber = nil;
    }
    PDF_SUPER_DEALLOC;
}
@end

//
//  PDFViewController.h
//  E-Publishing
//
//  Created by CharlyZhang on 15/1/15.
//
//

#import "ReaderViewController.h"
#import "PDFConstants.h"

@interface PDFViewController : ReaderViewController

+ (UIImage*) pdfCoverWithPath:(NSString*)filePath;

-(id)initWithPath:(NSString *)path withBookID:(NSString*)bookID;

-(id)initWithPath:(NSString *)path withBookID:(NSString*)bookID withPassword:(NSString *)pwd;


/*
 configuration:
 
 @{
 TOOLBAR_BACKGROUND_IMAGE_KEY:   @[UIImage,...]     //< 顶部栏背景图片,    0 for horizonal, 1 for vertical
 TOOLBAR_BACK_BTN_IMAGES_KEY:    @[UIImage,...]     //< 返回按钮图片,     0 for Normal, 1 for Highlighted
 TOOLBAR_FLAG_BTN_IMAGES_KEY:    @[UIImage,...]     //< 书签按钮图片,     0 for Normal, 1 for Highlighted
 TOOLBAR_CATALOG_BTN_IMAGES_KEY: @[UIImage,...]     //< 目录按钮图片,     0 for Normal, 1 for Highlighted
 TOOLBAR_THUMB_BTN_IMAGES_KEY:   @[UIImage,...]     //< 缩略图按钮图片,    0 for Normal, 1 for Highlighted
 TOOLBAR_SEARCH_BTN_IMAGES_KEY:  @[UIImage,...]     //< 搜索按钮图片,     0 for Normal, 1 for Highlighted
 CATALOG_TITLE_IMAGES_KEY:       @[UIImage,...]     //< 目录标题前图标,    0 for main title, 1 for subtitle
 BOOKMARK_FLAG_IMAGE_KEY:        UIImage            //< 书签的图片
 
 TOOLBAR_CUSTOM_BTNS_KEY:    @[                     //< 自定义按钮数组
 @{
 TOOLBAR_CUSTOM_BTN_IMAGES_KEY:    @[UIImage,..]        //< 自定义按钮图片,     0 for Normal, 1 for Highlighted
 },
 ...
 ]
 }
 */
-(id)initWithPath:(NSString *)path withBookID:(NSString*)bookID withPassword:(NSString *)pwd configuration:(NSDictionary*) config;

-(UIImage*) imageForCurrentPage;

@end

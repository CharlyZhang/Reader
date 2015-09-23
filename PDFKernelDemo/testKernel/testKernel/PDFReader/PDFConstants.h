//
//  PDFConstants.h
//  E-Publishing
//
//  Created by CharlyZhang on 15/1/28.
//
//

#ifndef E_Publishing_PDFConstants_h
#define E_Publishing_PDFConstants_h

#define TOOLBAR_BACKGROUND_IMAGE_KEY    @"toolbarBackgroundImageKey"      //< 背景图片
#define TOOLBAR_BACK_BTN_IMAGES_KEY     @"toolbarBackBtnImagesKey"        //< 返回按钮图片
#define TOOLBAR_FLAG_BTN_IMAGES_KEY     @"toolbarFlagBtnImagesKey"        //< 书签按钮图片
#define TOOLBAR_CATALOG_BTN_IMAGES_KEY  @"toolbarCatalogBtnImagesKey"     //< 目录按钮图片
#define TOOLBAR_THUMB_BTN_IMAGES_KEY    @"toolbarThumbBtnImagesKey"       //< 缩略图按钮图片
#define TOOLBAR_SEARCH_BTN_IMAGES_KEY   @"toolbarSearchBtnImagesKey"      //< 搜索按钮图片
#define TOOLBAR_CUSTOM_BTNS_KEY         @"toolbarCustomBtnsKey"           //< 自定义按钮
#define TOOLBAR_CUSTOM_BTN_IMAGES_KEY   @"toolbarCustomBtnImagesKey"      //< 自定义按钮图片
#define CATALOG_TITLE_IMAGES_KEY        @"catalogTitleImagesKey"          //< 目录中标题前图片
#define BOOKMARK_FLAG_IMAGE_KEY         @"bookmarkFlagImageKey"           //< 书签图片

#define isPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

#if __has_feature(objc_arc)

#define PDF_AUTORELEASE(expression) expression

#define PDF_RELEASE(expression)

#define PDF_RETAIN(expression)  expression

#define PDF_SUPER_DEALLOC

#else

#define PDF_AUTORELEASE(expression) [expression autorelease]

#define PDF_RELEASE(expression) [expression release]

#define PDF_RETAIN(expression) [expression retain]

#define PDF_SUPER_DEALLOC      [super dealloc]

#endif

#endif

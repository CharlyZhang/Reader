//
//  PDFConstants.h
//  E-Publishing
//
//  Created by CharlyZhang on 15/1/28.
//
//

#ifndef E_Publishing_PDFConstants_h
#define E_Publishing_PDFConstants_h


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

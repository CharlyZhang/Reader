//
//  PDFViewController.h
//  E-Publishing
//
//  Created by CharlyZhang on 15/1/15.
//
//

#import "ReaderViewController.h"

@interface PDFViewController : ReaderViewController

+ (UIImage*) pdfCoverWithPath:(NSString*)filePath;

-(id)initWithPath:(NSString *)path with:(NSString*)bookID;

-(id)initWithPath:(NSString *)path withBookID:(NSString*)bookID withPassword:(NSString *)pwd;

-(UIImage*) imageForCurrentPage;

@end

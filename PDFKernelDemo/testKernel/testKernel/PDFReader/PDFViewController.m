//
//  PDFViewController.m
//  E-Publishing
//
//  Created by CharlyZhang on 15/1/15.
//
//

#import "PDFViewController.h"

@interface PDFViewController ()
{
}

@end

@implementation PDFViewController
#pragma mark - Properties


#pragma mark - Initialization


-(id)initWithPath:(NSString *)path withBookID:(NSString*)bookID withPassword:(NSString *)pwd{
    assert(path != nil); // Path to first PDF file
    
    ReaderDocument *document = [ReaderDocument withDocumentFilePath:path password:pwd];
    
    if (document != nil) // Must have a valid ReaderDocument object in order to proceed with things
    {
        self = [super initWithReaderDocument:document];
        
        self.pdfId = bookID;
    }
    else // Log an error so that we know that something went wrong
    {
        NSLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:'%@'] failed.", __FUNCTION__, path, pwd);
        self = nil;
    }
    
    return self;
}

- (id)initWithPath:(NSString *)path withBookID:(NSString *)bookID
{
    return [self initWithPath:path withBookID:bookID withPassword:nil];
}


-(id)initWithPath:(NSString *)path withBookID:(NSString*)bookID withPassword:(NSString *)pwd configuration:(NSDictionary*) config
{
    assert(path != nil); // Path to first PDF file
    
    ReaderDocument *document = [ReaderDocument withDocumentFilePath:path password:pwd];
    
    if (document != nil) // Must have a valid ReaderDocument object in order to proceed with things
    {
        self = [super initWithReaderDocument:document configuration:config];
        
        self.pdfId = bookID;
    }
    else // Log an error so that we know that something went wrong
    {
        NSLog(@"%s [ReaderDocument withDocumentFilePath:'%@' password:'%@'] failed.", __FUNCTION__, path, nil);
    }
    
    return self;
    
}

#pragma mark - PDFViewController methods

-(UIImage*) imageForCurrentPage
{
    UIImage *image;
    
    UIGraphicsBeginImageContextWithOptions(self.currentView.bounds.size,YES,0.0f);
    [self.currentView.layer renderInContext:UIGraphicsGetCurrentContext()];
    image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}

#pragma mark - Class methods

+ (UIImage*) pdfCoverWithPath:(NSString*)filePath
{
    NSAssert(filePath != nil, @"文件路径不能为空");
    if (filePath == nil) return nil;    //检查文件是否存在
    
    
    //创建PDF document
    NSURL *pdfURL = [NSURL fileURLWithPath:filePath];
    CGPDFDocumentRef pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
    
    CGPDFPageRef pageRef = CGPDFDocumentGetPage(pdfDocument, 1);
    CGRect pageRect = CGPDFPageGetBoxRect(pageRef, kCGPDFCropBox);
    UIGraphicsBeginImageContext(pageRect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, CGRectGetMinX(pageRect),CGRectGetMaxY(pageRect));
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, -(pageRect.origin.x), -(pageRect.origin.y));
    CGContextDrawPDFPage(context, pageRef);
    
    
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGPDFDocumentRelease(pdfDocument);
    
    return finalImage;
}

@end

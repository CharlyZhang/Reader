#import <Foundation/Foundation.h>
#import "StringDetector.h"
#import "FontCollection.h"
#import "XObjectCollection.h"
#import "RenderingState.h"
#import "Selection.h"
#import "RenderingStateStack.h"

@interface Scanner : NSObject <StringDetectorDelegate> {
    NSURL *documentURL;
    NSString *keyword;
    CGPDFDocumentRef pdfDocument;
    CGPDFOperatorTableRef operatorTable;
    StringDetector *stringDetector;
    FontCollection *fontCollection;
    XObjectCollection *xobjectCollection;
    RenderingStateStack *renderingStateStack;
    Selection *currentSelection;
    NSMutableArray *selections;
    NSMutableString *content;
    
    CGPDFContentStreamRef pageContentStream;        // refer to the content stream of present scanner;
}

/* Initialize with a file path */
- (id)initWithContentsOfFile:(NSString *)path;

/* Initialize with a PDF document */
- (id)initWithDocument:(CGPDFDocumentRef)document;

/* Initialize with a rendering state */
- (id)initWithRenderState:(RenderingState*)state;

/* Start scanning (synchronous) */
- (void)scanDocumentPage:(NSUInteger)pageNumber;

/* Start scanning a particular page */
- (void)scanPage:(CGPDFPageRef)page;

@property (nonatomic, retain) NSMutableArray *selections;
@property (nonatomic, retain) RenderingStateStack *renderingStateStack;
@property (nonatomic, retain) FontCollection *fontCollection;
@property (nonatomic, retain) XObjectCollection *xobjectCollection;
@property (nonatomic, retain) StringDetector *stringDetector;
@property (nonatomic, retain) NSString *keyword;
@property (nonatomic, retain) NSMutableString *content;
@property (nonatomic) CGPDFContentStreamRef pageContentStream;
@property (nonatomic, assign) CGFloat lastTyOfCTM;                          /// 上次展示文本时CTM的ty值
@property (nonatomic, assign) CGFloat lastTyOfTextMatrix;                   /// 上次展示文本时TextMatrix的ty值
@end

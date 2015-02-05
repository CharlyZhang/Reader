#import "Scanner.h"
#import "Util.h"

#define DELTA 1e-6
#define SPACE_WIDTH_ADJUST_FACTOR   0.8     ///< 空格宽度调整系数（有些文档的显示空格比设定空格窄）
//#define SHOW_OPERATE_DATA
//#define SHOW_CONTENT_STREAM_OF_PAGE

#pragma mark

@interface Scanner ()

#pragma mark - Text showing

// Text-showing operators
void Tj(CGPDFScannerRef scanner, void *info);
void quot(CGPDFScannerRef scanner, void *info);
void doubleQuot(CGPDFScannerRef scanner, void *info);
void TJ(CGPDFScannerRef scanner, void *info);

#pragma mark Text positioning

// Text-positioning operators
void Td(CGPDFScannerRef scanner, void *info);
void TD(CGPDFScannerRef scanner, void *info);
void Tm(CGPDFScannerRef scanner, void *info);
void TStar(CGPDFScannerRef scanner, void *info);

#pragma mark Text state

// Text state operators
void BT(CGPDFScannerRef scanner, void *info);
void ET(CGPDFScannerRef scanner, void *info);
void Tc(CGPDFScannerRef scanner, void *info);
void Tw(CGPDFScannerRef scanner, void *info);
void Tz(CGPDFScannerRef scanner, void *info);
void TL(CGPDFScannerRef scanner, void *info);
void Tf(CGPDFScannerRef scanner, void *info);
void Ts(CGPDFScannerRef scanner, void *info);

#pragma mark Graphics state

// Special graphics state operators
void q(CGPDFScannerRef scanner, void *info);
void Q(CGPDFScannerRef scanner, void *info);
void cm(CGPDFScannerRef scanner, void *info);

@property (nonatomic, retain) Selection *currentSelection;
@property (nonatomic, readonly) RenderingState *currentRenderingState;
@property (nonatomic, readonly) Font *currentFont;
@property (nonatomic, readonly) CGPDFDocumentRef pdfDocument;
@property (nonatomic, copy) NSURL *documentURL;

#pragma mark XObject drawing operators

/* Draw XObject */
void Do(CGPDFScannerRef scanner, void *info);

/* Returts the operator callbacks table for scanning page stream */
@property (nonatomic, readonly) CGPDFOperatorTableRef operatorTable;

@end

#pragma mark

@implementation Scanner


#pragma mark - Properties

- (NSMutableString*)content
{
    if (!content) {
        content = [[NSMutableString alloc] init];
    }
    
    return content;
}

#pragma mark - Initialization

- (id)initWithDocument:(CGPDFDocumentRef)document
{
    if ((self = [super init]))
    {
        pdfDocument = CGPDFDocumentRetain(document);
    }
    return self;
}

- (id)initWithContentsOfFile:(NSString *)path
{
    if ((self = [super init]))
    {
        self.documentURL = [NSURL fileURLWithPath:path];
    }
    return self;
}

/* Initialize with a rendering state , used when created to scan a content stream */
- (id)initWithRenderState:(RenderingState*)state
{
    if ((self = [super init]))
    {
        renderingStateStack = [[RenderingStateStack alloc] initWithState:state];
    }
    return self;
}

#pragma mark Scanner state accessors

- (RenderingState *)currentRenderingState
{
    return [self.renderingStateStack topRenderingState];
}

- (Font *)currentFont
{
    return self.currentRenderingState.font;
}

- (CGPDFDocumentRef)pdfDocument
{
    if (!pdfDocument)
    {
        pdfDocument = CGPDFDocumentCreateWithURL((CFURLRef)self.documentURL);
    }
    return pdfDocument;
}

/* The operator table used for scanning PDF pages */
- (CGPDFOperatorTableRef)operatorTable
{
    if (operatorTable)
    {
        return operatorTable;
    }
    
    operatorTable = CGPDFOperatorTableCreate();
    
    // Text-showing operators
    CGPDFOperatorTableSetCallback(operatorTable, "Tj", Tj);
    CGPDFOperatorTableSetCallback(operatorTable, "\'", quot);
    CGPDFOperatorTableSetCallback(operatorTable, "\"", doubleQuot);
    CGPDFOperatorTableSetCallback(operatorTable, "TJ", TJ);
    
    // Text-positioning operators
    CGPDFOperatorTableSetCallback(operatorTable, "Tm", Tm);
    CGPDFOperatorTableSetCallback(operatorTable, "Td", Td);
    CGPDFOperatorTableSetCallback(operatorTable, "TD", TD);
    CGPDFOperatorTableSetCallback(operatorTable, "T*", TStar);
    
    // Text state operators
    CGPDFOperatorTableSetCallback(operatorTable, "Tw", Tw);
    CGPDFOperatorTableSetCallback(operatorTable, "Tc", Tc);
    CGPDFOperatorTableSetCallback(operatorTable, "TL", TL);
    CGPDFOperatorTableSetCallback(operatorTable, "Tz", Tz);
    CGPDFOperatorTableSetCallback(operatorTable, "Ts", Ts);
    CGPDFOperatorTableSetCallback(operatorTable, "Tf", Tf);
    
    // Graphics state operators
    CGPDFOperatorTableSetCallback(operatorTable, "cm", cm);
    CGPDFOperatorTableSetCallback(operatorTable, "q", q);
    CGPDFOperatorTableSetCallback(operatorTable, "Q", Q);
    
    CGPDFOperatorTableSetCallback(operatorTable, "BT", BT);
    CGPDFOperatorTableSetCallback(operatorTable, "ET", ET);
    
    // XObject drawing operators
    CGPDFOperatorTableSetCallback(operatorTable, "Do", Do);
    
    return operatorTable;
}

/* Create a font dictionary given a PDF page */
- (FontCollection *)fontCollectionWithPage:(CGPDFPageRef)page
{
    CGPDFDictionaryRef dict = CGPDFPageGetDictionary(page);
    if (!dict)
    {
#ifdef SHOW_FONT_INFO
        NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing");
#endif
        return nil;
    }
    
    return [self fontCollectionWithDict:dict];
}

/* Create a font dictionary given a dictionary */
- (FontCollection *)fontCollectionWithDict:(CGPDFDictionaryRef)dict
{
#ifdef DEBUG
    //// show all document stream at certain page
    // [Util printDocument:pdfDocument atPageNo:0];
    
    
    //// show all the items in page dictionary
    //[Util printDictionary:dict];
#endif
    CGPDFDictionaryRef resources;
    if (!CGPDFDictionaryGetDictionary(dict, "Resources", &resources))
    {
#ifdef SHOW_FONT_INFO
        NSLog(@"Scanner: fontCollectionWithPage: page dictionary missing Resources dictionary");
#endif
        return nil;
    }
    CGPDFDictionaryRef fonts;
    if (!CGPDFDictionaryGetDictionary(resources, "Font", &fonts)) return nil;
    
#ifdef DEBUG
    //// show all the items in fonts dictionary
    //[Util printDictionary:fonts];
#endif
    FontCollection *collection = [[FontCollection alloc] initWithFontDictionary:fonts];
    return [collection autorelease];
}

/* Create a xobject dictionary given a PDF page */
- (XObjectCollection *)xobjectCollectionWithPage:(CGPDFPageRef)page
{
    CGPDFDictionaryRef dict = CGPDFPageGetDictionary(page);
    if (!dict)
    {
#ifdef SHOW_FONT_INFO
        NSLog(@"Scanner: xobjectCollectionWithPage: page dictionary missing");
#endif
        return nil;
    }
    
    return [self xobjectCollectionWithDict:dict];
}

/* Create a xobject dictionary given a dictionary */
- (XObjectCollection *)xobjectCollectionWithDict:(CGPDFDictionaryRef)dict
{
    CGPDFDictionaryRef resources;
    if (!CGPDFDictionaryGetDictionary(dict, "Resources", &resources))
    {
#ifdef SHOW_FONT_INFO
        NSLog(@"Scanner: xobjectCollectionWithPage: page dictionary missing Resources dictionary");
#endif
        return nil;
    }
    
    CGPDFDictionaryRef xobjects;
    if (!CGPDFDictionaryGetDictionary(resources, "XObject", &xobjects)) return nil;
    
    XObjectCollection *collection = [[XObjectCollection alloc] initWithXObjectDictionary:xobjects];
    return [collection autorelease];
}

/* Scan the given page of the current document */
- (void)scanDocumentPage:(NSUInteger)pageNumber
{
    CGPDFPageRef page = CGPDFDocumentGetPage(self.pdfDocument, pageNumber);
    [self scanPage:page];
}

#pragma mark Start scanning

- (void)scanPage:(CGPDFPageRef)page
{
#ifdef SHOW_CONTENT_STREAM_OF_PAGE
    // show the content stream of this page
    CGPDFContentStreamRef stream = CGPDFContentStreamCreateWithPage(page);
    CFArrayRef streamArr = CGPDFContentStreamGetStreams(stream);
    
    CFIndex num = CFArrayGetCount(streamArr);
    for (CFIndex i=0; i<num; i++) {
        CGPDFStreamRef s = (CGPDFStreamRef)CFArrayGetValueAtIndex(streamArr, i);
        NSString *str = [Util getStringFromStream:s];
        NSLog(@"content stream %ld:%@",i,str);
    }
    CGPDFContentStreamRelease(stream);
#endif
    
    // Return immediately if no keyword set
    if (!keyword) return;
    
    // save the content stream
    CGPDFContentStreamRelease(pageContentStream);
    pageContentStream = CGPDFContentStreamCreateWithPage(page);
    
    [self.stringDetector reset];
    [content setString:@""];
    
    self.stringDetector.keyword = self.keyword;
    
    // Initialize font collection (per page)
    self.fontCollection = [self fontCollectionWithPage:page];
    
    // Initialize xobject collection
    self.xobjectCollection = [self xobjectCollectionWithPage:page];
    
    CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithPage(page);
    CGPDFScannerRef scanner = CGPDFScannerCreate(contentStream, self.operatorTable, self);
    CGPDFScannerScan(scanner);
    CGPDFScannerRelease(scanner); scanner = nil;
    CGPDFContentStreamRelease(contentStream); contentStream = nil;
}

/* Start scanning a particular self-contained stream */
- (void)scanStream:(CGPDFStreamRef)stream
{
    Scanner *streamScanner = [[Scanner alloc]initWithRenderState:[self.renderingStateStack topRenderingState]];
    
    // copy the keyword
    streamScanner.keyword = keyword;
    
    [streamScanner.stringDetector reset];
    streamScanner.stringDetector.keyword = streamScanner.keyword;
    
    // create the dictionary
    CGPDFDictionaryRef dict = CGPDFStreamGetDictionary(stream);
    
    // create the associated resources
    CGPDFDictionaryRef resources;
    if (!CGPDFDictionaryGetDictionary(dict, "Resources", &resources))
        resources = nil;
    
    // create the content stream
    CGPDFContentStreamRef contentStream = CGPDFContentStreamCreateWithStream(stream, resources, pageContentStream);
    // save the new content stream
    streamScanner.pageContentStream = contentStream;
    
    // Initialize font collection (per page)
    streamScanner.fontCollection = [streamScanner fontCollectionWithDict:dict];
    
    // Initialize xobject collection
    streamScanner.xobjectCollection = [streamScanner xobjectCollectionWithDict:dict];
    
    CGPDFScannerRef newScanner = CGPDFScannerCreate(contentStream, [streamScanner operatorTable], streamScanner);
    CGPDFScannerScan(newScanner);
    CGPDFScannerRelease(newScanner); newScanner = nil;
    CGPDFContentStreamRelease(contentStream); contentStream = nil;
    
    // save the xobjects selections
    for (Selection *s in streamScanner.selections)
    {
        [self.selections addObject:s];
    }
    
    [streamScanner release];
    
}

#pragma mark StringDetectorDelegate

- (void)detector:(StringDetector *)detector didScanCharacter:(unichar)character
{
    RenderingState *state = [self currentRenderingState];
    CGFloat width = [self.currentFont widthOfCharacter:character withFontSize:state.fontSize];
    width /= 1000;
    width += state.characterSpacing;
    if (character == 32)
    {
        width += state.wordSpacing;
    }
    [state translateTextPosition:CGSizeMake(width, 0)];
}

- (void)detector:(StringDetector *)detector didStartMatchingString:(NSString *)string
{
    Selection *sel = [[Selection alloc] initWithStartState:self.currentRenderingState];
    self.currentSelection = sel;
    [sel release];
}

- (void)detector:(StringDetector *)detector foundString:(NSString *)needle
{
    RenderingState *state = [[self renderingStateStack] topRenderingState];
    [self.currentSelection finalizeWithState:state];
    
    if (self.currentSelection)
    {
        [self.selections addObject:self.currentSelection];
        self.currentSelection = nil;
    }
}

#pragma mark Line Content

- (void)didScanOneLine
{
    int selNum = [self.selections count];
    
    /// set current line content to the past unset selections
    for (int i = selNum-1; i >= 0; i--) {
        Selection *sel = [self.selections objectAtIndex:i];
        if (sel.lineContent)    break;
        
        sel.lineContent = [NSString stringWithString:content];
    }
#ifdef DEBUG
    NSLog(@"line content:%@",content);
#endif
    [self.stringDetector reset];        ///< to fix the bug "dectected the keyword occupying lines, but can't render correctly"
    [content setString:@""];
}

/// to determine have scaned new line
- (void)haveScanNewLine
{
    /// calculate the height difference in User Space
    RenderingState *state = [self currentRenderingState];
    
    /// new line when CTM is changed
    if(fabsf(state.ctm.ty-self.lastTyOfCTM)/state.ctm.d >= DELTA)
        [self didScanOneLine];
    self.lastTyOfCTM = state.ctm.ty;
    
    /// new line when Tm is changed over Font Height
    CGFloat dy = fabsf(state.textMatrix.ty-self.lastTyOfTextMatrix)/state.textMatrix.d;
    CGFloat h = [state convertToUserSpace:[state.font maxY] - [state.font minY] ];
    if( dy >= h)
        [self didScanOneLine];
    self.lastTyOfTextMatrix = state.textMatrix.ty;
}

#pragma mark - Scanner callbacks

void BT(CGPDFScannerRef scanner, void *info)
{
    [[(Scanner *)info currentRenderingState] setTextMatrix:CGAffineTransformIdentity replaceLineMatrix:YES];
}

void ET(CGPDFScannerRef scanner, void *info)
{
    [(Scanner *)info didScanOneLine];
}

/* Pops the requested number of values, and returns the number of values popped */
// !!!: Make sure this is correct, then use it
int popIntegers(CGPDFScannerRef scanner, CGPDFInteger *buffer, size_t length)
{
    bzero(buffer, length);
    CGPDFInteger value;
    int i = 0;
    while (i < length)
    {
        if (!CGPDFScannerPopInteger(scanner, &value)) break;
        buffer[i] = value;
        i++;
    }
    return i;
}

#pragma mark Text showing operators

void didScanSpace(float value, Scanner *scanner)
{
    float width = [scanner.currentRenderingState convertToUserSpace:value];
    [scanner.currentRenderingState translateTextPosition:CGSizeMake(-width, 0)];
    if (abs(value) >= [scanner.currentRenderingState.font widthOfSpace] * SPACE_WIDTH_ADJUST_FACTOR)
    {
        [scanner.stringDetector reset];
        //NSLog(@"didScanSpace and reset %f",value);
        [scanner.content appendString:@" "];
    }
}

/* Called any time the scanner scans a string */
void didScanString(CGPDFStringRef pdfString, Scanner *scanner)
{
    NSString *string = [[scanner stringDetector] appendPDFString:pdfString withFont:[scanner currentFont]];
    
#ifdef SHOW_OPERATE_DATA
    NSLog(@"%@",string);
#endif
    
    [[scanner content] appendString:string];
}

/* Show a string */
void Tj(CGPDFScannerRef scanner, void *info)
{
#ifdef SHOW_OPERATE_DATA
    NSLog(@"Tj");
#endif
    CGPDFStringRef pdfString = nil;
    if (!CGPDFScannerPopString(scanner, &pdfString)) return;
    didScanString(pdfString, info);
}

/* Equivalent to operator sequence [T*, Tj] */
void quot(CGPDFScannerRef scanner, void *info)
{
    TStar(scanner, info);
    Tj(scanner, info);
}

/* Equivalent to the operator sequence [Tw, Tc, '] */
void doubleQuot(CGPDFScannerRef scanner, void *info)
{
    Tw(scanner, info);
    Tc(scanner, info);
    quot(scanner, info);
}

/* Array of strings and spacings */
void TJ(CGPDFScannerRef scanner, void *info)
{
#ifdef SHOW_OPERATE_DATA
    NSLog(@"TJ");
#endif
    CGPDFArrayRef array = nil;
    CGPDFScannerPopArray(scanner, &array);
    size_t count = CGPDFArrayGetCount(array);
    for (int i = 0; i < count; i++)
    {
        CGPDFObjectRef object = nil;
        CGPDFArrayGetObject(array, i, &object);
        CGPDFObjectType type = CGPDFObjectGetType(object);
        switch (type)
        {
            case kCGPDFObjectTypeString:
            {
                CGPDFStringRef pdfString;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeString, &pdfString))
                {
                    didScanString(pdfString, info);
#ifdef DEBUG
                    //                    Scanner *scanner = (Scanner*)info;
                    //                    NSString *string = [[scanner stringDetector] appendPDFString:pdfString withFont:[scanner currentFont]];
                    //                    NSLog(@" - %@",string);
#endif
                }
                break;
            }
            case kCGPDFObjectTypeReal:
            {
                CGPDFReal tx;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeReal, &tx))
                {
                    didScanSpace(tx, info);
                }
                break;
            }
            case kCGPDFObjectTypeInteger:
            {
                CGPDFInteger tx;
                if (CGPDFObjectGetValue(object, kCGPDFObjectTypeInteger, &tx))
                {
                    didScanSpace(tx, info);
                }
                break;
            }
            default:
#ifdef SHOW_FONT_INFO
                NSLog(@"Scanner: TJ: Unsupported type: %d", type);
#endif
                break;
        }
    }
}

#pragma mark Text positioning operators

/* Move to start of next line */
void Td(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal tx = 0, ty = 0;
    CGPDFScannerPopNumber(scanner, &ty);
    CGPDFScannerPopNumber(scanner, &tx);
    
#ifdef SHOW_OPERATE_DATA
    NSLog(@"Td (%f,%f)",tx,ty);
#endif
    
    [[(Scanner *)info currentRenderingState] newLineWithLeading:-ty indent:tx save:NO];
    
    [(Scanner *)info haveScanNewLine];
}

/* Move to start of next line, and set leading */
void TD(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal tx, ty;
    if (!CGPDFScannerPopNumber(scanner, &ty)) return;
    if (!CGPDFScannerPopNumber(scanner, &tx)) return;
	   
#ifdef SHOW_OPERATE_DATA
    NSLog(@"TD (%f,%f)",tx,ty);
#endif
    
    [[(Scanner *)info currentRenderingState] newLineWithLeading:-ty indent:tx save:YES];
    
    [(Scanner *)info haveScanNewLine];
}

/* Set line and text matrixes */
void Tm(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal a, b, c, d, tx, ty;
    if (!CGPDFScannerPopNumber(scanner, &ty)) return;
    if (!CGPDFScannerPopNumber(scanner, &tx)) return;
    if (!CGPDFScannerPopNumber(scanner, &d)) return;
    if (!CGPDFScannerPopNumber(scanner, &c)) return;
    if (!CGPDFScannerPopNumber(scanner, &b)) return;
    if (!CGPDFScannerPopNumber(scanner, &a)) return;
    CGAffineTransform t = CGAffineTransformMake(a, b, c, d, tx, ty);
#ifdef SHOW_OPERATE_DATA
    NSLog(@"Tm (%f,%f,%f,%f,%f,%f)",a, b, c, d, tx, ty);
#endif
    [[(Scanner *)info currentRenderingState] setTextMatrix:t replaceLineMatrix:YES];
    
    [(Scanner *)info haveScanNewLine];
}

/* Go to start of new line, using stored text leading */
void TStar(CGPDFScannerRef scanner, void *info)
{
    [[(Scanner *)info currentRenderingState] newLine];
    
    [(Scanner *)info haveScanNewLine];
}

#pragma mark Text State operators

/* Set character spacing */
void Tc(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal charSpace;
    if (!CGPDFScannerPopNumber(scanner, &charSpace)) return;
#ifdef SHOW_OPERATE_DATA
    NSLog(@"Tc (%f)",charSpace);
#endif
    [[(Scanner *)info currentRenderingState] setCharacterSpacing:charSpace];
}

/* Set word spacing */
void Tw(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal wordSpace;
    if (!CGPDFScannerPopNumber(scanner, &wordSpace)) return;
    
#ifdef SHOW_OPERATE_DATA
    NSLog(@"Tw (%f)",wordSpace);
#endif
    
    [[(Scanner *)info currentRenderingState] setWordSpacing:wordSpace];
}

/* Set horizontal scale factor */
void Tz(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal hScale;
    if (!CGPDFScannerPopNumber(scanner, &hScale)) return;
    
#ifdef SHOW_OPERATE_DATA
    NSLog(@"Tz (%f)",hScale);
#endif
    
    [[(Scanner *)info currentRenderingState] setHorizontalScaling:hScale];
}

/* Set text leading */
void TL(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal leading;
    if (!CGPDFScannerPopNumber(scanner, &leading)) return;
    
#ifdef SHOW_OPERATE_DATA
    NSLog(@"TL (%f)",leading);
#endif
    
    [[(Scanner *)info currentRenderingState] setLeadning:leading];
}

/* Font and font size */
void Tf(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal fontSize;
    const char *fontName;
    if (!CGPDFScannerPopNumber(scanner, &fontSize)) return;
    if (!CGPDFScannerPopName(scanner, &fontName)) return;
    
#ifdef SHOW_OPERATE_DATA
    NSLog(@"Tf (%f,%s)",fontSize,fontName);
#endif
    
    RenderingState *state = [(Scanner *)info currentRenderingState];
    Font *font = [[(Scanner *)info fontCollection] fontNamed:[NSString stringWithUTF8String:fontName]];
    [state setFont:font];
    [state setFontSize:fontSize];
}

/* Set text rise */
void Ts(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal rise;
    if (!CGPDFScannerPopNumber(scanner, &rise)) return;
    
#ifdef SHOW_OPERATE_DATA
    NSLog(@"Ts (%f)",rise);
#endif
    
    [[(Scanner *)info currentRenderingState] setTextRise:rise];
}


#pragma mark Graphics state operators

/* Push a copy of current rendering state */
void q(CGPDFScannerRef scanner, void *info)
{
    RenderingStateStack *stack = [(Scanner *)info renderingStateStack];
    RenderingState *state = [[(Scanner *)info currentRenderingState] copy];
    [stack pushRenderingState:state];
    [state release];
}

/* Pop current rendering state */
void Q(CGPDFScannerRef scanner, void *info)
{
    [[(Scanner *)info renderingStateStack] popRenderingState];
}

/* Update CTM */
void cm(CGPDFScannerRef scanner, void *info)
{
    CGPDFReal a, b, c, d, tx, ty;
    if (!CGPDFScannerPopNumber(scanner, &ty)) return;
    if (!CGPDFScannerPopNumber(scanner, &tx)) return;
    if (!CGPDFScannerPopNumber(scanner, &d)) return;
    if (!CGPDFScannerPopNumber(scanner, &c)) return;
    if (!CGPDFScannerPopNumber(scanner, &b)) return;
    if (!CGPDFScannerPopNumber(scanner, &a)) return;
    
#ifdef SHOW_OPERATE_DATA
    NSLog(@"cm (%f,%f,%f,%f,%f,%f)",a, b, c, d, tx, ty);
#endif
    
    RenderingState *state = [(Scanner *)info currentRenderingState];
    CGAffineTransform t = CGAffineTransformMake(a, b, c, d, tx, ty);
    state.ctm = CGAffineTransformConcat(state.ctm, t);
    
    [(Scanner *)info haveScanNewLine];
}

#pragma mark XObject drawing operators

/* Draw XObject */
void Do(CGPDFScannerRef scanner, void *info)
{
    const char *xobjectName;
    
    if (!CGPDFScannerPopName(scanner, &xobjectName)) return;
    
#ifdef SHOW_OPERATE_DATA
    NSLog(@"Do (%s)",xobjectName);
#endif
    
    Scanner *scn = (Scanner*)info;
    XObject *xobject = [[scn xobjectCollection] xobjectNamed: [NSString stringWithUTF8String:xobjectName]];
    if (xobject == nil) return;
    
    [scn scanStream:xobject.stream];
}

#pragma mark -
#pragma mark Memory management

- (RenderingStateStack *)renderingStateStack
{
    if (!renderingStateStack)
    {
        renderingStateStack = [[RenderingStateStack alloc] init];
    }
    return renderingStateStack;
}

- (StringDetector *)stringDetector
{
    if (!stringDetector)
    {
        stringDetector = [[StringDetector alloc] initWithKeyword:self.keyword];
        stringDetector.delegate = self;
    }
    return stringDetector;
}

- (NSMutableArray *)selections
{
    if (!selections)
    {
        selections = [[NSMutableArray alloc] init];
    }
    return selections;
}

- (void)dealloc
{
    CGPDFOperatorTableRelease(operatorTable);
    [currentSelection release];
    [fontCollection release];
    [xobjectCollection release];
    [renderingStateStack release];
    [keyword release]; keyword = nil;
    [stringDetector release];
    [documentURL release]; documentURL = nil;
    CGPDFContentStreamRelease(pageContentStream); pageContentStream = nil;
    CGPDFDocumentRelease(pdfDocument); pdfDocument = nil;
    [selections release];
    [content release];
    [super dealloc];
}

@synthesize documentURL, keyword, stringDetector, fontCollection, xobjectCollection, renderingStateStack, currentSelection, selections /* rawTextContent */, pageContentStream, content;
@end

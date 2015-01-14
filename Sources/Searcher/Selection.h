#import <Foundation/Foundation.h>

@class RenderingState;

@interface Selection : NSObject<NSCopying> {
	RenderingState *initialState;
    NSString        *lineContent;          ///< 所在行的内容
    int             pageNo;                ///< 所在页的页码
    NSString        *sectionTitle;         ///< 所在章节名称
	CGAffineTransform transform;
	CGRect frame;
}

/* Initalize with rendering state (starting marker) */
- (id)initWithStartState:(RenderingState *)state;

/* Finalize the selection (ending marker) */
- (void)finalizeWithState:(RenderingState *)state;

/* The frame with zero origin covering the selection */
@property (nonatomic) CGRect frame;

/* The transformation needed to position the selection */
@property (nonatomic) CGAffineTransform transform;

@property (nonatomic, retain) NSString *lineContent;

@property (nonatomic, retain) NSString *sectionTitle;

@property (nonatomic, assign) int pageNo;

@end

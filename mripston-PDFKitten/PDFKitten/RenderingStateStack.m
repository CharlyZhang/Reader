#import "RenderingStateStack.h"
#import "RenderingState.h"

@implementation RenderingStateStack

- (id)init
{
    RenderingState *rootRenderingState = [[RenderingState alloc] init];
	
    if ((self = [self initWithState:rootRenderingState]))
	{
		stack = [[NSMutableArray alloc] init];
		
		[self pushRenderingState:rootRenderingState];
		
	}
    
    [rootRenderingState release];
    
	return self;
}

/* Init with a rendering state */
- (id)initWithState:(RenderingState*)state
{
    if ((self = [super init]))
    {
        stack = [[NSMutableArray alloc] init];
        [self pushRenderingState:state];
    }
    
    return self;
}

/* The rendering state currently on top of the stack */
- (RenderingState *)topRenderingState
{
	return [stack lastObject];
}

/* Push a rendering state to the stack */
- (void)pushRenderingState:(RenderingState *)state
{
	[stack addObject:state];
}

/* Pops the top rendering state off the stack */
- (RenderingState *)popRenderingState
{
	RenderingState *state = [stack lastObject];
	[[stack retain] autorelease];
	[stack removeLastObject];
	return state;
}


#pragma mark - Memory Management

- (void)dealloc
{
	[stack release];
	[super dealloc];
}

@end

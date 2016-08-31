#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

extern NSValue *rangeValue(unsigned int from, unsigned int to);

@interface Operator : NSObject
+ (Operator *)operatorWithStart:(NSString *)start end:(NSString *)end handler:(SEL)handler;
@property (retain) NSString *start;
@property (retain) NSString *end;
@property SEL handler;
@end

/// define CharacterRangeMapping
typedef enum CharacterRangeMappingType{
    MAPPING_TYPE_N_1,           ///< range to one value
    MAPPING_TYPE_N_N            ///< range to range value
} CharacterRangeMappingType;

@interface CharacterRangeMapping : NSObject
{
    CharacterRangeMappingType type;
    NSRange                   range;
    NSMutableArray*           values;
    BOOL                      completed;         ///< false when values length is shorter than the range in case MAPPING_TYPE_N_N
}

@property (nonatomic, readonly)CharacterRangeMappingType type;

- (id)initWithType:(CharacterRangeMappingType)t forRange:(NSRange)r;

- (void)addValue:(NSNumber*)value;
- (void)finishAdd;                          ///for MAPPING_TYPE_N_N

- (unichar)valueForCID:(unichar)cid;

@end

@interface CMap : NSObject {
	NSMutableArray *offsets;
    NSMutableDictionary *chars;
	NSMutableDictionary *context;
	NSString *currentEndToken;

	/* CMap ranges */
	NSMutableArray *codeSpaceRanges;
	
	/* Character mappings */
	NSMutableDictionary *characterMappings;
	
	/* Character range mappings */
	NSMutableDictionary *characterRangeMappings;
}

/* Initialize with PDF stream containing a CMap */
- (id)initWithPDFStream:(CGPDFStreamRef)stream;

/* Initialize with a string representation of a CMap */
- (id)initWithString:(NSString *)string;

/* Unicode mapping for character ID */
- (unichar)unicodeCharacter:(unichar)cid;

@property (nonatomic, retain) NSMutableArray *codeSpaceRanges;
@property (nonatomic, retain) NSMutableDictionary *characterMappings;
@property (nonatomic, retain) NSMutableDictionary *characterRangeMappings;

@end

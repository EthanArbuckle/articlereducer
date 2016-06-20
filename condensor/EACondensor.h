//
//  EACondensor.h
//  condensor
//
//  Created by Ethan Arbuckle on 6/14/16.
//  Copyright © 2016 Ethan Arbuckle. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EACondensor : NSObject

@property (nonatomic, strong) NSString *originalString;
@property (nonatomic, strong) NSString *finalString;

@property (nonatomic, strong) NSMutableArray *scoredSentences;

@property (nonatomic) CGFloat averageThreshold;
@property (nonatomic) CGFloat averageScore;
@property (nonatomic) CGFloat reducementPercent; //0-100

@property (nonatomic) BOOL hasPerformedCondensing;
@property (nonatomic) NSUInteger sentenceCount;

- (id)initWithText:(NSString *)originalString;
- (void)performCondensing;

- (NSString *)condensedString;

@end

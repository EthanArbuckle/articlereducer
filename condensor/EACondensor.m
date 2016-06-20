//
//  EACondensor.m
//  condensor
//
//  Created by Ethan Arbuckle on 6/14/16.
//  Copyright © 2016 Ethan Arbuckle. All rights reserved.
//

#import "EACondensor.h"

@implementation EACondensor

- (id)initWithText:(NSString *)originalString {
    
    if ((self = [super init])) {
        
        _hasPerformedCondensing = NO;
        _originalString = originalString;
        
        _averageThreshold = 1.4;
    }
    
    return self;
}

- (void)performCondensing {
    
    if (_hasPerformedCondensing && [_finalString length] > 0) {
        
        return;
    }
    
    //rid of formatting stuff
    NSArray *replaceFormattingMarks = @[@"\n", @"\t"];
    for (NSString *formatMark in replaceFormattingMarks) {
        
        _originalString = [_originalString stringByReplacingOccurrencesOfString:formatMark withString:@""];
    }
    
    //split article up into sentences
    NSMutableArray *seperatedSentences = [[NSMutableArray alloc] init];
                                          
    NSArray *sentenceEndings = @[@".", @"!", @"?"];
    
    NSUInteger contentLength = [_originalString length];
    NSUInteger currentIndex = 0;
    NSUInteger sentenceLength = 0;
    
    while (currentIndex < contentLength) {
        
        NSRange currentCharRange = NSMakeRange(currentIndex++, 1);
        NSString *currentChar = [_originalString substringWithRange:currentCharRange];
        
        sentenceLength++;
        
        for (NSString *endingCandidate in sentenceEndings) {
            
            if ([currentChar isEqualToString:endingCandidate]) {
                
                NSString *sentenceCandidate = [_originalString substringWithRange:NSMakeRange(currentIndex - sentenceLength, sentenceLength)];
                
                //check for a integer 2 indexes forward
                if ([_originalString length] > currentCharRange.location + 2) {
                    
                    if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location + 2, 1)] intValue] > 0) {
                        
                        continue;
                    }
                }
                
                //check for comma 1 index forward
                if ([_originalString length] > currentCharRange.location + 1) {
                    
                    if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location + 1, 1)] isEqualToString:@","]) {
                        
                        continue;
                    }
                }
                
                //check for predefined prefixes that include periods
                NSArray *falsePositives = @[@"Mr", @"Mrs", @"Ms", @"Gov", @"Jr", @"Inc", @"Ph", @"St", @"Rd"];
                NSUInteger exceptionIndex = 0;
                BOOL foundException = NO;
                while (exceptionIndex < [falsePositives count]) {
                    
                    if ((currentCharRange.location - [falsePositives[exceptionIndex] length]) > 0) {
                        
                        if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location - [falsePositives[exceptionIndex]  length], [falsePositives[exceptionIndex]  length])] isEqualToString:falsePositives[exceptionIndex] ]) {
                            
                            foundException = YES;
                        }
                    }
                    
                    exceptionIndex++;
                }
                
                if (foundException) {
                    
                    continue;
                }
                
                //check if period is after a letter standing alone, ie. Ethan A. Arbuckle
                if ([_originalString length] > currentCharRange.location + 1 && currentCharRange.location - 2 > 0) {
                    
                    if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location + 1, 1)] isEqualToString:@" "] && [[_originalString substringWithRange:NSMakeRange(currentCharRange.location - 2, 1)] isEqualToString:@" "]) {
                        
                        continue;
                    }
                }
                
                //check if char 2 indexes forward is a period, ie U.S.
                if ([_originalString length] > currentCharRange.location + 2) {
                    
                    if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location + 2, 1)] isEqualToString:@"."]) {
                        
                        continue;
                    }
                }
                
                //check if char 2 indexes backwards is a period, ie m.p.h
                if ([_originalString length] > currentCharRange.location - 2) {
                    
                    if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location - 2, 1)] isEqualToString:@"."]) {
                        
                        continue;
                    }
                }
                
                
                //if loop hasnt broken sentence is valid, add to array
                [seperatedSentences addObject:sentenceCandidate];
                
                //reset length for next sentence
                sentenceLength = 0;

            }
        }
        
    }
    
    _scoredSentences = [[NSMutableArray alloc] initWithCapacity:[seperatedSentences count]];
    _averageScore = 0;
    for (NSString *sentence in seperatedSentences) {
        
        CGFloat sentenceScore = [sentence length];
        
        for (NSString *singleWord in [sentence componentsSeparatedByString:@" "]) {
            
            sentenceScore += [singleWord length];
        }
        
        
        [_scoredSentences insertObject:@(sentenceScore) atIndex:[seperatedSentences indexOfObject:sentence]];
        
        _averageScore += sentenceScore;
    }
    
    _averageScore /= [_scoredSentences count];
    
    //construct new string
    NSMutableString *mutableNewString = [[NSMutableString alloc] init];
    for (id sentenceScore in _scoredSentences) {
        
        if ([sentenceScore floatValue] > (_averageScore * _averageThreshold)) {
            
            [mutableNewString appendString:[NSString stringWithFormat:@"%@ ", seperatedSentences[[_scoredSentences indexOfObject:sentenceScore]]]];
        }
    }
    
    _finalString = mutableNewString;
    
}

- (NSString *)condensedString {
    
    if (!_hasPerformedCondensing) {
        
        [self performCondensing];
    }
    
    return _finalString;
}

@end

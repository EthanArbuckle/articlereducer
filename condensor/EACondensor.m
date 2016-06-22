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
        
        //sentence score has to be > average * average threshold to pass
        _averageThreshold = 1.4;
    }
    
    return self;
}

- (void)performCondensing {
    
    if (_hasPerformedCondensing && [_finalString length] > 0) {
        
        return;
    }
    
    //rid of formatting stuff
    NSArray *replaceFormattingMarks = @[@"\n", @"\t", @"\r"];
    for (NSString *formatMark in replaceFormattingMarks) {
        
        _originalString = [_originalString stringByReplacingOccurrencesOfString:formatMark withString:@""];
    }
    
    //split article up into sentences
    NSMutableArray *seperatedSentences = [[NSMutableArray alloc] init];
    
    //these are possible sentence stoppers
    NSArray *sentenceEndings = @[@".", @"!", @"?"];
    
    NSUInteger contentLength = [_originalString length];
    NSUInteger currentIndex = 0;
    NSUInteger sentenceLength = 0;
    
    //iterate every character
    while (currentIndex < contentLength) {
        
        NSRange currentCharRange = NSMakeRange(currentIndex++, 1);
        
        //current character
        NSString *currentChar = [_originalString substringWithRange:currentCharRange];
        
        //keep track of the length of this sentence
        sentenceLength++;
        
        //conpare character to sentence stoppers
        for (NSString *endingCandidate in sentenceEndings) {
            
            if ([currentChar isEqualToString:endingCandidate]) {
                
                //get sentence candidate contents
                NSString *sentenceCandidate = [_originalString substringWithRange:NSMakeRange(currentIndex - sentenceLength, sentenceLength)];
                
                //check for a integer 2 indexes forward (Aug 21. xxx)
                if ([_originalString length] > currentCharRange.location + 2) {
                    
                    if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location + 2, 1)] intValue] > 0) {
                        
                        continue;
                    }
                }
                
                //check for comma 1 index forward (Miss., xxx)
                if ([_originalString length] > currentCharRange.location + 1) {
                    
                    if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location + 1, 1)] isEqualToString:@","]) {
                        
                        continue;
                    }
                }
                
                //check for predefined prefixes that include periods (Ms. Smith xxx)
                NSArray *falsePositives = @[@"Mr", @"Mrs", @"Ms", @"Gov", @"Jr", @"Inc", @"Ph", @"St", @"Rd"];
                NSUInteger exceptionIndex = 0;
                BOOL foundException = NO;
                while (exceptionIndex < [falsePositives count]) {
                    
                    //make sure a character exists at (current index - prefix length)
                    if ((currentCharRange.location - [falsePositives[exceptionIndex] length]) > 0) {
                        
                        //compare it to the preix
                        if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location - [falsePositives[exceptionIndex]  length], [falsePositives[exceptionIndex]  length])] isEqualToString:falsePositives[exceptionIndex] ]) {
                            
                            foundException = YES;
                        }
                    }
                    
                    exceptionIndex++;
                }
                
                //break if prefix found
                if (foundException) {
                    
                    continue;
                }
                
                //check if period is after a letter standing alone, (John B. Smith)
                if ([_originalString length] > currentCharRange.location + 1 && currentCharRange.location - 2 > 0) {
                    
                    //check for a space at one before current index, and 2 after current index
                    if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location + 1, 1)] isEqualToString:@" "] && [[_originalString substringWithRange:NSMakeRange(currentCharRange.location - 2, 1)] isEqualToString:@" "]) {
                        
                        continue;
                    }
                }
                
                //check if char 2 indexes forward is a period, (U.S.)
                if ([_originalString length] > currentCharRange.location + 2) {
                    
                    if ([[_originalString substringWithRange:NSMakeRange(currentCharRange.location + 2, 1)] isEqualToString:@"."]) {
                        
                        continue;
                    }
                }
                
                //check if char 2 indexes backwards is a period, ie (m.p.h)
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
    
    //keep track of average score of sentences
    _averageScore = 0;
    
    //iterate sentences twice, first time to count occurances of words, second time to score the sentences
    NSMutableDictionary *wordOccurances = [[NSMutableDictionary alloc] init];
    for (NSString *sentence in seperatedSentences) {
        
        for (NSString *singleWord in [sentence componentsSeparatedByString:@" "]) {
            
            //check if word exists already
            if ([wordOccurances valueForKey:singleWord]) {
                
                //if it does increment the usage count
                [wordOccurances setValue:@([[wordOccurances valueForKey:singleWord] integerValue] + 1) forKey:singleWord];
            }
            else {
                
                //start the usage count at 1
                [wordOccurances setValue:@(1) forKey:singleWord];
            }
        }
        
    }
    
    for (NSString *sentence in seperatedSentences) {
        
        //scores will be the sum of al individual word lengths + overall sentence length
        CGFloat sentenceScore = [sentence length];
        
        //iterate words
        for (NSString *singleWord in [sentence componentsSeparatedByString:@" "]) {
            
            //weight word length lightly
            sentenceScore += [singleWord length] / 2;
            
            //increment score by word occurance count
            sentenceScore += [[wordOccurances valueForKey:singleWord] integerValue];
        }
        
        [_scoredSentences insertObject:@(sentenceScore) atIndex:[seperatedSentences indexOfObject:sentence]];
        
        _averageScore += sentenceScore;
    }
    
    //divide score sum by sentence count
    _averageScore /= [_scoredSentences count];
    
    //construct new string
    NSMutableString *mutableNewString = [[NSMutableString alloc] init];
    for (id sentenceScore in _scoredSentences) {
        
        if ([sentenceScore floatValue] > (_averageScore * _averageThreshold)) {
            
            //strip out any prepended spaces as there tends to be doubled sometimes
            NSString *sentence = seperatedSentences[[_scoredSentences indexOfObject:sentenceScore]];
            while ([[sentence substringWithRange:NSMakeRange(0, 1)] isEqualToString:@" "]) {
                
                //remove it
                sentence = [sentence stringByReplacingCharactersInRange: NSMakeRange(0, 1) withString:@""];
            }
            
            //add the single spade
            [mutableNewString appendString:[NSString stringWithFormat:@"%@ ", sentence]];
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

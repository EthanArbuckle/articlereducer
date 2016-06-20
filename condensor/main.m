//
//  main.m
//  condensor
//
//  Created by Ethan Arbuckle on 6/10/16.
//  Copyright © 2016 Ethan Arbuckle. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EACondensor.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {

        NSString *articleContent = [NSString stringWithContentsOfFile:@"/Users/ethanarbuckle/Desktop/news" encoding:NSUTF8StringEncoding error:nil];
        
        EACondensor *cond = [[EACondensor alloc] initWithText:articleContent];
        [cond setAverageThreshold:1.4f];
        NSLog(@"\n\n%@\n\n", [cond condensedString]);
        
    }
    
    return 0;
}
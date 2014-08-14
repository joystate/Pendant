//
//  WordHandler.m
//  RFduinoExample
//
//  Created by Nadia Yudina on 8/5/14.
//  Copyright (c) 2014 Nadia. All rights reserved.
//

#import "WordHandler.h"

@implementation WordHandler

+ (NSArray *)arrayOfWordsFromFile: (NSString *)fileName
{
    NSString *filepath = [[NSBundle mainBundle] pathForResource:fileName ofType:@"txt"];
    NSError *error;
    NSString *fileContents = [NSString stringWithContentsOfFile:filepath
                                                       encoding:NSUTF8StringEncoding error:&error];
    
    if (error)
        NSLog(@"Error reading file: %@", error.localizedDescription);

    NSArray *wordArray = [fileContents componentsSeparatedByString:@"\n"];
    return wordArray;
}

@end

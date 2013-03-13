//
//  DeallocManager.m
//  TheDeallocer
//
//  Created by Josh Klobe on 3/12/13.
//  Copyright (c) 2013 Josh Klobe. All rights reserved.
//

#import "DeallocManager.h"

@implementation DeallocManager

static NSString *nonatomicRetainPropertyString = @"@property (nonatomic, retain)";
static NSString *inheritenceString = @"@interface";

+(void)handleFilePairingObject:(FilePairingObject *)theFilePairingObject
{
    NSArray *releasableProperties = [DeallocManager getReleasableProperties:theFilePairingObject];
    NSLog(@"releasableProperties: %@", releasableProperties);
    
}

+(NSArray *)getReleasableProperties:(FilePairingObject *)theFilePairingObject
{

    NSMutableArray *retAr = [NSMutableArray arrayWithCapacity:0];
    
    NSString* content = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", theFilePairingObject.rootPath, theFilePairingObject.headerFilename]
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    
    NSArray *linesArray = [content componentsSeparatedByString:@"\n"];
    for (int i = 0; i < [linesArray count]; i++)
    {
        NSString *line = [linesArray objectAtIndex:i];
    
        if ([line rangeOfString:nonatomicRetainPropertyString].length > 0)
        {
            line = [line stringByReplacingOccurrencesOfString:nonatomicRetainPropertyString withString:@""];
            line = [line stringByReplacingOccurrencesOfString:@";" withString:@""];
            NSArray *split = [line componentsSeparatedByString:@" *"];
            NSString *className = [split objectAtIndex:0];
            NSString *instanceName = [split objectAtIndex:1];

            NSDictionary *retDict = [NSDictionary dictionaryWithObject:instanceName forKey:className];
            [retAr addObject:retDict];             
        }

    }
        
    return retAr;
}
@end


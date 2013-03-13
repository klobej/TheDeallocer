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
static NSString *deallocMethodDefinitionString = @"-(void) dealloc";


+(void)handleFilePairingObject:(FilePairingObject *)theFilePairingObject
{
    NSArray *releasableProperties = [DeallocManager getReleasableProperties:theFilePairingObject];
    
    NSString *implementationString = [DeallocManager implementationStringByDeallocingWithFilePairingObject:theFilePairingObject withReleasableProperties:releasableProperties];

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
            
            if ([split count] <= 1)
                split = [line componentsSeparatedByString:@" "];
            
            if ([split count] > 1)
            {
                
                NSString *className = [split objectAtIndex:0];
                NSString *instanceName = [split objectAtIndex:1];
                
                NSDictionary *retDict = [NSDictionary dictionaryWithObject:instanceName forKey:className];
                [retAr addObject:retDict];
            }
        }
    }
    
    
    
    return retAr;
}

+(NSString *)implementationStringByDeallocingWithFilePairingObject:(FilePairingObject *)theFilePairingObject withReleasableProperties:(NSArray *)releasablePropertiesArray
{
    NSString* content = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", theFilePairingObject.rootPath, theFilePairingObject.implementationFilename]
                                                  encoding:NSUTF8StringEncoding
                                                     error:NULL];
    
    if ([content rangeOfString:@"dealloc"].length != 0)
    {
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"-*(void)*dealloc*" options:0 error:NULL];
        NSTextCheckingResult *match = [regex firstMatchInString:content options:0 range:NSMakeRange(0, [content length])];
        
        NSString *deallocMethodStartString = [content substringFromIndex:match.range.location-9];
        
        int closeHitchCockIndex = (int)[deallocMethodStartString rangeOfString:@"\n}"].location + 1;
        
        NSString *deallocMethod = [content substringWithRange:NSMakeRange([content rangeOfString:deallocMethodStartString].location, closeHitchCockIndex + 1)];
     
        content = [content stringByReplacingOccurrencesOfString:deallocMethod withString:@""];
    }
    
    
    NSMutableString *deallocMethodString = [NSMutableString stringWithCapacity:0];
    [deallocMethodString appendString:[NSString stringWithFormat:@"%@\n", deallocMethodDefinitionString]];
    [deallocMethodString appendString:@"{\n"];
    
    for (int i = 0; i < [releasablePropertiesArray count]; i++)
    {
        NSDictionary *dictObject = [releasablePropertiesArray objectAtIndex:i];
        NSString *key = [[dictObject allKeys] objectAtIndex:0];
        NSString *value = [dictObject objectForKey:key];
        [deallocMethodString appendString:[NSString stringWithFormat:@"\t[self.%@ release];\n", value]];
    }
    
    [deallocMethodString appendString:@"\n\t[super dealloc];\n"];
    [deallocMethodString appendString:@"}\n"];
    [deallocMethodString appendString:@"@end\n"];
    
    content = [content stringByReplacingOccurrencesOfString:@"@end" withString:deallocMethodString];
    
    NSLog(@"releasablePropertiesArray: %@", releasablePropertiesArray);
    NSLog(@"deallocMethodString: %@", deallocMethodString);
    NSLog(@" ");
    
    
    return content;
}
@end


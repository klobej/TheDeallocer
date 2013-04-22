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
    
    if (releasableProperties > 0)
    {
        NSString *implementationString = [DeallocManager implementationStringByDeallocingWithFilePairingObject:theFilePairingObject withReleasableProperties:releasableProperties];
        theFilePairingObject.implementationReplacement = implementationString;
    
        [DeallocManager replaceImplementationWithFilePairingObject:theFilePairingObject];
    }
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
  
        
        if ([line rangeOfString:nonatomicRetainPropertyString].length > 0 && [line rangeOfString:@"//"].length == 0)
        {
            
            line = [line stringByReplacingOccurrencesOfString:nonatomicRetainPropertyString withString:@""];
            line = [line stringByReplacingOccurrencesOfString:@";" withString:@""];
            NSArray *split = [line componentsSeparatedByString:@" *"];
            
            NSString *className = nil;
            NSString *instanceName = nil;

            if ([split count] <= 1)
                split = [line componentsSeparatedByString:@" "];

            if ([split count] == 2 )
            {

                
                className = [split objectAtIndex:0];
                instanceName = [split objectAtIndex:1];

            }
            else if ([split count] == 3)
            {
                className = [split objectAtIndex:1];
                instanceName = [split objectAtIndex:2];
                
            }

            if (className != nil && instanceName != nil)
            {
                className = [className stringByReplacingOccurrencesOfString:@"IBOutlet" withString:@""];
                className = [className stringByReplacingOccurrencesOfString:@" " withString:@""];
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
    
    if ([content rangeOfString:@"dealloc" options:NSBackwardsSearch].length != 0)
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
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\tNSLog(@\"deallocing: %@\", self);", @"%@"]];
    for (int i = 0; i < [releasablePropertiesArray count]; i++)
    {
        NSDictionary *dictObject = [releasablePropertiesArray objectAtIndex:i];
        
        NSString *key = [NSString stringWithFormat:@"%@", [[dictObject allKeys] objectAtIndex:0]];
        NSString *value = [dictObject objectForKey:key];
        
        Class objectClass = NSClassFromString(key);
        
        if ([objectClass isSubclassOfClass:[UIView class]] && ![objectClass isSubclassOfClass:[UIButton class]])
        {  
            
            [deallocMethodString appendString:[NSString stringWithFormat:@"\n\tif ([self.%@ superview] != nil)\n\t", value]];
            [deallocMethodString appendString:[NSString stringWithFormat:@"\t[self.%@ removeFromSuperview];\n", value]];
            [deallocMethodString appendString:[NSString stringWithFormat:@"\t[self.%@ release];\n", value]];
            [deallocMethodString appendString:[NSString stringWithFormat:@"\tself.%@ = nil;\n", value]];
            [deallocMethodString appendString:@"\n"];
        }
        else
        {
            [deallocMethodString appendString:[NSString stringWithFormat:@"\t[self.%@ release];\n", value]];
            
        }
       
    
    }
    
    [deallocMethodString appendString:@"\n\t[super dealloc];\n"];
    [deallocMethodString appendString:@"}\n"];

        
    NSRange endRange = [content rangeOfString:@"@end" options:NSBackwardsSearch];
    NSUInteger index = endRange.location;
    if (endRange.location > 0 && endRange.location < 100000)
    {
        NSMutableString* mstr2 = [content mutableCopy];
        [mstr2 insertString:deallocMethodString atIndex:index];
        content = mstr2;
    }
    
    return content;
}

+(void)replaceImplementationWithFilePairingObject:(FilePairingObject *)theFilePairingObject
{
    NSLog(@"replacing: %@", [NSString stringWithFormat:@"%@%@", theFilePairingObject.rootPath, theFilePairingObject.implementationFilename]);
    
    NSString *myString = theFilePairingObject.implementationReplacement;
    NSError *err = nil;
    [myString writeToFile:[NSString stringWithFormat:@"%@%@", theFilePairingObject.rootPath, theFilePairingObject.implementationFilename] atomically:YES encoding:NSUTF8StringEncoding error:&err];
    if(err != nil) {
        NSLog(@"error: %@", err);
    }
    else
        NSLog(@"success!");
    
    NSLog(@" ");
    NSLog(@" ");
    
        
}

@end


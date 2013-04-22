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
    NSArray *excludableClasses = [NSArray arrayWithObjects:@"APIHandler", nil];
    if (releasableProperties > 0)
    {
        NSString *implementationString = [DeallocManager implementationStringByDeallocingWithFilePairingObject:theFilePairingObject withReleasableProperties:releasableProperties withExcludableClassesArray:excludableClasses];
        theFilePairingObject.implementationReplacement = implementationString;
        
        [DeallocManager replaceImplementationWithFilePairingObject:theFilePairingObject];
    }
}

+(NSArray *)getReleasableProperties:(FilePairingObject *)theFilePairingObject
{
    
    NSMutableArray *retAr = [NSMutableArray arrayWithCapacity:0];
    
    NSArray *filenamesAr = [NSArray arrayWithObjects:theFilePairingObject.headerFilename, theFilePairingObject.implementationFilename, nil];
    
    
    for (int j = 0; j < [filenamesAr count]; j++)
    {
        NSString *lookupString = [filenamesAr objectAtIndex:j];
        
        NSLog(@"lookupString: %@", lookupString);
        
        
        NSString* content = [NSString stringWithContentsOfFile:[NSString stringWithFormat:@"%@/%@", theFilePairingObject.rootPath, lookupString]
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
                    
                    NSLog(@"className: %@, instanceName: %@", className, instanceName);
                    
                    NSDictionary *retDict = [NSDictionary dictionaryWithObject:instanceName forKey:className];
                    [retAr addObject:retDict];
                }
                
                
            }
        }
    }
    
    NSLog(@" ");
    NSLog(@" ");    
    
    return retAr;
}

+(NSString *)implementationStringByDeallocingWithFilePairingObject:(FilePairingObject *)theFilePairingObject withReleasableProperties:(NSArray *)releasablePropertiesArray withExcludableClassesArray:(NSArray *)excludeArray
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
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\tswitch (DEALLOC_LOG_LEVEL) {"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\t\tcase DEALLOC_LOG_LEVEL_ALL:"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\t\t\tNSLog(@\"deallocing: %@\", self);", @"%@"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\t\tbreak;\n"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\t\tcase DEALLOC_LOG_LEVEL_EXCLUDE:"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\t\t\tNSLog(@\"\");\n"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\t\t\tBOOL proceed = YES;\n"]];
    for (int i = 0; i < [excludeArray count]; i++)
    {
        [deallocMethodString appendString:[NSString stringWithFormat:@"\t\t\tif ([[self class] rangeOfString:@\"%@\"].length > 0);\n", [excludeArray objectAtIndex:i]]];
        [deallocMethodString appendString:[NSString stringWithFormat:@"\t\t\t\tproceed = NO;\n"]];
        
    }
    [deallocMethodString appendString:[NSString stringWithFormat:@"\t\t\tif(proceed)\n"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\t\t\t\tNSLog(@\"deallocing: %@\", self);", @"%@"]];

    //    
    
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\t\tbreak;\n"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\t\tdefault:"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\t\tbreak;"]];
    [deallocMethodString appendString:[NSString stringWithFormat:@"\n\t}\n\n"]];
                    

    for (int i = 0; i < [releasablePropertiesArray count]; i++)
    {
        NSDictionary *dictObject = [releasablePropertiesArray objectAtIndex:i];
        
        NSString *key = [NSString stringWithFormat:@"%@", [[dictObject allKeys] objectAtIndex:0]];
        NSString *value = [dictObject objectForKey:key];
        
        Class objectClass = NSClassFromString(key);
        
        if ([objectClass isSubclassOfClass:[UIView class]] && ![objectClass isSubclassOfClass:[UIButton class]])
        {
            
            [deallocMethodString appendString:[NSString stringWithFormat:@"\n\tif ([self.%@ superview] != nil)\n", value]];
            [deallocMethodString appendString:[NSString stringWithFormat:@"\t{\n"]];
            [deallocMethodString appendString:[NSString stringWithFormat:@"\t\t[self.%@ removeFromSuperview];\n",value]];
            [deallocMethodString appendString:[NSString stringWithFormat:@"\t\t[self.%@ release];\n", value]];
            [deallocMethodString appendString:[NSString stringWithFormat:@"\t\tself.%@ = nil;\n", value]];
            [deallocMethodString appendString:[NSString stringWithFormat:@"\t}\n"]];
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


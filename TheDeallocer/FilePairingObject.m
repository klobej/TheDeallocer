//
//  FilePairingObject.m
//  TheDeallocer
//
//  Created by Josh Klobe on 3/12/13.
//  Copyright (c) 2013 Josh Klobe. All rights reserved.
//

#import "FilePairingObject.h"

@implementation FilePairingObject

@synthesize rootPath, headerFilename, implementationFilename, implementationReplacement;

-(NSString *)description
{
    NSMutableString *retStr = [NSMutableString stringWithCapacity:0];
    [retStr appendString:@"FilePairingObject\r"];
    [retStr appendString:[NSString stringWithFormat:@"rootPath: %@\r", self.rootPath]];
    [retStr appendString:[NSString stringWithFormat:@"headerFilename: %@\r", self.headerFilename]];
    [retStr appendString:[NSString stringWithFormat:@"implementationFilename: %@\r", self.implementationFilename]];
    [retStr appendString:@"\r"];
    
    return retStr;
}
@end

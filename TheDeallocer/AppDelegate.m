//
//  AppDelegate.m
//  TheDeallocer
//
//  Created by Josh Klobe on 3/12/13.
//  Copyright (c) 2013 Josh Klobe. All rights reserved.
//

#import "AppDelegate.h"
#import "FilePairingObject.h"
#import "DeallocManager.h"

@implementation AppDelegate

- (void)dealloc
{
    [super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    
    NSLog(@"here");
    
    NSString *folderPath = @"/Users/jklobe/Desktop/HomeTalk/HomeTalk/HomeTalk/";
//    NSString *folderPath = @"/Users/josh/Desktop/Hometalk/HomeTalk/HomeTalk/";
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *filesArray = [theFileManager contentsOfDirectoryAtPath:folderPath error:&error];
    
    NSMutableArray *filePairingObjectsArray = [NSMutableArray arrayWithCapacity:0];


    for (int i = 0; i < [filesArray count]; i++)
    {
        NSString *filename = [filesArray objectAtIndex:i];
        if ([filename rangeOfString:@".h"].length > 0)
        {
            FilePairingObject *filePairingObject = [[FilePairingObject alloc] init];
            filePairingObject.rootPath = folderPath;
            filePairingObject.headerFilename = filename;
            filePairingObject.implementationFilename = [filename stringByReplacingOccurrencesOfString:@".h" withString:@".m"];
            [filePairingObjectsArray addObject:filePairingObject];
        }

    }
    
    for (int i = 0; i < [filePairingObjectsArray count]; i++)
    {
    [DeallocManager handleFilePairingObject:[filePairingObjectsArray objectAtIndex:i]];
    }
    
}

@end

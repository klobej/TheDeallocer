//
//  AppDelegate.m
//  iDeallocer
//
//  Created by Josh Klobe on 3/13/13.
//  Copyright (c) 2013 Josh Klobe. All rights reserved.
//

#import "AppDelegate.h"
#import "FilePairingObject.h"
#import "DeallocManager.h"
@implementation AppDelegate

- (void)dealloc
{
    [_window release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    
    NSLog(@"here");
    
    NSString *folderPath = @"/Users/jklobe/Desktop/HomeTalk/HomeTalk/HomeTalk/";
    //NSString *folderPath = @"/Users/jaycanty/Desktop/HomeTalk/HomeTalk/";
    
    NSArray *excludeArray = [NSArray arrayWithObjects:@"ClassCreator.h", @"SMWebRequest.h", nil];
    NSFileManager *theFileManager = [NSFileManager defaultManager];
    NSError *error = nil;
    NSArray *filesArray = [theFileManager contentsOfDirectoryAtPath:folderPath error:&error];
    
    NSMutableArray *filePairingObjectsArray = [NSMutableArray arrayWithCapacity:0];
    
    
    for (int i = 0; i < [filesArray count]; i++)
    {
        NSString *filename = [filesArray objectAtIndex:i];
        if ([filename rangeOfString:@".h"].length > 0 && [excludeArray indexOfObject:filename] == NSNotFound)
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

    
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end

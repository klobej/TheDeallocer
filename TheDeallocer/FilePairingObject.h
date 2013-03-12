//
//  FilePairingObject.h
//  TheDeallocer
//
//  Created by Josh Klobe on 3/12/13.
//  Copyright (c) 2013 Josh Klobe. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FilePairingObject : NSObject
{
    NSString *rootPath;
    NSString *headerFilename;
    NSString *implementationFilename;
}

@property (nonatomic, retain) NSString *rootPath;
@property (nonatomic, retain) NSString *headerFilename;
@property (nonatomic, retain) NSString *implementationFilename;

@end

//
//  DeallocManager.h
//  TheDeallocer
//
//  Created by Josh Klobe on 3/12/13.
//  Copyright (c) 2013 Josh Klobe. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FilePairingObject.h"

@interface DeallocManager : NSObject


+(void)handleFilePairingObject:(FilePairingObject *)theFilePairingObject;

@end

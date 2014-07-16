//
//  VideoGame.m
//  MobileConnectivity
//
//  Created by Michael Crump on 7/15/14.
//  Copyright (c) 2014 Michael Crump. All rights reserved.
//

#import "VideoGame.h"

@implementation VideoGame
- (instancetype)init
{
    self = [super init];
    if (self) {
        _gameId = [[NSUUID UUID] UUIDString];
    }
    return self;
}
@end

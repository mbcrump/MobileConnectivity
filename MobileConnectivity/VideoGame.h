//
//  VideoGame.h
//  MobileConnectivity
//
//  Created by Michael Crump on 7/15/14.
//  Copyright (c) 2014 Michael Crump. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface VideoGame : NSObject
@property (strong, nonatomic) NSString *gameId;
@property (strong, nonatomic) NSString *gameTitle;
-(instancetype) init;
@end

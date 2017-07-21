//
//  PCNetworkStatus.h
//  PPTVCommon
//
//  Created by GuoQiang Qian on 13-1-9.
//  Copyright (c) 2013年 PPTV. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPTVReachability.h"

#define PCNetworkReachabilityChanged @"PCNetworkReachabilityChanged"

@interface PCNetworkStatus : NSObject

+ (instancetype)sharedNetworkStatus;

@property (nonatomic, strong, readonly) PPTVReachability *reachability;
@property (nonatomic, assign, readonly) PPTVReachNetworkStatus networkStatus;

@end

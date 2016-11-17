//
//  BZDataCache.h
//  CargoLogistics
//
//  Created by bobzhang on 16/3/29.
//  Copyright © 2016年 张博bobzhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SynthesizeSingleton.h"

@interface BZDataCache : NSObject

@property (nonatomic, strong) NSFileManager *fileManager;

+ (BZDataCache *)sharedBZDataCache;

- (NSString *)cacheForKey:(NSString *)key;
- (void)setCache:(NSString *)cache forKey:(NSString *)key;
- (void)removeCacheForKey:(NSString *)key;
- (void)removeAllCaches;

@end

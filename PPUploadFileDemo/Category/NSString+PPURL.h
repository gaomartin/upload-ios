//
//  NSString+PPURL.h
//  PPTVCommon
//
//  Created by GuoQiang Qian on 14-6-25.
//  Copyright (c) 2014年 PPLive Corporation. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (PPURL)

- (NSString *)URLEncodedString;

- (NSString *)URLDecodedString;

@end

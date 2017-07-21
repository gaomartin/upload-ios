//
//  PPDAC.h
//  PPYLiveKit
//
//  Created by bobzhang on 16/11/21.
//  Copyright © 2016年 PPTV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPDAC : NSObject

+ (PPDAC *)sharedPPDAC;

- (void)sendUploadInfo;//发送上传日志

@end

//
//  PPVideoInfo.h
//  PPTVFileUpload
//
//  Created by bobzhang on 2017/4/12.
//  Copyright © 2017年 PPTV. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PPVideoInfo : NSObject

@property (nonatomic, assign) BOOL isLocalCacheVideo;    //是否是APP的本地缓存视频, 默认NO, 默认是处理相册中的视频, 如果是缓存视频, 请使用YES

@property (nonatomic, strong) NSString *path;       //视频路径, 必传
@property (nonatomic, strong) NSString *title;      //视频标题, 可选
@property (nonatomic, strong) NSString *detail;     //视频详情, 可选

@property (nonatomic, assign) NSInteger width;      //视频宽度
@property (nonatomic, assign) NSInteger height;     //视频高度
@property (nonatomic, assign) NSInteger bitrate;    //视频码流率(kbp/s)
@property (nonatomic, assign) NSInteger framerate;  //视频帧率
@property (nonatomic, assign) NSInteger duration;   //视频长度(秒)

@end

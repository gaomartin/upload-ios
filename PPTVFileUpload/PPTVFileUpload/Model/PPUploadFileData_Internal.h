//
//  PPUploadFileData_Internal.h
//  PPTVFileUpload
//
//  Created by bobzhang on 16/11/30.
//  Copyright © 2016年 PPTV. All rights reserved.
//

#import <PPTVFileUpload/PPTVFileUpload.h>


//扩展, 以免暴露给上层不必要的参数
@interface PPUploadFileData ()

//本机文件地址
@property (nonatomic, copy) NSString * assetURL;
//上传路径
@property (nonatomic, copy) NSString * uploadPath;
//md5
@property (nonatomic, copy) NSString * md5;
//dcid
@property (nonatomic, copy) NSString * dcid;
//gcid
@property (nonatomic, copy) NSString * gcid;
//pid
@property (nonatomic, copy) NSString * pid;
//文件cid
@property (nonatomic, copy) NSString * cid;
//id
@property (nonatomic, copy) NSString * uploadID;
//fid
@property (nonatomic, copy) NSString *fid;
//token
@property (nonatomic, copy) NSString *token;
/* 文件的唯一标识 */
@property (nonatomic, copy) NSString *fileIdentifier;

@property (nonatomic, copy) NSString *fileIdentifierForLog;

@property (nonatomic, assign) BOOL isLocalCacheVideo;    //是否是APP的本地缓存视频, 默认NO, 默认是处理相册中的视频, 如果是缓存视频, 请使用YES
@property (nonatomic, strong) NSString *path;       //视频路径
@property (nonatomic, assign) NSInteger width;      //视频宽度
@property (nonatomic, assign) NSInteger height;     //视频高度
@property (nonatomic, assign) NSInteger bitrate;    //视频码流率(kbp/s)
@property (nonatomic, assign) NSInteger framerate;  //视频帧率
@property (nonatomic, assign) NSInteger duration;   //视频长度(秒)

//上传日志
@property (nonatomic, strong) NSString *user_id;

@end

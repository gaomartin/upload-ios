//
//  PPUploadFileData.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/27.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

//上传文件进度
typedef NS_ENUM(NSUInteger, UploadProgress)
{
    UPProgressCreateFile    ,//创建文件
    UPProgressSubmitMD5     ,//提交md5
    UPProgressSubmitOther   ,//提交其他信息
    UPProgressWaiting       ,//等待中...
    UPProgressUploading     ,//上传中...
    UPProgressComplete      ,//上传完成
};

//上传文件状态
typedef NS_ENUM(NSUInteger, UploadStatus)
{
    //---视频上传状态---
    UPStatusNormal      , //正常状态
    UPStatusWait        , //等待状态
    UPStatusPause       , //上传暂停
    UPStatusUploading   , //正在上传
    UPStatusUploadFinish, //已完成
    UPStatusError       , //上传出错..
};

@interface PPUploadFileData : NSObject<NSCoding>

//创建时间
@property (nonatomic, copy) NSDate *createDate;
//是否已开始上传
@property (nonatomic, assign) BOOL isStartUploaded;
//视频缩略图
@property (nonatomic, copy) UIImage * fileImage;
//file_status >= 100 表示秒传
@property (nonatomic, assign) NSInteger file_status;
//文件大小
@property (nonatomic) long long fileSize;
//channelWebId 播放相关
@property (nonatomic, copy) NSString * channelWebId;
//ppfeature
@property (nonatomic, copy) NSString * ppfeature;
//分类编号
@property (nonatomic, assign) NSInteger categoryId;
//分类名称
@property (nonatomic, copy) NSString * categoryName;
//视频名
@property (nonatomic, copy) NSString * fileName;
//介绍
@property (nonatomic, copy) NSString * introduce;
//已上传大小
@property (nonatomic) long long finished;
//当前进度
@property (nonatomic) UploadProgress progress;
//当前状态
@property (nonatomic) UploadStatus status;

@end

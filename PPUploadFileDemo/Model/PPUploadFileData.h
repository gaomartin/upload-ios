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
    UPProgressDecoding      ,//压制中
    UPProgressPublishing    ,//发布中
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
    
    //---下面这些用于在上传完成后服务器对视频的操作---
    UPStatusDecoding    , //压制中...
    UPStatusDecodeFinish, //压制成功
    UPStatusDecodeError , //压制失败
    UPStatusPublishing  , //发布中...
    UPStatusPublishFinish,//发布成功
    UPStatusPublishError,//发布失败
};

@interface PPUploadFileData : NSObject

//视频标识
@property (nonatomic, copy) NSString * assetURL;//文件地址
//视频缩略图
@property (nonatomic, copy) UIImage * fileImage;

//ppfeature
@property (nonatomic, copy) NSString * ppfeature;
@property (nonatomic, copy) NSString * channelWebId;
@property (nonatomic, assign) NSInteger categoryId;//分类编号
@property (nonatomic, copy) NSString * categoryName;//分类名称
//视频名
@property (nonatomic, copy) NSString * fileName;
//介绍
@property (nonatomic, copy) NSString * introduce;
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
//上传异常码
@property (nonatomic, copy) NSString * exceptionCode;
//请求block块位置的用时
@property (nonatomic, copy) NSString * blockRequestTime;
//请求block块位置是否成功
@property (nonatomic, copy) NSString * blockExceptionCode;
//block块上传用时
@property (nonatomic, copy) NSString * uploadDuration;
//是否在上传结束后删除文件
@property (nonatomic) BOOL isDeleteOnFinished;
//创建时间
@property (nonatomic, copy) NSDate *createDate;
//是否已开始上传
@property (nonatomic, assign) bool isStartUploaded;

//是否被选中
@property (nonatomic) bool isSelected;
//是否停止
@property (nonatomic) bool isStop;
//fid
@property (nonatomic) long long fid;
//文件大小
@property (nonatomic) long long fileSize;

//文件视频时长
@property (nonatomic) double duration;
//已上传大小
@property (nonatomic) long long finished;
//当前进度
@property (nonatomic) UploadProgress progress;
//当前状态
@property (nonatomic) UploadStatus status;
//上传协议
@property (nonatomic) int protocol;
//上传类型
@property (nonatomic) int uploadType;

//请求block块始末请求是否成功
@property (nonatomic) int isBlockSuccess;

///** 文件的唯一标识 */
//-(NSString *) fileIdentifier;

@end

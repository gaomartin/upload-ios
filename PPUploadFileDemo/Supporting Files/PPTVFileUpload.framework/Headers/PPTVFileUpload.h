//
//  PPTVFileUpload.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/8/1.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PPUploadFileData.h"
#import "PPVideoInfo.h"

/*!
 *  @brief 文件上传回调
 */
@protocol PPTVUploadDelegate <NSObject>

@optional

/*!
 *  @brief 检索本地视频成功
 *  @discussion 可以不用处理该回调
 */
- (void)getVideoInfoSuccess;

/*!
 *  @brief 检索本地视频失败
 *  @param message 失败原因
 *  @discussion 无法检索到视频, 无法上传
 */
- (void)getVideoInfoFailed:(NSString *)message;

/*!
 *  @brief 文件上传状态的变化回调
 *  @discussion 回调中, 刷新上传文件的状态
 */
- (void)uploadFileStatusChange;

@end


/*!
 *  @brief PPTV文件上传SDK
 */
@interface PPTVFileUpload : NSObject

/*!
 *  @brief 文件上传delegate
 */
@property (nonatomic, weak) id <PPTVUploadDelegate> uploadDelegate;

/*!
 *  @brief 所有上传文件对象的数组
 */
@property (nonatomic, strong) NSMutableArray *allUploadFiles;

/*!
 *  @brief 初始化
 *  @param domainName 域名
 *  @param cookie HTTPHeader
 */
- (instancetype)initWithDomainName:(NSString *)domainName andCookie:(NSString *)cookie;

/*!
 *  @brief 开始上传文件
 *  @param info PPVideoInfo对象
 */
- (void)startUploadFileWithVideoInfo:(PPVideoInfo *)info;

/*!
 *  @brief 改变文件的上传状态
 *  @param fileData PPUploadFileData对象, 指定文件
 *  @param status UploadStatus对象, 文件状态
 */
- (void)changeUploadingFile:(PPUploadFileData *)fileData toStatus:(UploadStatus)status;

/*!
 *  @brief 取消上传
 *  @param fileData PPUploadFileData对象, 指定文件
 *  @discussion 已经上传成功的是无法取消的, 这里取消的只是网络请求.
 */
- (void)removeUploadFile:(PPUploadFileData *)fileData;


@end

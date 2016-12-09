//
//  PPFileUploadManager.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/8/1.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

#define MAX_CONCURRENT_TASK_NUMBER 5 //最大5个并行任务
#define MIN_CONCURRENT_TASK_NUMBER 1 //最小并行任务数
#define FileUploadingCheckNotification @"fileUploadingCheckNotification"    //文件上传更新检查通知

@protocol PPUploadFileManagerDelegate <NSObject>

/** 上传文件状态变化回调 */
- (void) uploadingFileStatusChange;

@end

@interface PPFileUploadManager : NSObject

@property(nonatomic, weak) id<PPUploadFileManagerDelegate> delegate;

/*!
 @brief 获取单例对象
 */
+ (instancetype)sharedFileUploadManager;

/*! @brief 添加新上传文件到队列中
 @param uploadFile 需要被添加的上传对象
 */
- (BOOL)addNewUploadFile:(PPUploadFileData *)uploadFile;

- (void)upgradeFileProperty:(PPUploadFileData *)uploadFile;

/*! @brief 从所有的文件队列中删除上传文件
 @param uploadFile 需要删除的上传对象
 */
- (void)removeUploadFile:(PPUploadFileData *)uploadFile;

/*! @brief 加载本地所有的上传文件信息(之前完成和未完成的数据信息)*/
- (void)loadAllUploadFilesFromLocal;

/*! @brief 取消所有队列中的数据和正在执行的操作 */
- (void)releaseAllUploadFiles;

/*! @brief 取消所有正在上传的文件 */
- (void)cancelAllUploadingFiles;

/*! @brief 当前的所有上传文件数据 */
- (NSMutableArray *)currentAllUploadFiles;

/*! @brief 修改上传文件状态操作
 
 @param uploadFile 需要被修改的上传文件
 @param status 文件的状态信息
 */
- (void)changeUploadingFile:(PPUploadFileData *)uploadFile toStatus:(UploadStatus)status;

@end

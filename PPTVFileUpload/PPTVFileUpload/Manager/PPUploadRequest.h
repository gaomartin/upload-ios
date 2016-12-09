//
//  PPUploadRequest.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/8/1.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import <Foundation/Foundation.h>

//协议
@protocol PPUploadRequestDelegate

@optional

//创建上传文件完成的回调
-(void)createFileComplete:(PPUploadFileData*)fileData;

//提交MD5完成的回调
-(void)submitMD5Complete:(PPUploadFileData*)fileData;

//上传文件块完成的回调
-(void)uploadingFileComplete:(PPUploadFileData*)fileData;

//获取文件进度的回调
-(void)fetchFileProgressComplete:(PPUploadFileData*)fileData;

@end


@interface PPUploadRequest : NSObject

@property(nonatomic, strong)  NSOperationQueue *operationQueue;//请求执行队列
@property(nonatomic, weak) id<PPUploadRequestDelegate> delegate;//数据操作流程中的回调

//创建上传文件, 就是请求fid
- (void)createFileWithData:(PPUploadFileData*)fileData;

//提交MD5
- (void)submitMD5WithData:(PPUploadFileData*)fileData;

//开始上传文件块
- (void)uploadingFileWithData:(PPUploadFileData*)fileData;


@end

//
//  PPUploadHashTool.h
//  PPCloudPlay_iphone
//
//  Created by stephenzhang on 14-3-25.
//  Copyright (c) 2014年 PPTV. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FileBlock: NSObject

@property(nonatomic, copy)NSString *blockMD5;
@property(nonatomic, copy)NSData *blockData;

@end
////////////////////////////////////////////////////////////////////////////////////////////////////

@class PPUploadFileData;

//委托
@protocol PPUploadHashToolDelegate

@optional
//获得PPfeature后的回调
-(void)getPPfeature:(NSString*)PPfeature fileData:(PPUploadFileData*)fileData;

//获得dcid后的回调
-(void)getDcid:(NSString*)dcidString fileData:(PPUploadFileData*)fileData;

//获得gcid后的回调
-(void)getGcid:(NSString*)gcidString fileData:(PPUploadFileData*)fileData;

//获得MD5后的回调
-(void)getMD5:(NSString*)MD5String fileData:(PPUploadFileData*)fileData;

//获得分段MD5后的回调
-(void)getBlockMD5:(FileBlock*)fileBlock start:(long long)start end:(long long)end bid:(NSString*)bid uploadUrl:(NSString*)uploadUrl fileData:(PPUploadFileData*)fileData;

@end


@interface PPUploadHashTool : NSObject

@property(nonatomic,weak)id<PPUploadHashToolDelegate> delegate;

//计算PPfeature
- (void)computePPfeature:(PPUploadFileData*)fileData;

//计算dcid
- (void)computeDcid:(PPUploadFileData*)fileData;

//计算gcid
- (void)computeGcid:(PPUploadFileData*)fileData;

//计算MD5
- (void)computeMD5:(PPUploadFileData*)fileData;

//计算分段MD5
- (void)computeMD5withStart:(long long)start end:(long long)end bid:(NSString*)bid uploadUrl:(NSString*)uploadUrl fileData:(PPUploadFileData*)fileData;

@end

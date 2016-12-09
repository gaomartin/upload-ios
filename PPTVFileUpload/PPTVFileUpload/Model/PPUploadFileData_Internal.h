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


@end

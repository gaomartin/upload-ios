//
//  PPCloudErrorCodeDefine.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/8/3.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#ifndef PPCloudErrorCodeDefine_h
#define PPCloudErrorCodeDefine_h

//播放器错误
#define     PLAY_LOAD_FINISH  @"0"  //播放器加载完成
#define     PLAY_LOAD_ERROR   @"401"  //播放器加载失败
#define     PLAY_LOAD_TIMEOUT @"402"     //播放器回调返回前，点击返回按钮

//上传错误
#define    UPLOAD_NO_ERROR               @"0"    //无异常状态码
#define    UPLOAD_CREATFILE_ERROR        @"201"  //创建文件请求失败
#define    UPLOAD_PLACEHOLDER_ERROR      @"202"  //文件占位请求失败
#define    UPLOAD_SUBMITMD5_ERROR        @"203"  //提交MD5失败
#define    UPLOAD_SUBMITOTHER_ERROR      @"204"  //提交其它特征失败
#define    UPLOAD_UPLOADPROTOCOL_ERROR   @"205"  //没有可用的上传文件协议
#define    UPLOAD_UPLOADRANGE_ERROR      @"206"  //请求上传范围错误
#define    UPLOAD_FILEBLOCK_ERROR        @"207"  //提交文件块错误
#define    UPLOAD_ADDUPLOADRECORD_ERROR  @"208"  //添加上传文件记录错误


//下载错误
#define    DOWNLOAD_NO_ERROR             @"0"   //无异常状态码
#define    DOWNLOAD_DOWNLOADING_TIMEOUT  @"1"   //链接下载服务器超时
#define    DOWNLOAD_NO_SPACE             @"2"   //无下载空间
#define    DOWN_PLAY

#endif /* PPCloudErrorCodeDefine_h */

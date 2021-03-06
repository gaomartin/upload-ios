//
//  PPUploadRequest.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/8/1.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "PPUploadRequest.h"
#import "PPUploadHashTool.h"
#import "NSString+Hashes.h"
#import "BZRangeInfo.h"
#import "NSString+PPURL.h"
#import "PPDAC.h"

@interface PPUploadRequest()<PPUploadHashToolDelegate>

@property (nonatomic, strong) PPUploadHashTool *uploadHashTool;

@end

@implementation PPUploadRequest

- (instancetype)init
{
    if(self = [super init])
    {
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.uploadHashTool = [[PPUploadHashTool alloc] init];
        self.uploadHashTool.delegate = self;
    }
    
    return self;
}

- (void)createFileWithData:(PPUploadFileData*)fileData
{
    self.uploadHashTool.delegate = self;
   
    if(!fileData.ppfeature)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.uploadHashTool computePPfeature:fileData];
        });
    } else {
        [self getPPfeature:fileData.ppfeature fileData:fileData];
    }
}

//ppfeature计算完成后的回调
-(void)getPPfeature:(NSString*)PPfeature fileData:(PPUploadFileData*)fileData
{
    NSLog(@"%@ getPPfeature : %@",fileData.fileIdentifierForLog,PPfeature);
    fileData.ppfeature = PPfeature;
    
    if(!fileData.cid || !fileData.uploadID)
    {
        NSMutableURLRequest* createFileRequest = [self createFileRequestWithData:fileData];//请求fid
        [NSURLConnection sendAsynchronousRequest:createFileRequest queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *createFileData, NSError *error)
         {
             NSDictionary *dic = [createFileData PPJSONValue];//[NSJSONSerialization JSONObjectWithData:createFileData options:NSJSONReadingMutableLeaves error:&error];
             NSLog(@"%@ request fid : %@",fileData.fileIdentifierForLog, dic);
             
             if (error)
             {
                 fileData.status = UPStatusError;
                 fileData.errorMsg = error.description;
                 fileData.errorCode = error.code;
                 [self uploadErrorWithInfo:fileData];
             } else {
                 if (createFileData) {
                     if(dic && [[dic safeNumberForKey:@"err"] integerValue] == 0)
                     {
                         NSDictionary* resultDic = [dic safeDictionaryForKey:@"data"];
                         fileData.cid = [[resultDic safeNumberForKey:@"channel_id"] stringValue];
                         fileData.channelWebId = [resultDic safeStringForKey:@"channel_web_id"];
                         fileData.fid = [[resultDic safeNumberForKey:@"fid"] stringValue];
                         fileData.ppfeature = [resultDic safeStringForKey:@"ppfeature"];
                         fileData.uploadID = [[resultDic safeNumberForKey:@"id"] stringValue];
                         fileData.status = UPStatusUploading;
                         fileData.progress = UPProgressSubmitMD5;
                         fileData.file_status = [[resultDic safeNumberForKey:@"file_status"] integerValue];
                         fileData.token = [resultDic safeStringForKey:@"up_token"];
                         fileData.categoryId = [[resultDic safeNumberForKey:@"category_id"] integerValue];
                         fileData.user_id = [[resultDic safeNumberForKey:@"user_id"] stringValue];
                         
                         if (fileData.file_status >= 100) {//秒传
                             fileData.finishedSize = fileData.fileSize;
                             fileData.progress = UPProgressComplete;
                             fileData.status = UPStatusUploadFinish;
                             [self.delegate uploadingFileComplete:fileData];
                             
                             return;
                         }
                         
                         [self.delegate createFileComplete:fileData];
                         
                     } else {
                         fileData.status = UPStatusError;
                         fileData.errorMsg = @"请求fid失败";
                         fileData.errorCode = [[dic safeNumberForKey:@"err"] integerValue];
                         fileData.progress = UPProgressWaiting;
                         [self uploadErrorWithInfo:fileData];
                     }
                 } else {
                     fileData.status = UPStatusError;
                     fileData.errorMsg = @"请求fid失败, data返回为空";
                     fileData.errorCode = error.code;
                     fileData.progress = UPProgressWaiting;
                     [self uploadErrorWithInfo:fileData];
                 }
             }
         }];
    } else {
        fileData.status = UPStatusUploading;
        fileData.progress = UPProgressSubmitMD5;
        [self submitMD5WithData:fileData];
    }
}

- (void)submitMD5WithData:(PPUploadFileData*)fileData
{
    self.uploadHashTool.delegate = self;
    
    if(fileData.md5 == nil)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [self.uploadHashTool computeMD5:fileData];
        });
    } else {
        [self getMD5:fileData.md5 fileData:fileData];
    }
}

//获得MD5后的回调
-(void)getMD5:(NSString*)MD5String fileData:(PPUploadFileData*)fileData
{
    NSLog(@"%@ 完整视频的md5计算成功: md5=%@", fileData.fileIdentifierForLog, MD5String);
    
    NSMutableURLRequest* MD5Request = [self MD5RequestWithFid:fileData.fid feature:fileData.ppfeature md5:fileData.md5];
    
    [MD5Request addValue:fileData.token forHTTPHeaderField:@"Authorization"];

    [NSURLConnection sendAsynchronousRequest:MD5Request queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *MD5Data, NSError *error)
     {
         if (error)
         {
             fileData.status = UPStatusError;
             fileData.errorMsg = error.description;
             fileData.errorCode = error.code;
             [self uploadErrorWithInfo:fileData];
         } else {
             NSDictionary *dic = [MD5Data PPJSONValue]; //[NSJSONSerialization JSONObjectWithData:MD5Data options:NSJSONReadingMutableLeaves error:&error];
             NSLog(@"%@ getMD5 dic : %@",fileData.fileIdentifierForLog, dic);
             if (dic && [[dic safeNumberForKey:@"err"] integerValue] == 0)
             {
                 fileData.status = UPProgressWaiting;
                 fileData.progress = UPStatusUploading;
                 [self.delegate submitMD5Complete:fileData];
             } else {
                 fileData.status = UPStatusError;
                 fileData.errorMsg = @"请求md5失败";
                 fileData.errorCode = [[dic safeNumberForKey:@"err"] integerValue];
                 [self uploadErrorWithInfo:fileData];
             }
         }
     }];
}

//开始上传文件块
- (void)uploadingFileWithData:(PPUploadFileData*)fileData
{
    NSMutableURLRequest* uploadRangeRequest = [self uploadRangeRequestV3WithFid:fileData.fid feature:fileData.ppfeature];
    [uploadRangeRequest addValue:fileData.token forHTTPHeaderField:@"Authorization"];
    
    //NSDate *requsetBeforeDate = [NSDate date];
    [NSURLConnection sendAsynchronousRequest:uploadRangeRequest queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *uploadRangeData, NSError *error)
     {
         //NSTimeInterval requsetAfterDate = [[NSDate date] timeIntervalSinceDate:requsetBeforeDate];
         //NSString *requestTime = [NSString stringWithFormat:@"%f",round(requsetAfterDate*1000)];
         NSDictionary *dic = [uploadRangeData PPJSONValue]; //[NSJSONSerialization JSONObjectWithData:uploadRangeData options:NSJSONReadingMutableLeaves error:&error];
         NSLog(@"%@ uploadRangeData dic: %@",fileData.fileIdentifierForLog, dic);
         
         if (error)
         {
             fileData.status = UPStatusError;
             fileData.errorMsg = error.description;
             fileData.errorCode = error.code;
             fileData.progress = UPProgressWaiting;
             [self uploadErrorWithInfo:fileData];
         } else {
             if (dic && [[dic safeNumberForKey:@"err"] integerValue] == 0)
             {
                 NSDictionary *dataDic = [dic safeDictionaryForKey:@"data"];
                 NSInteger status = [[dataDic safeNumberForKey:@"status"] integerValue];
                 /*!
                  status: 上传中0-99，转码中100-199，200-299 可播放，>300已删除
                  if status=0-99，range不为空，then 需要用户上传
                  if status=0-99，range为空，then 暂时不需要上传。
                  If status>=100-149, 已经上传完成，转码中，客户端向私有云请求status或channelid。
                  If status>=150, 表示转码失败。
                  */
                 if (status >= 100)
                 {
                     fileData.finishedSize = fileData.fileSize;
                     fileData.progress = UPProgressComplete;
                     fileData.status = UPStatusUploadFinish;
                     [self.delegate uploadingFileComplete:fileData];
                     return;
                 }
                 
                 if ([[dataDic safeArrayForKey:@"ranges"] count] == 0)
                 {
                     fileData.progress = UPProgressUploading;
                     fileData.status = UPStatusUploading;
                     [self.delegate uploadingFileComplete:fileData];
                     return;
                 }
                 
                 NSArray *ranges = [dataDic safeArrayForKey:@"ranges"];
                 
                 for (int i=0; i<[ranges count]; i++) {
                     NSDictionary* blockDic = [ranges objectAtIndexIfIndexInBounds:i];
                     NSString* bid = [blockDic safeStringForKey:@"bid"];
                     long long start = [[blockDic safeNumberForKey:@"start"] longLongValue];
                     long long end = [[blockDic safeNumberForKey:@"end"] longLongValue];
                     NSString* url = [blockDic safeStringForKey:@"upload_url"];
                     
                     self.uploadHashTool.delegate = self;
                     dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                         [self.uploadHashTool computeMD5withStart:start end:end bid:bid uploadUrl:url fileData:fileData];
                     });
                 }
             } else {
                 fileData.status = UPStatusError;
                 fileData.errorMsg = @"请求上传ranges失败";
                 fileData.errorCode = [[dic safeNumberForKey:@"err"] integerValue];
                 fileData.progress = UPProgressWaiting;
                 [self uploadErrorWithInfo:fileData];
             }
         }
     }];
}

//获得分段MD5后的回调
-(void)getBlockMD5:(FileBlock*)fileBlock start:(long long)start end:(long long)end bid:(NSString *)bid uploadUrl:(NSString *)uploadUrl
          fileData:(PPUploadFileData *)fileData
{
    NSLog(@"%@ 分段视频的md5计算成功, md5=%@",fileData.fileIdentifierForLog, fileBlock.blockMD5);
    
    NSMutableURLRequest *urlRequest = [self uploadingRequestWithUrl:uploadUrl bid:bid start:start end:end fileBlock:fileBlock];//上传文件
    [urlRequest addValue:fileData.token forHTTPHeaderField:@"Authorization"];
    [urlRequest addValue:fileBlock.blockMD5 forHTTPHeaderField:@"Etag"];
    
    [NSURLConnection sendAsynchronousRequest:urlRequest queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *MD5Data, NSError *error)
     {
         NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
         NSDictionary* headerDic = [(NSHTTPURLResponse *)response allHeaderFields];
         
         // 这里只关心responseCode, 不管返回结果
         if(responseCode == 201)//表示正确返回响应数据
         {
             NSLog(@"%@ upload file success", fileData.fileIdentifierForLog);
             //上传完成汇报
             NSString* uploadid = [headerDic safeStringForKey:@"Etag"];
             
             NSMutableURLRequest *reportRequest = [self reportRequestV3WithFid:fileData.fid MD5:fileBlock.blockMD5 bid:bid uploadid:uploadid];//分段上传完成汇报
             [reportRequest addValue:fileData.token forHTTPHeaderField:@"Authorization"];
             //汇报上传数据
             [NSURLConnection sendAsynchronousRequest:reportRequest queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *reportData, NSError *error)
              {
                  NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
                  if(responseCode == 200)
                  {
                      NSLog(@"%@ uploaded report success", fileData.fileIdentifierForLog);
                      NSMutableURLRequest* progressRequest = [self getProgressRequestWithFid:fileData.fid];//上传进度请求
                      [progressRequest addValue:fileData.token forHTTPHeaderField:@"Authorization"];
                      
                      [NSURLConnection sendAsynchronousRequest:progressRequest queue:self.operationQueue completionHandler:^(NSURLResponse *response, NSData *progressData, NSError *error)
                       {
                           NSInteger responseCode = [(NSHTTPURLResponse *)response statusCode];
                           if(responseCode == 200)
                           {
                               NSDictionary *progressDic = [progressData PPJSONValue];//[NSJSONSerialization JSONObjectWithData:progressData options:NSJSONReadingMutableLeaves error:&error];
                               NSLog(@"%@ progressDic : %@", fileData.fileIdentifierForLog, progressDic);
                               NSDictionary *data = [progressDic safeDictionaryForKey:@"data"];
                               fileData.finishedSize = [[data safeNumberForKey:@"finished"] longLongValue];
                               fileData.progress = UPProgressUploading;
                               fileData.status = UPStatusUploading;
                               [self.delegate uploadingFileComplete:fileData];
                           } else {
                               NSLog(@"%@ get progress error, responseCode=%zd",fileData.fileIdentifierForLog,responseCode);
                               fileData.status = UPStatusError;
                               fileData.errorMsg = @"请求上传进度失败";
                               fileData.errorCode = responseCode;
                               fileData.progress = UPProgressWaiting;
                               [self uploadErrorWithInfo:fileData];
                           }
                       }];
                  } else {
                      NSLog(@"%@ uploaded reportfailed, responseCode=%zd",fileData.fileIdentifierForLog,responseCode);
                      fileData.status = UPStatusError;
                      fileData.errorMsg = @"汇报上传数据失败";
                      fileData.errorCode = responseCode;
                      fileData.progress = UPProgressWaiting;
                      [self uploadErrorWithInfo:fileData];
                  }
              }];
         } else {
             NSLog(@"%@ upload file failed, responseCode=%zd",fileData.fileIdentifierForLog,responseCode);
             fileData.status = UPStatusError;
             fileData.errorMsg = @"上传文件失败";
             fileData.errorCode = responseCode;
             fileData.progress = UPProgressWaiting;
             [self uploadErrorWithInfo:fileData];
         }

     }];
    
     [[PPFileUploadManager sharedFileUploadManager] startSendLog];
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - httpRequest

//新建文件请求
- (NSMutableURLRequest*)createFileRequestWithData:(PPUploadFileData *)fileData
{
    NSString *intro = [fileData.introduce ? : @"详细内容稍后补充" PPTV_URLEncodedString];
    NSString *name = [fileData.fileName ? : @"iosFileUploadTest"  PPTV_URLEncodedString];
    
    NSString *createUrl = [NSString stringWithFormat:@"%@?name=%@&length=%lld&ppfeature=%@&summary=%@", [BZUserModel sharedBZUserModel].domainName, name, fileData.fileSize,fileData.ppfeature, intro];
    //add video info
    createUrl = [NSString stringWithFormat:@"%@&width=%zd&height=%zd&bitrate=%zd&framerate=%zd&duration=%zd",createUrl, fileData.width, fileData.height, fileData.bitrate, fileData.framerate, fileData.duration];
    NSLog(@"get createUrl =%@",createUrl);
    
    NSMutableURLRequest *myRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:createUrl]];
    [myRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [myRequest setValue:@"text/plain" forHTTPHeaderField:@"Accept"];//for suning
    
    if ([[BZUserModel sharedBZUserModel].cookie length]) {
        [myRequest setValue:[BZUserModel sharedBZUserModel].cookie forHTTPHeaderField:@"Cookie"];
    }
    
    [myRequest setHTTPMethod:@"GET"];
    
    return myRequest;
}

//提交MD5
- (NSMutableURLRequest*)MD5RequestWithFid:(NSString *)fid feature:(NSString*)feature md5:(NSString*)md5
{
    NSString *sumbitMD5Url = [NSString stringWithFormat:@"%@/fsvc/1/file/%@/md5?md5=%@&feature_pplive=%@",PPCLOUD_PUBLIC_URL,fid,md5,feature];
    NSMutableURLRequest *myRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:sumbitMD5Url]];
    [myRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [myRequest setHTTPMethod:@"POST"];
    NSLog(@"post sumbitMD5Url =%@",sumbitMD5Url);
    
    return myRequest;
}

//获得上传范围v3
- (NSMutableURLRequest*)uploadRangeRequestV3WithFid:(NSString *)fid feature:(NSString*)feature
{
    //segs=3改为segs=1
    NSString *uploadrangeV3Url= [NSString stringWithFormat:@"%@/fsvc/3/file/%@/action/uploadrange?feature_pplive=%@&segs=1&fromcp=ppcloud&inner=false",PPCLOUD_PUBLIC_URL,fid,feature];
    NSLog(@"get uploadrange v3 url = %@",uploadrangeV3Url);
    NSMutableURLRequest *myRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:uploadrangeV3Url]];
    [myRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [myRequest setHTTPMethod:@"GET"];
    
    return myRequest;
}

//上传文件
- (NSMutableURLRequest*)uploadingRequestWithUrl:(NSString*)url bid:(NSString*)bid start:(long long)start end:(long long)end fileBlock:(FileBlock*)fileBlock
{
    NSMutableURLRequest *myRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];
    
    [myRequest setValue:fileBlock.blockMD5 forHTTPHeaderField:@"Content-MD5"];
    [myRequest setValue:[NSString stringWithFormat:@"%lld",(end - start + 1)] forHTTPHeaderField:@"Content-Length"];
    [myRequest setHTTPBodyStream:[NSInputStream inputStreamWithData:fileBlock.blockData]];
    [myRequest setHTTPMethod:@"PUT"];
    NSLog(@"put uploadingRequest Url =%@",url);
    
    return myRequest;
}

//上传完成汇报V3
- (NSMutableURLRequest*)reportRequestV3WithFid:(NSString *)fid MD5:(NSString*)MD5 bid:(NSString*)bid uploadid:(NSString*)uploadid
{
    //请求链接	/fsvc/3/file/{fid}/action/uploaded?range_md5=1234567890abcdef&bid=123456&uploadid=123456
    NSString *reportV3Url = [NSString stringWithFormat:@"%@/fsvc/3/file/%@/action/uploaded?range_md5=%@&bid=%@&uploadid=%@",PPCLOUD_PUBLIC_URL,fid,MD5,bid,uploadid];
    NSMutableURLRequest *myRequest=[NSMutableURLRequest requestWithURL:[NSURL URLWithString:reportV3Url]];
    [myRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [myRequest setHTTPMethod:@"POST"];
    NSLog(@"post reportV3Url =%@",reportV3Url);
    
    return myRequest;
}

//获取上传进度
- (NSMutableURLRequest*)getProgressRequestWithFid:(NSString*)fid
{
    NSString *progressUrl = [NSString stringWithFormat:@"%@/fsvc/3/file/%@/uploading?fromcp=private_cloud",PPCLOUD_PUBLIC_URL,fid];
    NSMutableURLRequest *myRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:progressUrl]];
    [myRequest setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [myRequest setHTTPMethod:@"GET"];
    NSLog(@"get getProgress url =%@",progressUrl);
    
    return myRequest;
}


#pragma mark  -

- (void)uploadErrorWithInfo:(PPUploadFileData*)fileData
{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"error info = %@, errorCode = %zd", fileData.errorMsg, fileData.errorCode);
        [[NSNotificationCenter defaultCenter] postNotificationName:FileUploadingCheckNotification object:nil];
    });
}

@end

//
//  PPTVFileUpload.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/8/1.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "PPTVFileUpload.h"
#import <AssetsLibrary/AssetsLibrary.h>

@interface PPTVFileUpload ()<PPUploadFileManagerDelegate>

@property (nonatomic, strong) PPUploadFileData *videoInfo;//视频信息实体
@property (nonatomic, strong) NSMutableArray *uploadFileArray;


@end

@implementation PPTVFileUpload

- (instancetype)initWithDomainName:(NSString *)domainName andCookie:(NSString *)cookie
{
    if (self = [super init])
    {
        [BZUserModel sharedBZUserModel].domainName = domainName;
        [BZUserModel sharedBZUserModel].cookie = cookie;
        
        [self loadAllUploadFilesFromLocal];
        
        //TODO: 删除tmp文件夹中的.MOV文件, 这个方法需不需要SDK内部处理?
        [self deleteTmpFolderVideo];
    }
    
    return self;
}

- (void)loadAllUploadFilesFromLocal
{
    [[PPFileUploadManager sharedFileUploadManager] loadAllUploadFilesFromLocal];
    [PPFileUploadManager sharedFileUploadManager].delegate = self;
}

- (void)uploadingFileStatusChange
{
    if (self.uploadDelegate && [self.uploadDelegate respondsToSelector:@selector(uploadFileStatusChange)]) {
        [self.uploadDelegate uploadFileStatusChange];
    }
    
    NSArray *uploadArray = self.allUploadFiles;
    
    BOOL isNeedSend = NO;
    for (PPUploadFileData *fileData in uploadArray) {
        NSLog(@"uploadingFileStatusChange fileData.status=%zd",fileData.status);
        if (fileData.status == UPStatusUploading) {
            isNeedSend = YES;
        }
    }
    
    if (!isNeedSend) {
        [[PPFileUploadManager sharedFileUploadManager] stopSendLog];
    }
}

- (NSMutableArray *)allUploadFiles
{
    //PPUploadFileData数据
    self.uploadFileArray = [[PPFileUploadManager sharedFileUploadManager] currentAllUploadFiles];
    
    return self.uploadFileArray;
}

- (void)changeUploadingFile:(PPUploadFileData *)uploadFile toStatus:(UploadStatus)status
{
    PPUploadFileData *fileData;
    for (int i=0; i<[self.uploadFileArray count]; i++) {
        fileData = [self.uploadFileArray objectAtIndex:i];
        
        if ([fileData.fileIdentifier isEqualToString:uploadFile.fileIdentifier]) {
            break;
        }
    }
    
    [[PPFileUploadManager sharedFileUploadManager] changeUploadingFile:fileData toStatus:status];
}

- (void)removeUploadFile:(PPUploadFileData *)uploadFile
{
    PPUploadFileData *fileData;
    for (int i=0; i<[self.uploadFileArray count]; i++) {
        fileData = [self.uploadFileArray objectAtIndex:i];
        
        if ([fileData.fileIdentifier isEqualToString:uploadFile.fileIdentifier]) {
            break;
        }
    }
    
    [[PPFileUploadManager sharedFileUploadManager] removeUploadFile:fileData];
}

- (void)startUploadFileWithVideoInfo:(PPVideoInfo *)info
{
    if (info.isLocalCacheVideo) {
        NSData *data = [NSData dataWithContentsOfFile:info.path];
        
        if (!data) {
            NSLog(@"videoInfo.path=%@", info.path);
            if (self.uploadDelegate && [self.uploadDelegate respondsToSelector:@selector(getVideoInfoFailed:)]) {
                [self.uploadDelegate getVideoInfoFailed:@"文件路径不对"];
            }
            return;
        }
        
        self.videoInfo = [[PPUploadFileData alloc] init];
        self.videoInfo.fileSize = [data length];
        self.videoInfo.assetURL = info.path;
        
        self.videoInfo.createDate = [NSDate date];
        self.videoInfo.status = UPStatusWait;
        self.videoInfo.progress = UPProgressCreateFile;
        self.videoInfo.uploadPath = @"%2F";
        self.videoInfo.isStartUploaded = YES;
        //视频信息
        self.videoInfo.path = info.path;
        self.videoInfo.isLocalCacheVideo = info.isLocalCacheVideo;
        self.videoInfo.width = info.width;
        self.videoInfo.height = info.height;
        self.videoInfo.bitrate = info.bitrate;
        self.videoInfo.framerate = info.framerate;
        self.videoInfo.duration = info.duration;
        
        if ([info.title length]) {
            self.videoInfo.fileName = info.title;
        }
        if ([info.detail length]) {
            self.videoInfo.introduce = info.detail;
        }
        
        [[PPFileUploadManager sharedFileUploadManager] upgradeFileProperty:self.videoInfo];
        
        //添加到新的上传文件
        if ([[PPFileUploadManager sharedFileUploadManager] addNewUploadFile:self.videoInfo]) {
            if (self.uploadDelegate && [self.uploadDelegate respondsToSelector:@selector(getVideoInfoSuccess)]) {
                [self.uploadDelegate getVideoInfoSuccess];
            }
        } else {
            //允许重复添加文件
            NSLog(@"重复添加已存在的文件");
        }
    }
    else {
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
        [assetsLibrary assetForURL:[NSURL URLWithString:info.path] resultBlock:^(ALAsset *result) {
            NSString* assetType = [result valueForProperty:ALAssetPropertyType];
            if([assetType isEqualToString:ALAssetTypeVideo])
            {
                ALAssetRepresentation *assertRepresentation = [result defaultRepresentation];
                //UIImage *fileImg = [[UIImage alloc] initWithCGImage:[assertRepresentation fullScreenImage]];
                //self.previewImage.image = fileImg;
                self.videoInfo = [[PPUploadFileData alloc] init];
                self.videoInfo.fileSize = [assertRepresentation size];
                self.videoInfo.assetURL = info.path;
                
                self.videoInfo.createDate = [NSDate date];
                self.videoInfo.status = UPStatusWait;
                self.videoInfo.progress = UPProgressCreateFile;
                self.videoInfo.uploadPath = @"%2F";
                self.videoInfo.isStartUploaded = YES;
                //视频信息
                self.videoInfo.isLocalCacheVideo = info.isLocalCacheVideo;
                self.videoInfo.width = info.width;
                self.videoInfo.height = info.height;
                self.videoInfo.bitrate = info.bitrate;
                self.videoInfo.framerate = info.framerate;
                self.videoInfo.duration = info.duration;
                
                if ([info.title length]) {
                    self.videoInfo.fileName = info.title;
                }
                if ([info.detail length]) {
                    self.videoInfo.introduce = info.detail;
                }
                
                [[PPFileUploadManager sharedFileUploadManager] upgradeFileProperty:self.videoInfo];
                
                //添加到新的上传文件
                if ([[PPFileUploadManager sharedFileUploadManager] addNewUploadFile:self.videoInfo]) {
                    if (self.uploadDelegate && [self.uploadDelegate respondsToSelector:@selector(getVideoInfoSuccess)]) {
                        [self.uploadDelegate getVideoInfoSuccess];
                    }
                } else {
                    //允许重复添加文件
                    NSLog(@"重复添加已存在的文件");
                }
            }
            
        } failureBlock:^(NSError *error) {
            if (self.uploadDelegate && [self.uploadDelegate respondsToSelector:@selector(getVideoInfoFailed:)]) {
                [self.uploadDelegate getVideoInfoFailed:@"文件路径不对"];
            }
        }];
    }
}

#pragma mark - 删除tmp目录下的.MOV文件
- (void)deleteTmpFolderVideo
{
    NSArray *fileList = [[NSFileManager defaultManager] subpathsOfDirectoryAtPath:NSTemporaryDirectory() error:nil];
    
    for (NSString *filePath in fileList) {
        if ([filePath containsString:@"MOV"]) {
            NSString *fullPath = [NSString stringWithFormat:@"%@/%@",NSTemporaryDirectory(), filePath];
            [[NSFileManager defaultManager] removeItemAtPath:fullPath error:nil];
        }
    }
}

@end

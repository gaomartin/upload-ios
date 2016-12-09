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

- (instancetype)initWithDomainName:(NSString *)domainName
{
    if (self = [super init])
    {
        [BZUserModel sharedBZUserModel].domainName = domainName;
        
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

- (void)startUploadFileWithPath:(NSString *)path
                          title:(NSString *)title
                         detail:(NSString *)detail
{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    [assetsLibrary assetForURL:[NSURL URLWithString:path] resultBlock:^(ALAsset *result) {
        NSString* assetType = [result valueForProperty:ALAssetPropertyType];
        if([assetType isEqualToString:ALAssetTypeVideo])
        {
            ALAssetRepresentation *assertRepresentation = [result defaultRepresentation];
            UIImage *fileImg = [[UIImage alloc] initWithCGImage:[assertRepresentation fullScreenImage]];
            //self.previewImage.image = fileImg;
            self.videoInfo = [[PPUploadFileData alloc] init];
            self.videoInfo.fileSize = [assertRepresentation size];
            self.videoInfo.fileImage = fileImg;
            self.videoInfo.assetURL = path;
            
            self.videoInfo.createDate = [NSDate date];
            self.videoInfo.status = UPStatusWait;
            self.videoInfo.progress = UPProgressCreateFile;
            self.videoInfo.uploadPath = @"%2F";
            self.videoInfo.isStartUploaded = YES;
            
            if ([title length]) {
                self.videoInfo.fileName = title;
            }
            if ([detail length]) {
                self.videoInfo.introduce = detail;
            }
            
            [[PPFileUploadManager sharedFileUploadManager] upgradeFileProperty:self.videoInfo];
            
            //添加到新的上传文件
            if ([[PPFileUploadManager sharedFileUploadManager] addNewUploadFile:self.videoInfo]) {
                if (self.uploadDelegate && [self.uploadDelegate respondsToSelector:@selector(getVideoInfoSuccess)]) {
                    [self.uploadDelegate getVideoInfoSuccess];
                }
            } else {
                if (self.uploadDelegate && [self.uploadDelegate respondsToSelector:@selector(getVideoInfoFailed:)]) {
                    [self.uploadDelegate getVideoInfoFailed:@"添加文件失败, 此文件已在上传列表中!"];
                }
            }
        }
        
    } failureBlock:^(NSError *error) {
        if (self.uploadDelegate && [self.uploadDelegate respondsToSelector:@selector(getVideoInfoFailed:)]) {
            [self.uploadDelegate getVideoInfoFailed:@"文件路径不对"];
        }
    }];
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

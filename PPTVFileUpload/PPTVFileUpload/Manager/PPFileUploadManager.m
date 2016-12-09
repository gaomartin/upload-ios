//
//  PPFileUploadManager.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/8/1.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "PPFileUploadManager.h"
#import "PPUploadRequest.h"

#define PPTVAllUploadFiles @"PPTVAllUploadFiles"

/** 上传队列的串行队列 */
static dispatch_queue_t dispatch_get_uploading_queue(){
    static dispatch_queue_t uploadingQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        uploadingQueue = dispatch_queue_create("com.pptvsdk.uploadingQueue", DISPATCH_QUEUE_SERIAL);
    });
    return uploadingQueue;
}

@interface PPFileUploadManager ()<PPUploadRequestDelegate>

@property(nonatomic, strong) NSMutableArray        *allUploadFiles;       //所有文件队列
@property(nonatomic, strong) NSMutableArray        *uploadingQueue;       //文件正在上传队列
@property(nonatomic, strong) NSMutableDictionary   *uploadingDelegateMap; //上传操作代理映射

@property(nonatomic, assign) int                concurrentTaskNumber;      //并行任务数量
@property(nonatomic, strong) PPUploadRequest    *protocolRequest;          //协议请求
@property(nonatomic, assign) UIBackgroundTaskIdentifier backgroundIdentifier;

/** 用于轮训检查上传任务和进度更新操作 */
- (void)checkUploadingQueueStatus:(NSNotification *)notif;

//对正在上传文件队列添加和删除操作
- (BOOL)enqueueUploadingFile:(PPUploadFileData *)uploadFile;
- (BOOL)dequeueUploadingFile:(PPUploadFileData *)uploadFile;

@end

@implementation PPFileUploadManager

+ (instancetype)sharedFileUploadManager
{
    static PPFileUploadManager *fileManager = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        fileManager = [[PPFileUploadManager alloc] init];
    });
    
    return fileManager;
}

- (instancetype)init
{
    if (self = [super init]) {
        self.allUploadFiles = [NSMutableArray array];
        _uploadingQueue = [NSMutableArray array];
        _uploadingDelegateMap = [NSMutableDictionary dictionary];
        _protocolRequest  = [[PPUploadRequest alloc] init];
        
        //判断是否支持多任务
        if ([[UIDevice currentDevice] isMultitaskingSupported]) {
            _concurrentTaskNumber = MAX_CONCURRENT_TASK_NUMBER;//默认最大并行任务数
        }else{
            _concurrentTaskNumber = MIN_CONCURRENT_TASK_NUMBER;//默认最小并行任务数
        }
    }
    
    return self;
}

#pragma mark -- notification observer
/** 添加通知观察 */
- (void) addNotificationObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkUploadingQueueStatus:) name:FileUploadingCheckNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(gointoBackgroud) name:UIApplicationDidEnterBackgroundNotification object:nil];
}

/** 删除通知观察 */
- (void) removeNotificationObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)postNotification:(NSString *)aNoti
{
    [[NSNotificationCenter defaultCenter] postNotificationName:aNoti object:nil];
}

#pragma mark -- 文件操作
- (BOOL)enqueueUploadingFile:(PPUploadFileData *)uploadFile
{
    //只有满足未完成且没有出错的上传操作才可以执行上传操作
    if (uploadFile && uploadFile.status != UPStatusUploadFinish && uploadFile.status != UPStatusError) {
        PPUploadRequest *request =  [self.uploadingDelegateMap objectForKey:[uploadFile fileIdentifier]];
        
        if (!request) {
            request =  [[PPUploadRequest alloc] init];
            request.delegate = self;
            [self.uploadingDelegateMap setObject:request forKey:[uploadFile fileIdentifier]];
            [self.uploadingQueue addObject:uploadFile];
            NSLog(@"enqueueUploadingFile [%@]",[uploadFile fileIdentifier]);
        }
        
        switch (uploadFile.progress) {
            case UPProgressCreateFile:
            {
                [request createFileWithData:uploadFile];
            }
                break;
                
            case UPProgressSubmitMD5:
            {
                uploadFile.status = UPStatusUploading;
                [request submitMD5WithData:uploadFile];
            }
                break;
                
            case UPProgressUploading:
            {
                uploadFile.status = UPStatusUploading;
                [request uploadingFileWithData:uploadFile];
            }
                break;
                
            case UPProgressWaiting:
            {
                uploadFile.status = UPStatusUploading;
                uploadFile.progress = UPProgressUploading;
                [request uploadingFileWithData:uploadFile];
            }
                break;
                
            case UPProgressComplete:
            {
                uploadFile.status = UPStatusUploadFinish;
                uploadFile.progress = UPProgressComplete;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([self.delegate respondsToSelector:@selector(uploadingFileStatusChange)]) {
                        [self.delegate uploadingFileStatusChange];
                    }
                });
            }
                break;
                
            default:
                break;
        }
        return YES;
    }
    return NO;
}

- (BOOL)dequeueUploadingFile:(PPUploadFileData *)uploadFile
{
    if (uploadFile) {
        //取消所有的数据请求
        PPUploadRequest *request =  [self.uploadingDelegateMap objectForKey:[uploadFile fileIdentifier]];
        if (request) {
            [request.operationQueue cancelAllOperations];
            request.delegate = nil;
            [self.uploadingQueue removeObject:uploadFile];
            [self.uploadingDelegateMap removeObjectForKey:[uploadFile fileIdentifier]];
            NSLog(@"dequeueUploadingFile [%@]",[uploadFile fileIdentifier]);
            return YES;
        }
    }
    return NO;
}

- (BOOL)addNewUploadFile:(PPUploadFileData *)uploadFile
{
    if (uploadFile) {
        NSLog(@"add new upload file[%@]",[uploadFile fileIdentifier]);
        
        BOOL isNeedAdd = YES;
        for (PPUploadFileData *fileData in self.allUploadFiles) {
            NSLog(@"fileData =%@, uploadFile=%@",[fileData fileIdentifier], [uploadFile fileIdentifier]);
            if ([[fileData fileIdentifier] isEqualToString:[uploadFile fileIdentifier]]) {
                isNeedAdd = NO;
            }
        }
        
        if (isNeedAdd) {
            [self.allUploadFiles addObject:uploadFile];
            
            [self enqueueUploadingFile:uploadFile];
            
            [self updateToDBWith:uploadFile];
            
            return YES;
        }
    }
    return NO;
}

- (void)upgradeFileProperty:(PPUploadFileData *)uploadFile
{
    if (uploadFile) {
        for (PPUploadFileData *file in self.allUploadFiles) {
            if ([[file fileIdentifier] isEqualToString:[uploadFile fileIdentifier]]) {
                NSLog(@"old file = %@ , new File = %@",file,uploadFile);
                file.fileName = uploadFile.fileName;
                file.fileSize = uploadFile.fileSize;
                file.introduce = uploadFile.introduce;
                break;
            }
        }
    }
}

- (void)removeUploadFile:(PPUploadFileData *)uploadFile
{
    if (uploadFile) {
        [self.allUploadFiles removeObject:uploadFile];
        [self dequeueUploadingFile:uploadFile];
        [self updateToDBWith:uploadFile];
    }
    
    NSLog(@"removeUploadFile");
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self.delegate respondsToSelector:@selector(uploadingFileStatusChange)]) {
            [self.delegate uploadingFileStatusChange];
        }
    });
}

- (void)loadAllUploadFilesFromLocal
{
    [self.allUploadFiles removeAllObjects];
    [self.uploadingQueue removeAllObjects];
    [self.uploadingDelegateMap removeAllObjects];
    
    [self getAllFileData];
    
    //把非完成状态的文件修改为正常状态
    for (PPUploadFileData *uploadFile in self.allUploadFiles) {
        if(uploadFile.status != UPStatusUploadFinish){
            uploadFile.status = UPStatusNormal;
        }
    }
    
    [self addNotificationObserver];
}

- (void)releaseAllUploadFiles
{
    [self removeNotificationObserver];
    //取消所有的网络请求
    for (PPUploadFileData *uploadFile in self.uploadingQueue) {
        PPUploadRequest *request =  [self.uploadingDelegateMap objectForKey:[uploadFile fileIdentifier]];
        [request.operationQueue cancelAllOperations];
        [self.uploadingDelegateMap removeObjectForKey:[uploadFile fileIdentifier]];
    }
    for (PPUploadFileData *uploadFile in self.allUploadFiles) {
        //只要不是完成状态的话就都设置
        if (uploadFile.status != UPStatusUploadFinish) {
            uploadFile.status = UPStatusNormal;
        }
        [self updateToDBWith:uploadFile];
    }
    
    [self.allUploadFiles removeAllObjects];
    [self.uploadingQueue removeAllObjects];
    [self.uploadingDelegateMap removeAllObjects];
}

- (void)cancelAllUploadingFiles
{
    for (PPUploadFileData *uploadFile in self.uploadingQueue) {
        uploadFile.status = UPStatusPause;
        PPUploadRequest *request =  [self.uploadingDelegateMap objectForKey:[uploadFile fileIdentifier]];
        [request.operationQueue cancelAllOperations];
        [self.uploadingDelegateMap removeObjectForKey:[uploadFile fileIdentifier]];
    }
    NSLog(@"cancelAllUploadingFiles");
    [self postNotification:FileUploadingCheckNotification];
}

- (void)changeUploadingFile:(PPUploadFileData *)uploadFile toStatus:(UploadStatus)status
{
    if (!uploadFile) {
        return;
    }
    
    if (status == UPStatusNormal || status == UPStatusPause || status == UPStatusWait) {
        //如果当文件上传队列包含该文件上传操作的话
        uploadFile.status = status;
        if (status == UPStatusPause) {
            [self dequeueUploadingFile:uploadFile];
        }
    }
    NSLog(@"changeUploadingFile toStatus: %zd", status);
    [self postNotification:FileUploadingCheckNotification];
}

- (NSMutableArray *)currentAllUploadFiles
{
    if (self.allUploadFiles.count > 0) {
        return self.allUploadFiles;
    }
    
    [self getAllFileData];
    
    return self.allUploadFiles;
}

#pragma mark -- 上传任务检查

- (void)checkUploadingQueueStatus:(NSNotification *)notif
{
    //使用异步串行队列检查上传人物状态
    dispatch_async(dispatch_get_uploading_queue(), ^{
        for (PPUploadFileData *uploadFile in self.allUploadFiles) {
            if (uploadFile) {
                NSLog(@"check uploading queue status methods, upload file:[%@]",[uploadFile fileIdentifier]);
                NSLog(@"upload file status : %zd",[uploadFile status]);
                if (uploadFile.status == UPStatusWait) {//把所有处于等待状态的文件入队列
                    if (self.uploadingQueue.count <= self.concurrentTaskNumber) {
                        [self enqueueUploadingFile:uploadFile];
                    }
                } else if (uploadFile.status == UPStatusUploadFinish
                          || uploadFile.status == UPStatusError) {
                    //所有都成功或者出示失败的情况下出队列
                    [self dequeueUploadingFile:uploadFile];
                }
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.delegate respondsToSelector:@selector(uploadingFileStatusChange)]) {
                [self.delegate uploadingFileStatusChange];
            }
        });
    });
}

- (void)gointoBackgroud
{
    //请求后台执行
    [[UIApplication sharedApplication] endBackgroundTask:self.backgroundIdentifier];
    self.backgroundIdentifier = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        
    }];
}

#pragma mark -- PPUploadRequestDelegate

- (void)createFileComplete:(PPUploadFileData*)fileData
{
    [self updateToDBWith:fileData];
    if (fileData.status != UPStatusError) {
        PPUploadRequest *request = [self.uploadingDelegateMap objectForKey:[fileData fileIdentifier]];
        [request submitMD5WithData:fileData];
    }
    
    NSLog(@"createFileComplete fid");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FileUploadingCheckNotification object:fileData];
    });
}

- (void)submitMD5Complete:(PPUploadFileData*)fileData
{
    [self updateToDBWith:fileData];
    if (fileData.status != UPStatusError) {
        PPUploadRequest *request = [self.uploadingDelegateMap objectForKey:[fileData fileIdentifier]];
         [request uploadingFileWithData:fileData];
    }
    
    NSLog(@"submitMD5Complete");
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FileUploadingCheckNotification object:fileData];
    });
}

- (void)uploadingFileComplete:(PPUploadFileData*)fileData
{
    [self updateToDBWith:fileData];
    if (fileData) {
        PPUploadRequest *request = [self.uploadingDelegateMap objectForKey:[fileData fileIdentifier]];
        if(fileData.status == UPStatusUploading){
            //当状态为正在上传的状态的话,继续执行上传操作
            [request uploadingFileWithData:fileData];
        }
    }
    
    NSLog(@"uploadingFileComplete fileData.status = %zd", fileData.status);
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:FileUploadingCheckNotification object:fileData];
    });
}

#pragma mark - NSUserDefault

- (void)getAllFileData
{
    //获取所有的上传文件数据
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([[defaults dictionaryRepresentation].allKeys containsObject:PPTVAllUploadFiles]) {
        // unarchive the value here
        NSData *fileData = [defaults objectForKey:PPTVAllUploadFiles];
        NSLog(@"allUploadFiles NSUserDefaults fileData = %.2fk, %fM",[fileData length] / 1024.0, [fileData length] / (1024.0*1024.0));
        NSArray *uploadDBArray = [NSKeyedUnarchiver unarchiveObjectWithData:fileData];
        
        [self.allUploadFiles addObjectsFromArray:uploadDBArray];
    }
}

- (void)updateToDBWith:(PPUploadFileData *)fileData
{
    [self upgradeFileProperty:fileData];
    
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.allUploadFiles];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:data forKey:PPTVAllUploadFiles];
    [defaults synchronize];
}

@end

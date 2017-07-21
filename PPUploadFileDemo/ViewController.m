//
//  ViewController.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/27.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "ViewController.h"

#import <MobileCoreServices/MobileCoreServices.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "VideoStatusTableViewCell.h"

#import <PPTVFileUpload/PPTVFileUpload.h>

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, PPTVUploadDelegate, UploadTableViewCellDelegate>

@property (nonatomic, strong) PPTVFileUpload *fileUpload;
@property (nonatomic, strong) NSString *filePath;
@property (nonatomic, strong) IBOutlet UILabel *videoPathLabel;
@property (nonatomic, strong) IBOutlet UILabel *videoSizeLabel;

@property (nonatomic, weak) IBOutlet UITextField *fileTitle;
@property (nonatomic, weak) IBOutlet UITextField *fileDetail;

@property (nonatomic, weak) IBOutlet UITableView *uploadTableView;//table视图
@property (nonatomic, strong) NSMutableArray *uploadList;//上传列表
@property (nonatomic, assign) long long fileSize;
@property (nonatomic, assign) BOOL isLocalCacheVideo;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.fileUpload = [[PPTVFileUpload alloc] initWithDomainName:@"http://115.231.44.26:8081/uploadtest/uptoken" andCookie:@""];
    self.fileUpload.uploadDelegate = self;
    
    [self uploadFileStatusChange];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//打开相册
- (IBAction)pickVideoFromAlbum:(UIButton *)button
{
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    imagePicker.allowsEditing = YES;
    
    [imagePicker setMediaTypes:[NSArray arrayWithObjects:(NSString *)kUTTypeMovie,nil]];
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}
// 打开摄像头
- (IBAction)openCamera
{
    // UIImagePickerControllerCameraDeviceRear 后置摄像头
    // UIImagePickerControllerCameraDeviceFront 前置摄像头
    BOOL isCamera = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear];
    if (!isCamera) {
       isCamera = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.delegate = self;
    
    [imagePicker setMediaTypes:[NSArray arrayWithObjects:(NSString *)kUTTypeMovie,nil]];
    // 编辑模式
    imagePicker.allowsEditing = YES;
    
    [self  presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)selectLocalVideo
{
    self.isLocalCacheVideo = YES;
    self.filePath = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"mp4"];
    self.videoPathLabel.text = self.filePath;
    [self startUploadVideo:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //ALAssetsLibrary 获取图片和视频
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    
    NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
    
    if (url){//本地视频
        [assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            NSString *videoPath = [NSString stringWithFormat:@"%@", rep.url];
            self.videoPathLabel.text = videoPath;
            self.filePath = videoPath;
            self.fileSize =  rep.size;
            
            NSLog(@"self.fileSize=%lld, %.2fM", self.fileSize, self.fileSize / (1024.0*1024.0));
            self.videoSizeLabel.text = [NSString stringWithFormat:@"%.2f M", self.fileSize / (1024.0*1024.0)];
        } failureBlock:nil];
    } else {//拍摄视频
        url = [info objectForKey:UIImagePickerControllerMediaURL];
        NSData *fileData = [NSData dataWithContentsOfFile:[url path]];
        self.fileSize = [fileData length];
        NSLog(@"self.fileSize=%lld, %.2fM", self.fileSize, self.fileSize / (1024.0*1024.0));
        self.videoSizeLabel.text = [NSString stringWithFormat:@"%.2f M", self.fileSize / (1024.0*1024.0)];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeVideoAtPathToSavedPhotosAlbum:url
                                    completionBlock:^(NSURL *assetURL, NSError *error) {
                                        if (error) {
                                            NSLog(@"Save video fail:%@",error);
                                        } else {
                                            NSLog(@"Save video succeed.");
                                            self.videoPathLabel.text = [NSString stringWithFormat:@"%@",assetURL];
                                            self.filePath = [assetURL absoluteString];
                                        }
                                    }];
    }
    
    NSLog(@"picker.videoQuality=%zd",picker.videoQuality);
    self.isLocalCacheVideo = NO;
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)startUploadVideo:(id)sender
{
    if (![self.filePath length]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tips" message:@"请先选择视频或者拍摄一段视频" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    //ios选择本地视频后, 会自动压缩
    //测试环境的swift配置有问题， 小于1M的无法提交成功
    if (self.fileSize < 1024*1024 && !self.isLocalCacheVideo) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tips" message:@"测试环境的swift配置有问题， 小于1M的无法提交成功" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSString *title = [NSString stringWithFormat:@"iosUploadTest%zd",self.fileSize];//主要是为了防止重名, 方便测试
    if ([self.fileTitle.text length]) {
        title = self.fileTitle.text;
    }
    
    
    PPVideoInfo *info = [[PPVideoInfo alloc] init];
    info.path = self.filePath;
    info.title = title;
    info.detail = self.fileDetail.text;
    info.isLocalCacheVideo = self.isLocalCacheVideo;
    
    [self.fileUpload startUploadFileWithVideoInfo:info];
    
    self.fileTitle.text = @"";
    self.fileDetail.text = @"";
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField;
{
    [self.fileTitle resignFirstResponder];
    [self.fileDetail resignFirstResponder];
    
    return YES;
}

#pragma mark - PPTVUploadDelegate
//提交节目信息
- (void)getVideoInfoSuccess
{
    NSLog(@"getVideoInfoSuccess");
}

- (void)getVideoInfoFailed:(NSString *)message
{
    NSLog(@"getVideoInfoFailed = %@",message);
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Tips" message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

- (void)uploadFileStatusChange
{
    NSLog(@"uploadFileStatusChange");
    NSMutableArray *array = [NSMutableArray arrayWithArray: self.fileUpload.allUploadFiles];
    self.uploadList = [NSMutableArray arrayWithArray:[[array reverseObjectEnumerator] allObjects]];//reverse数组位置, 为了tableview 上面显示最新的数据
    [self.uploadTableView reloadData];
}

#pragma mark - tableview

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.uploadList count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    VideoStatusTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (!cell) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"VideoStatusTableViewCell" owner:nil options:nil] objectAtIndex:0];
        cell.backgroundColor = [UIColor clearColor];
    }
    
    PPUploadFileData *fileData = [self.uploadList objectAtIndex:indexPath.row];
    cell.cellTag = indexPath.row;
    cell.delegate = self;
    [cell showUploadFileInfo:fileData];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}


#pragma mark-- UploadTableViewCellDelegate  Methods
- (void)pauseOrContinueAction:(NSInteger)position
{
    PPUploadFileData *uploadFile = [self.uploadList objectAtIndex:position];
    //处于等待或者上传状态的话就设置为暂停状态
    if (uploadFile.status == UPStatusWait || uploadFile.status == UPStatusUploading) {
        [self.fileUpload changeUploadingFile:uploadFile toStatus:UPStatusPause];
    }
    //处于暂停或者正常状态的话就设置为等待状态
    else if(uploadFile.status == UPStatusPause || uploadFile.status == UPStatusNormal){
        [self.fileUpload changeUploadingFile:uploadFile toStatus:UPStatusWait];
    }
}

- (void)cancelAction:(NSInteger)position
{
    PPUploadFileData *uploadFile = [self.uploadList objectAtIndex:position];
    [self.fileUpload removeUploadFile:uploadFile];
}

- (void)reUploadAction:(NSInteger)position
{
    PPUploadFileData *uploadFile = [self.uploadList objectAtIndex:position];
    [self.fileUpload changeUploadingFile:uploadFile toStatus:UPStatusWait];
}

@end

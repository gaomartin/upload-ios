//
//  ViewController.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/27.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "ViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "BZFidDataController.h"
#import "NSString+Hashes.h"
#import "PPUploadFileData.h"
#import "PPUploadHashTool.h"
#import "BZTokenDataController.h"
#import "BZUploadRangeDataController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "BZRangeInfo.h"
#import "BZFileUploadDataController.h"

@interface ViewController ()<UIImagePickerControllerDelegate, UINavigationControllerDelegate, BZDataControllerDelegate, PPUploadHashToolDelegate>

@property (nonatomic, strong) NSData *fileData;
@property (nonatomic, strong) IBOutlet UILabel *videoPathLabel;
@property (nonatomic, strong) BZFidDataController *fidDataController;
@property (nonatomic, strong) NSString *ppfeature;

@property (nonatomic, strong) PPUploadFileData *uploadFile;
@property (nonatomic, strong) PPUploadHashTool *uploadHashTool;
@property (nonatomic, strong) IBOutlet UILabel *ppfeatureLabel;
@property (nonatomic, strong) IBOutlet UILabel *fidInfoLabel;

@property (nonatomic, strong) BZTokenDataController *tokenDataController;
@property (nonatomic, strong) IBOutlet UILabel *tokenLabel;

@property (nonatomic, strong) BZUploadRangeDataController *uploadRangeDataController;
@property (nonatomic, strong) IBOutlet UILabel *rangesLabel;

@property (nonatomic, strong) BZFileUploadDataController *fileUploadDataController;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.uploadFile = [[PPUploadFileData alloc] init];
    self.uploadHashTool = [[PPUploadHashTool alloc] init];
    self.uploadHashTool.delegate = self;
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

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    //ALAssetsLibrary 获取图片和视频
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc]init];
    
    NSURL *url = [info objectForKey:UIImagePickerControllerReferenceURL];
    
    if (url){
        [assetLibrary assetForURL:url resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *rep = [asset defaultRepresentation];
            Byte *buffer = (Byte*)malloc((unsigned long)rep.size);
            NSUInteger buffered = [rep getBytes:buffer fromOffset:0.0 length:((unsigned long)rep.size) error:nil];
            self.fileData = [NSData dataWithBytesNoCopy:buffer length:buffered freeWhenDone:YES];
            
            NSURL* mediaURL = asset.defaultRepresentation.url;
            NSString *videoPath = [NSString stringWithFormat:@"%@",mediaURL];
            self.videoPathLabel.text = videoPath;
            self.uploadFile.assetURL = videoPath;
        } failureBlock:nil];
    } else {
        url = [info objectForKey:UIImagePickerControllerMediaURL];
        self.fileData = [NSData dataWithContentsOfFile:[url path]];
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeVideoAtPathToSavedPhotosAlbum:url
                                    completionBlock:^(NSURL *assetURL, NSError *error) {
                                        if (error) {
                                            NSLog(@"Save video fail:%@",error);
                                        } else {
                                            NSLog(@"Save video succeed.");
                                            self.videoPathLabel.text = [NSString stringWithFormat:@"%@",assetURL];
                                            self.uploadFile.assetURL = [NSString stringWithFormat:@"%@",assetURL];
                                            
                                            
                                        }
                                    }];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{}];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}


- (IBAction)createPPfeature:(id)sender
{
    [self.uploadHashTool computePPfeature: self.uploadFile];
}

- (void)requestFidInfo
{
    if (!self.fidDataController) {
        self.fidDataController = [[BZFidDataController alloc] initWithDelegate:self];
    }
    
    //apitk定义: apitk = MD5(key + url)
    NSString *apitk = [[NSString stringWithFormat:@"%@%@v1/api/channel/upload",[BZUserModel sharedBZUserModel].key,PPCLOUD_TEST_URL] md5];
    NSString *length = [NSString stringWithFormat:@"%zd",[self.fileData length]];
    
    if (![length integerValue]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"" message:@"请前往相册选择视频" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles: nil];
        [alert show];
        return;
    }
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                          [BZUserModel sharedBZUserModel].username,     @"username",
                          apitk,                                        @"apitk",
                          [BZUserModel sharedBZUserModel].categoryid,   @"categoryid",
                          @"videoTest",                                 @"name",
                          length,                                       @"length",
                          self.ppfeature,                               @"ppfeature",
                          nil];
    
    [self.fidDataController requestWithArgs:dict];
}

- (IBAction)requestTokenInfo
{
    if (!self.tokenDataController) {
        self.tokenDataController = [[BZTokenDataController alloc] initWithDelegate:self];
    }
    
    NSString *apitk = [[NSString stringWithFormat:@"%@%@v1/api/token/uptoken",[BZUserModel sharedBZUserModel].key, PPCLOUD_TEST_URL] md5];
    
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 [BZUserModel sharedBZUserModel].username,      @"username",
                                 apitk,                                         @"apitk",
                                 self.ppfeature,                                @"ppfeature",
                                 nil];
    [self.tokenDataController requestWithArgs:dict];
}

- (IBAction)requestUploadRange:(id)sender
{
    if (!self.uploadRangeDataController) {
        self.uploadRangeDataController = [[BZUploadRangeDataController alloc] initWithDelegate:self];
    }
    
    ///fsvc/3/file/{fid}/action/uploadrange?feature_pplive=1234567890abcdef&segs=3&fromcp=ppcloud&inner=false
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 self.ppfeature,    @"feature_pplive",
                                 @"3",              @"segs",
                                 @"ppcloud",        @"fromcp",
                                 @"false",          @"inner",
                                 nil];
    
    self.uploadRangeDataController.fid = self.fidDataController.fid;
    NSDictionary *headField = [NSDictionary dictionaryWithObjectsAndKeys:self.tokenDataController.token, @"Authorization", nil];
    self.uploadRangeDataController.headerField = headField;
    
    [self.uploadRangeDataController requestWithArgs:dict];
}

#pragma mark - BZDataController

//transcodeStatus > 200 表示秒传
//transcodeStatus  = 0, 转码, 就是需要上传
- (void)loadingDataFinished:(BZDataController *)controller
{
    if (controller == self.fidDataController) {
        self.fidInfoLabel.text = [NSString stringWithFormat:@"fid=%@, transcodeStatus=%zd",
                                  self.fidDataController.fid, self.fidDataController.transcodeStatus];
    } else if (controller == self.tokenDataController) {
        self.tokenLabel.text = self.tokenDataController.token;
    } else if (controller == self.uploadRangeDataController) {
        self.rangesLabel.text = [NSString stringWithFormat:@"ranges: %zd", [self.uploadRangeDataController.rangesList count]];
        [self startUploadFile];
    }
}

- (void)loadingData:(BZDataController *)controller failedWithError:(NSError *)error
{
    if (controller == self.fidDataController) {
        self.fidInfoLabel.text = @"fid获取失败";
    } else if (controller == self.tokenDataController) {
        self.tokenLabel.text = @"token获取失败";
        if ([self.tokenDataController.msg length]) {
            self.tokenLabel.text = self.tokenDataController.msg;
        }
    } else if (controller == self.uploadRangeDataController) {
         self.rangesLabel.text = @"ranges请求失败";
    }
    
}

- (void)getPPfeature:(NSString*)PPfeature fileData:(PPUploadFileData*)fileData
{
    NSLog(@"PPfeature=%@",PPfeature);
    self.ppfeature = PPfeature;
    self.ppfeatureLabel.text = PPfeature;
    [self requestFidInfo];
}

- (void)startUploadFile
{
    for (int i=0; i<[self.uploadRangeDataController.rangesList count]; i++) {
        BZRangeInfo *info = [self.uploadRangeDataController.rangesList objectAtIndex:i];
        NSData *data = [self.fileData subdataWithRange:NSMakeRange(info.start, info.end)];
        [self uploadFileWithUrl:info.upload_url andData:data];
    }
}

- (void)uploadFileWithUrl:(NSString *)upload_url andData:(NSData *)data
{
    if (!self.fileUploadDataController) {
        self.fileUploadDataController = [[BZFileUploadDataController alloc] initWithDelegate:self];
    }
    
    NSDictionary *headField = [NSDictionary dictionaryWithObjectsAndKeys:self.tokenDataController.token, @"Authorization", nil];
    self.fileUploadDataController.headerField = headField;
    self.fileUploadDataController.data = data;
    self.fileUploadDataController.fullUrl = [NSURL URLWithString:upload_url];
    [self.fileUploadDataController requestWithArgs:nil];
}


@end

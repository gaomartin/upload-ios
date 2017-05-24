//
//  VideoStatusTableViewCell.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/8/4.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "VideoStatusTableViewCell.h"
#import <PPTVFileUpload/PPTVFileUpload.h>

@interface VideoStatusTableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *videoTitleLabel;//视频标题
@property (weak, nonatomic) IBOutlet UILabel *uploadStateLabel;//上传状态
@property (weak, nonatomic) IBOutlet UILabel *createTimeLabel;//创建时间
@property (weak, nonatomic) IBOutlet UIProgressView *uploadProgressBar;//上传进度

@property (weak, nonatomic) IBOutlet UIButton *pauseOrContinueButton;//暂停和继续按钮
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;//取消按钮
@property (weak, nonatomic) IBOutlet UIButton *reUploadButton;//重新上传按钮
@property (weak, nonatomic) IBOutlet UIButton *completeButton;//完成按钮



@end

@implementation VideoStatusTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (IBAction)pauseOrContinueButtonClick:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(pauseOrContinueAction:)]) {
        [self.delegate pauseOrContinueAction:self.cellTag];
    }
    self.reUploadButton.hidden = YES;
}
- (IBAction)cancelButtonClick:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(cancelAction:)]) {
        [self.delegate cancelAction:self.cellTag];
    }
    self.reUploadButton.hidden = YES;
}
- (IBAction)reUploadButtonClick:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(reUploadAction:)]) {
        [self.delegate reUploadAction:self.cellTag];
    }
    self.pauseOrContinueButton.hidden = NO;
}

- (IBAction)completeButtonClick:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(completeAction:)]) {
        [self.delegate completeAction:self.cellTag];
    }
}

- (IBAction)shareButtonClick:(UIButton *)sender {
    if ([self.delegate respondsToSelector:@selector(shareProgramAction:)]) {
        [self.delegate shareProgramAction:self.cellTag];
    }
}

- (void)showUploadFileInfo:(PPUploadFileData *)fileData
{
    self.videoTitleLabel.text = fileData.fileName;
    self.uploadStateLabel.text = @"";
    
    self.createTimeLabel.text = [NSString stringWithFormat:@"%@创建",[self stringFromDate6: fileData.createDate]];
    //设置进度数据
    self.uploadProgressBar.hidden = NO;
    double progress = 0;
    if (fileData.fileSize > 0) {
        progress = (double)fileData.finished/fileData.fileSize;
    }
    self.uploadProgressBar.progress = progress;
    
    NSLog(@"uploadingFile progress = %f",progress);
    
    self.reUploadButton.hidden = YES;
    self.pauseOrContinueButton.hidden = YES;
    self.completeButton.hidden = YES;
    
    if (fileData) {
        //未开始
        if (!fileData.isStartUploaded) {
            self.uploadStateLabel.text = @"未开始";
        }else{
            switch (fileData.status) {
                case UPStatusNormal:
                    self.uploadStateLabel.text = @"未完成...";
                    self.pauseOrContinueButton.hidden = NO;
                    [self.pauseOrContinueButton setImage:[UIImage imageNamed:@"cloudplay"] forState:UIControlStateNormal];
                    break;
                case UPStatusWait:
                case UPStatusUploading:
                    self.uploadStateLabel.text = @"正在上传...";
                    self.pauseOrContinueButton.hidden = NO;
                    [self.pauseOrContinueButton setImage:[UIImage imageNamed:@"cloudpause"] forState:UIControlStateNormal];
                    break;
                case UPStatusError:
                    self.uploadStateLabel.text = @"上传失败";
                    self.reUploadButton.hidden = NO;
                    break;
                case UPStatusPause:
                    self.uploadStateLabel.text = @"暂停中";
                    self.pauseOrContinueButton.hidden = NO;
                    [self.pauseOrContinueButton setImage:[UIImage imageNamed:@"cloudplay"] forState:UIControlStateNormal];
                    break;
                case UPStatusUploadFinish:
                    self.uploadStateLabel.text = @"上传完成";
                    self.completeButton.hidden = NO;
                    break;
                    
                default:
                    break;
            }
        }
    }
    
    NSLog(@"createDate=%@, uploadingFile status = %@", fileData.createDate,self.uploadStateLabel.text);
}

- (NSString *)stringFromDate6:(NSDate *)date
{
    static NSDateFormatter *formatter = nil;
    
    if (!formatter) {
        @synchronized(self){
            formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"yyyy-MM-dd HH:mm"];
        }
    }
    return [formatter stringFromDate:date];
}

@end

//
//  VideoStatusTableViewCell.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/8/4.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol UploadTableViewCellDelegate <NSObject>

@optional
- (void)pauseOrContinueAction:(NSInteger ) position;
- (void)cancelAction:(NSInteger) position;
- (void)reUploadAction:(NSInteger) position;
- (void)shareProgramAction:(NSInteger ) position;
- (void)completeAction:(NSInteger) position;

@end


@class PPUploadFileData;

@interface VideoStatusTableViewCell : UITableViewCell

@property (weak, nonatomic) id <UploadTableViewCellDelegate>delegate;

@property (nonatomic, assign) NSInteger cellTag;

- (void)showUploadFileInfo:(PPUploadFileData *)fileData;

@end

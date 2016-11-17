//
//  BZUploadRangeDataController.h
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/28.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "BZDataController.h"

@interface BZUploadRangeDataController : BZDataController

@property (nonatomic, strong) NSString *fid;
@property (nonatomic, strong) NSDictionary *headerField;
@property (nonatomic, strong) NSMutableArray *rangesList;

@end

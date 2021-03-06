//
//  PPUploadFileData.m
//  PPUploadFileDemo
//
//  Created by bobzhang on 16/7/27.
//  Copyright © 2016年 bobzhang. All rights reserved.
//

#import "PPUploadFileData.h"

@implementation PPUploadFileData

- (NSString *)fileIdentifier
{
    return [NSString stringWithFormat:@"%lld_%@",self.fileSize,self.assetURL];
}

- (NSString *)fileIdentifierForLog
{
    return [NSString stringWithFormat:@"file(%@_%lld)",self.fileName, self.fileSize];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [self init];
    
    if(self)
    {
        self.assetURL           = [decoder decodeObjectForKey:@"assetURL"];
        self.file_status        = [decoder decodeIntegerForKey:@"file_status"];
        self.ppfeature          = [decoder decodeObjectForKey:@"ppfeature"];
        self.channelWebId       = [decoder decodeObjectForKey:@"channelWebId"];
        self.categoryId         = [decoder decodeIntegerForKey:@"categoryId"];
        self.categoryName       = [decoder decodeObjectForKey:@"categoryName"];
        self.fileName           = [decoder decodeObjectForKey:@"fileName"];
        self.introduce          = [decoder decodeObjectForKey:@"introduce"];
        self.errorMsg           = [decoder decodeObjectForKey:@"errorMsg"];
        self.uploadPath         = [decoder decodeObjectForKey:@"uploadPath"];
        
        self.md5                = [decoder decodeObjectForKey:@"md5"];
        self.dcid               = [decoder decodeObjectForKey:@"dcid"];
        self.gcid               = [decoder decodeObjectForKey:@"gcid"];
        self.pid                = [decoder decodeObjectForKey:@"pid"];
        self.cid                = [decoder decodeObjectForKey:@"cid"];
        self.uploadID           = [decoder decodeObjectForKey:@"uploadID"];
        self.createDate         = [decoder decodeObjectForKey:@"createDate"];
        
        self.isStartUploaded    = [decoder decodeBoolForKey:@"isStartUploaded"];
        self.fid                = [decoder decodeObjectForKey:@"fid"];
        self.fileSize           = [decoder decodeDoubleForKey:@"fileSize"];
        self.token              = [decoder decodeObjectForKey:@"token"];
        self.finishedSize       = [decoder decodeDoubleForKey:@"finishedSize"];
        self.progress           = [decoder decodeIntegerForKey:@"progress"];
        self.status             = [decoder decodeIntegerForKey:@"status"];
        self.fileIdentifier     = [decoder decodeObjectForKey:@"fileIdentifier"];
        self.fileIdentifierForLog     = [decoder decodeObjectForKey:@"fileIdentifierForLog"];
        self.user_id            = [decoder decodeObjectForKey:@"user_id"];
        self.errorCode          = [decoder decodeIntegerForKey:@"errorCode"];
    }
    
    return  self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.assetURL forKey:@"assetURL"];
    [encoder encodeInteger:self.file_status forKey:@"file_status"];
    [encoder encodeObject:self.ppfeature forKey:@"ppfeature"];
    [encoder encodeObject:self.channelWebId forKey:@"channelWebId"];
    [encoder encodeInteger:self.categoryId forKey:@"categoryId"];
    [encoder encodeObject:self.categoryName forKey:@"categoryName"];
    [encoder encodeObject:self.fileName forKey:@"fileName"];
    [encoder encodeObject:self.introduce forKey:@"introduce"];
    [encoder encodeObject:self.errorMsg forKey:@"errorMsg"];
    [encoder encodeObject:self.uploadPath forKey:@"uploadPath"];
    
    [encoder encodeObject:self.md5 forKey:@"md5"];
    [encoder encodeObject:self.dcid forKey:@"dcid"];
    [encoder encodeObject:self.gcid forKey:@"gcid"];
    [encoder encodeObject:self.pid forKey:@"pid"];
    [encoder encodeObject:self.cid forKey:@"cid"];
    [encoder encodeObject:self.uploadID forKey:@"uploadID"];
    [encoder encodeObject:self.createDate forKey:@"createDate"];
    
    [encoder encodeBool:self.isStartUploaded forKey:@"isStartUploaded"];
    [encoder encodeObject:self.fid forKey:@"fid"];
    [encoder encodeDouble:self.fileSize forKey:@"fileSize"];
    [encoder encodeObject:self.token forKey:@"token"];
    [encoder encodeDouble:self.finishedSize forKey:@"finishedSize"];
    [encoder encodeInteger:self.progress forKey:@"progress"];
    [encoder encodeInteger:self.status forKey:@"status"];
    [encoder encodeObject:self.fileIdentifier forKey:@"fileIdentifier"];
    [encoder encodeObject:self.fileIdentifierForLog forKey:@"fileIdentifierForLog"];
    
    [encoder encodeObject:self.user_id forKey:@"user_id"];
    [encoder encodeInteger:self.errorCode forKey:@"errorCode"];
}

@end

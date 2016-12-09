//
//  PPUploadHashTool.m
//  PPCloudPlay_iphone
//
//  Created by stephenzhang on 14-3-25.
//  Copyright (c) 2014年 PPTV. All rights reserved.
//

#import "PPUploadFileData.h"
#import "PPUploadHashTool.h"
#import <CommonCrypto/CommonDigest.h>
#import <AssetsLibrary/AssetsLibrary.h>

@implementation FileBlock

@end

@implementation PPUploadHashTool

- (NSString *)SHA1Hash:(Byte *)data bufferSize:(int)size
{
    uint8_t digest[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(data, size, digest);
    NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}

//计算PPfeature
- (void)computePPfeature:(PPUploadFileData*)fileData
{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    [assetsLibrary assetForURL:[NSURL URLWithString:fileData.assetURL] resultBlock:^(ALAsset *asset)
     {
         NSString* sha1String = nil;
         Byte buffer[61440];
         NSUInteger bytesRead = 0;
         long long offset = 0;
         long long length = [[asset defaultRepresentation] size];
         if(length < 65535)
         {
             bytesRead = [[asset defaultRepresentation] getBytes:buffer fromOffset:offset length:(NSUInteger)length error:nil];
             sha1String = [self SHA1Hash:buffer bufferSize:(int)length];
         } else {
             bytesRead = [[asset defaultRepresentation] getBytes:buffer fromOffset:offset length:12288 error:nil];
             offset = length/5;
             bytesRead = [[asset defaultRepresentation] getBytes:(buffer+12288) fromOffset:offset length:12288 error:nil];
             offset = 2*length/5;
             bytesRead = [[asset defaultRepresentation] getBytes:(buffer+24576) fromOffset:offset length:12288 error:nil];
             offset = 3*length/5;
             bytesRead = [[asset defaultRepresentation] getBytes:(buffer+36864) fromOffset:offset length:12288 error:nil];
             offset = length - 12288;
             bytesRead = [[asset defaultRepresentation] getBytes:(buffer+49152) fromOffset:offset length:12288 error:nil];
             
             sha1String = [self SHA1Hash:buffer bufferSize:61440];
         }
         NSString *output = [NSString stringWithFormat:@"%lld_%@",length,sha1String];
         fileData.ppfeature = output;
         [self.delegate getPPfeature:output fileData:fileData];
     } failureBlock:^(NSError *error){}];
}

//计算dcid
- (void)computeDcid:(PPUploadFileData*)fileData
{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    [assetsLibrary assetForURL:[NSURL URLWithString:fileData.assetURL] resultBlock:^(ALAsset *asset)
     {
         NSString* sha1String = nil;
         Byte buffer[12288];
         NSUInteger bytesRead = 0;
         long long offset = 0;
         long long length = [[asset defaultRepresentation] size];
         if(length < 12288)
         {
             bytesRead = [[asset defaultRepresentation] getBytes:buffer fromOffset:offset length:(NSUInteger)length error:nil];
             sha1String = [self SHA1Hash:buffer bufferSize:(int)length];
         }else
         {
             bytesRead = [[asset defaultRepresentation] getBytes:buffer fromOffset:offset length:4096 error:nil];
             offset = length/3;
             bytesRead = [[asset defaultRepresentation] getBytes:(buffer+4096) fromOffset:offset length:4096 error:nil];
             offset = length-4096;
             bytesRead = [[asset defaultRepresentation] getBytes:(buffer+8192) fromOffset:offset length:4096 error:nil];
             sha1String = [self SHA1Hash:buffer bufferSize:12288];
         }
         fileData.dcid = sha1String;
         [self.delegate getDcid:sha1String fileData:fileData];
     }failureBlock:^(NSError *error){}];
    
}

//计算gcid
- (void)computeGcid:(PPUploadFileData*)fileData
{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    [assetsLibrary assetForURL:[NSURL URLWithString:fileData.assetURL] resultBlock:^(ALAsset *asset)
     {
         CC_SHA1_CTX gcid;
         CC_SHA1_Init(&gcid);
         
         const NSUInteger bufferSize = 0x40000;
         NSUInteger bytesRead = 0;
         long long currentOffset = 0;
         do
         {
             @autoreleasepool
             {
                 uint8_t buffer[bufferSize];
                 bytesRead = [[asset defaultRepresentation] getBytes:(uint8_t*)buffer fromOffset:currentOffset length:bufferSize error:nil];
                 if(bytesRead == 0)break;
                 currentOffset +=bytesRead;
                 CC_SHA1_Update(&gcid, buffer, (CC_LONG)bytesRead);
             }
         } while (bytesRead > 0);
         
         unsigned char digest[CC_SHA1_DIGEST_LENGTH];
         CC_SHA1_Final(digest, &gcid);
         NSMutableString* output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
         for(int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++)
             [output appendFormat:@"%02x", digest[i]];
         fileData.gcid = output;
         [self.delegate getGcid:output fileData:fileData];
     } failureBlock:^(NSError *error){}];
    
}

//计算MD5
- (void)computeMD5:(PPUploadFileData*)fileData
{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    [assetsLibrary assetForURL:[NSURL URLWithString:fileData.assetURL] resultBlock:^(ALAsset *asset)
     {
         CC_MD5_CTX md5;
         CC_MD5_Init(&md5);
         
         const NSUInteger bufferSize = 0x40000;
         NSUInteger bytesRead = 0;
         long long currentOffset = 0;
         do
         {
             @autoreleasepool
             {
                 uint8_t buffer[bufferSize];
                 bytesRead = [[asset defaultRepresentation] getBytes:(uint8_t*)buffer fromOffset:currentOffset length:bufferSize error:nil];
                 if(bytesRead == 0)break;
                 currentOffset +=bytesRead;
                 CC_MD5_Update(&md5, buffer, (CC_LONG)bytesRead);
             }
         } while (bytesRead > 0);
         
         unsigned char digest[CC_MD5_DIGEST_LENGTH];
         CC_MD5_Final(digest, &md5);
         NSMutableString* output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
         for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
             [output appendFormat:@"%02x", digest[i]];
         fileData.md5 = output;
         [self.delegate getMD5:output fileData:fileData];
     } failureBlock:^(NSError *error){}];
}

//计算分段MD5
- (void)computeMD5withStart:(long long)start end:(long long)end bid:(NSString*)bid uploadUrl:(NSString*)uploadUrl fileData:(PPUploadFileData*)fileData
{
    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc]init];
    [assetsLibrary assetForURL:[NSURL URLWithString:fileData.assetURL] resultBlock:^(ALAsset *asset)
     {
         FileBlock* fileblock = [[FileBlock alloc] init];
         CC_MD5_CTX md5Range;
         CC_MD5_Init(&md5Range);
         const NSUInteger bufferSize = (NSUInteger)(end-start+1);
         uint8_t *buffer = (uint8_t *)malloc(sizeof(uint8_t)*bufferSize);
         NSUInteger bytesRead = 0;
         bytesRead = [[asset defaultRepresentation] getBytes:buffer fromOffset:start length:bufferSize error:nil];
         NSData *readData = [[NSData alloc] initWithBytes:(const void*)buffer length:bufferSize];
         CC_MD5_Update(&md5Range, buffer, (CC_LONG)bufferSize);
         unsigned char digest[CC_MD5_DIGEST_LENGTH];
         CC_MD5_Final(digest, &md5Range);
         NSMutableString* output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
         for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++)
             [output appendFormat:@"%02x", digest[i]];
         fileblock.blockData = readData;
         fileblock.blockMD5 = output;
         [self.delegate getBlockMD5:fileblock start:start end:end bid:bid uploadUrl:uploadUrl fileData:fileData];
         free(buffer);
     } failureBlock:^(NSError *error){}];
}

@end

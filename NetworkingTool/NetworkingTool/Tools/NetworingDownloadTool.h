//
//  NetworingDownloadTool.h
//  NetworkingTool
//
//  Created by huangjian on 2018/9/12.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkingRequest.h"
#import "NetworkingDownloadModel.h"

typedef void(^DownLoadSuccess)(NSURL *location,NetworkingProgressModel * model);
typedef void(^DownLoadFailure)(NSError *error);

@interface NetworingDownloadTool : NSObject
+(instancetype)sharedInstance;
//无进度下载
-(void)sendDownLoadRequest:(NetworkingRequest *)request success:(DownLoadSuccess)success failure:(DownLoadFailure)failure;
//有进度下载
-(void)sendBigDownLoadRequest:(NetworkingRequest *)request success:(DownLoadSuccess)success failure:(DownLoadFailure)failure;
//有进度 继续下载
-(void)continueDownload:(NSUInteger)taskId;
//有进度 暂停
-(void)suspendDownload:(NSUInteger)taskId;
//有进度 取消
-(void)cancelDownload:(NSUInteger)taskId;
@end

#define kNetworingDownloadTool NetworingDownloadTool.sharedInstance

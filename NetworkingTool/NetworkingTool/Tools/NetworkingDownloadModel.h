//
//  NetworkingDownloadModel.h
//  NetworkingTool
//
//  Created by huangjian on 2018/9/12.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class NetworkingProgressModel;

typedef void(^DownLoadSuccess)(NSURL *location,NetworkingProgressModel * model);
typedef void(^DownLoadFailure)(NSError *error);

@interface NetworkingDownloadModel : NSObject
@property (nonatomic,copy)NSString *url;
@property (nonatomic,assign)NSUInteger taskId;
@property(nonatomic,strong)NSURLSessionDataTask *task;

@property(nonatomic,strong)NSURLSessionDownloadTask *bkTask;

@property (nonatomic,assign)NSInteger startLength;
@property (nonatomic,assign)NSInteger fileLength;

@property (nonatomic,assign)BOOL isDirectory;
@property(nonatomic,copy)NSString *filePath;
@property (nonatomic, strong)NSFileHandle *fileHandle;

@property (nonatomic,copy)DownLoadSuccess success;
@property (nonatomic,copy)DownLoadFailure failure;
@end

@interface NetworkingProgressModel : NSObject

@property (nonatomic,assign)CGFloat progress;
@property (nonatomic,assign)NSUInteger taskId;

@property (nonatomic,assign)NSInteger downloadedLength;
@property (nonatomic,assign)NSInteger fileLength;

@property(nonatomic,copy)NSString *filePath;

@property (nonatomic,assign)int64_t bytesWritten;
@property (nonatomic,assign)int64_t totalBytesWritten;
@property (nonatomic,assign)int64_t totalBytesExpectedToWrite;

@end

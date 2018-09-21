







//
//  NetworkingBKdownloadTool.m
//  NetworkingTool
//
//  Created by huangjian on 2018/9/20.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import "NetworkingBKdownloadTool.h"
#import "NetworkingTool.h"
#import <CommonCrypto/CommonCrypto.h>
// 缓存主目录
#define UserCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"UserDownLoads"]

@interface NetworkingBKdownloadTool ()<NSURLSessionDownloadDelegate>
@property (nonatomic, strong, nullable) NSOperationQueue *downloadQueue;

@property (nonatomic, strong, nullable) NSOperationQueue *downloadRecieveQueue;

@property (nonatomic, strong)NSMutableDictionary *resumeDataDict;

@property (nonatomic,strong)NSMutableDictionary *completionHandlerDict;

@property (nonatomic,strong)NSLock *downLoadlock;

/** 保存所有下载相关信息 */
@property (nonatomic,strong) NSMutableDictionary *downloadModels;
@end
@implementation NetworkingBKdownloadTool
-(NSMutableDictionary *)resumeDataDict
{
    if (!_resumeDataDict) {
        _resumeDataDict=[NSMutableDictionary dictionary];
    }
    return _resumeDataDict;
}
-(NSMutableDictionary *)completionHandlerDict
{
    if (!_completionHandlerDict) {
        _completionHandlerDict=[NSMutableDictionary dictionary];
    }
    return _completionHandlerDict;
}
-(NSMutableDictionary *)downloadModels
{
    if (!_downloadModels) {
        _downloadModels=[NSMutableDictionary dictionary];
    }
    return _downloadModels;
}
-(void)addCompletionHandler:(void (^)(void))completionHandler identifier:(NSString *)identifier
{
    [self.completionHandlerDict setObject:completionHandler forKey:identifier];
}

-(NSURLSession *)session
{
    if(!_session)
    {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"UserBackgroundSession"];
        config.sessionSendsLaunchEvents = YES;
        //后面队列的作用  如果给子线程队列则协议方法在子线程中执行 给主线程队列就在主线程中执行
        _session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    }
    return _session;
}
+(instancetype)shareInstance
{
    static NetworkingBKdownloadTool * singleClass = nil;
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        singleClass = [[NetworkingBKdownloadTool alloc] init];
        NSOperationQueue *queue = [[NSOperationQueue alloc]init];
        queue.name=@"download_queue";
        queue.maxConcurrentOperationCount=10;
        singleClass.downloadQueue=queue;
        NSOperationQueue *downloadRecieveQueue = [[NSOperationQueue alloc]init];
        downloadRecieveQueue.name=@"downloadRecieve_queue";
        singleClass.downloadRecieveQueue=downloadRecieveQueue;
    
    }) ;
    
    return singleClass ;
}
//MARK: - 有进度 下载
-(void)sendDownLoadRequest:(NetworkingRequest *)request success:(DownLoadSuccess)success failure:(DownLoadFailure)failure
{
    NetworkingDownloadModel *model=[[NetworkingDownloadModel alloc]init];
    model.success = success;
    model.failure = failure;
    model.url = request.url;
    if(request.filePath)
    {
        BOOL isDirectory = [self createCacheDirectory:request.filePath];
        model.filePath=request.filePath;
        model.isDirectory=isDirectory;
    }
    NSURL *url = [NSURL URLWithString:request.url];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    NSUInteger taskIdentifier = [self getArc4Random];
    
   // NSURLSession *session = self.session;
   // NSData *data = [self.resumeDataDict objectForKey:request.url];
    __block NSURLSessionDownloadTask *task;
    __block BOOL isHaveTask;
    NSMutableDictionary *dictM = [self.session valueForKey:@"tasks"];
    NSLog(@"datatask -- %@",dictM);
    [dictM enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSURLSessionDownloadTask *task1 = obj;
        if ([task1.response.URL.absoluteString isEqualToString:request.url]) {
            isHaveTask=YES;
            task = task1;
        }
        NSLog(@"--%@   %@ -- %@ --%ld",key , obj,task.response.URL.absoluteString,task.taskIdentifier);
        
    }];

    if (isHaveTask) {
        model.taskId=task.taskIdentifier;
        model.bkTask = task;
        [self.downloadModels setObject:model forKey:@(task.taskIdentifier).stringValue];
        NSLog(@"taskIdentifier11 -- %ld  %ld",taskIdentifier,task.taskIdentifier);
    }else
    {
        task = [self.session downloadTaskWithRequest:req];
        model.taskId=task.taskIdentifier;
        model.bkTask = task;
        [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
        [self.downloadModels setObject:model forKey:@(task.taskIdentifier).stringValue];
        NSLog(@"taskIdentifier11 -- %ld  %ld",taskIdentifier,task.taskIdentifier);
        [self.downloadQueue addOperationWithBlock:^{
            [NSThread sleepForTimeInterval:0.1];
            [task resume];
        }];
    }
}
//MARK: - 下载完成
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSLog(@"location -- %@",location);
    NSLog(@"taskIdentifier22 -- %ld",downloadTask.taskIdentifier);
    NSLog(@"-- %@",self.downloadModels);
    if (![self.downloadModels objectForKey:@(downloadTask.taskIdentifier).stringValue]) {
        return;
    }
    NetworkingDownloadModel *model =[self.downloadModels objectForKey:@(downloadTask.taskIdentifier).stringValue];
    if (!model.filePath)
    {
        model.filePath = [UserCachesDirectory stringByAppendingPathComponent:downloadTask.response.suggestedFilename];
    }else
    {
        model.filePath = model.isDirectory?[model.filePath stringByAppendingPathComponent:downloadTask.response.suggestedFilename]:model.filePath;
    }
    NSError *error;
    [[NSFileManager defaultManager]moveItemAtPath:location.path toPath:model.filePath error:&error];
    [[NSFileManager defaultManager]removeItemAtURL:location error:nil];
    NSLog(@"---%@",model.filePath);
    dispatch_async(kNetworkingTool.callbackQueue, ^{
        if (!error) {
            model.success([NSURL URLWithString:model.filePath], nil);
        }else
        {
            model.failure(error);
        }
    });
}
//MARK: - 下载进度
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"-- %@",self.downloadModels);
    NSLog(@"%lf -- %ld",1.0 * totalBytesWritten / totalBytesExpectedToWrite,downloadTask.taskIdentifier);
    
    if (![self.downloadModels objectForKey:@(downloadTask.taskIdentifier).stringValue]) {
        return;
    }
    NetworkingProgressModel *progressModel =[[NetworkingProgressModel alloc]init];
    progressModel.bytesWritten=bytesWritten;
    progressModel.totalBytesWritten=totalBytesWritten;
    progressModel.totalBytesExpectedToWrite=totalBytesExpectedToWrite;
    progressModel.taskId = downloadTask.taskIdentifier;
    progressModel.progress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
    NetworkingDownloadModel *model =[self.downloadModels objectForKey:@(downloadTask.taskIdentifier).stringValue];

    dispatch_async(kNetworkingTool.callbackQueue, ^{
        model.success(nil, progressModel);
    });
}
//MARK: - 请求完成，错误调用的代理方法
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSLog(@"error --%@",error);
    if (error) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            NSString *url = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
//            NSData *data = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
//            if (data) {
//                [[NetworkingBKdownloadTool shareInstance].resumeDataDict setObject:data forKey:url];
//            }
//        });
    }
    [self.downLoadlock lock];
    if ([self.downloadModels objectForKey:@(task.taskIdentifier).stringValue]) {
        [self.downloadModels removeObjectForKey:@(task.taskIdentifier).stringValue];
    }
    [self.downLoadlock unlock];
    
    
    
}
-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    NSLog(@"URLSessionDidFinishEventsForBackgroundURLSession --");
    dispatch_async(dispatch_get_main_queue(), ^{
        void(^completionHandler)(void) = [self.completionHandlerDict objectForKey:session.configuration.identifier];
        if (completionHandler) {
            [self.completionHandlerDict removeObjectForKey:session.configuration.identifier];
            completionHandler();
        }
    });
}
//MARK: - 校验文件夹路径
- (BOOL)createCacheDirectory:(NSString *)path
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([path.pathExtension isEqualToString:@""])
    {
        if (![fileManager fileExistsAtPath:path]) {
            return [fileManager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        }
        return YES;
    }else
    {
        return NO;
    }
    
    return YES;
}

//MARK: - 获取随机数
-(NSUInteger)getArc4Random
{
    NSUInteger arc4 = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    if ([self.downloadModels objectForKey:@(arc4).stringValue]) {
        return [self getArc4Random];
    }
    return  arc4;
}
- (NSString *)md5String:(NSString *)string {
    const char *str = string.UTF8String;
    unsigned char buffer[CC_MD5_DIGEST_LENGTH];
    
    CC_MD5(str, (CC_LONG)strlen(str), buffer);
    
    return [self stringFromBytes:buffer length:CC_MD5_DIGEST_LENGTH];
}
- (NSString *)stringFromBytes:(unsigned char *)bytes length:(int)length {
    NSMutableString *strM = [NSMutableString string];
    
    for (int i = 0; i < length; i++) {
        [strM appendFormat:@"%02x", bytes[i]];
    }
    
    return [strM copy];
}
@end

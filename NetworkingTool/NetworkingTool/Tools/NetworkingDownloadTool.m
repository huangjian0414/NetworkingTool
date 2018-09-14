




//
//  NetworingDownloadTool.m
//  NetworkingTool
//
//  Created by huangjian on 2018/9/12.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import "NetworkingDownloadTool.h"
#import "NetworkingDownloadModel.h"
#import "NetworkingTool.h"



// 缓存主目录
#define UserCachesDirectory [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"UserDownLoads"]

@interface NetworkingDownloadTool ()<NSURLSessionDataDelegate>
@property (nonatomic, strong, nullable) NSOperationQueue *downloadQueue;

@property (nonatomic, strong, nullable) NSOperationQueue *noProgressDownloadQueue;

@property (nonatomic, strong, nullable) NSOperationQueue *downloadRecieveQueue;

@property (nonatomic,strong)NSLock *downLoadlock;

/** 保存所有下载相关信息 */
@property (nonatomic, strong) NSMutableDictionary *downloadModels;

@end
@implementation NetworkingDownloadTool
-(NSLock *)downLoadlock
{
    if (!_downLoadlock) {
        _downLoadlock = [[NSLock alloc]init];
    }
    return _downLoadlock;
}

-(NSMutableDictionary *)downloadModels
{
    if (!_downloadModels) {
        _downloadModels=[NSMutableDictionary dictionary];
    }
    return _downloadModels;
}
+(instancetype)sharedInstance
{
    static NetworkingDownloadTool *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NetworkingDownloadTool alloc]init];
        NSOperationQueue *queue = [[NSOperationQueue alloc]init];
        queue.name=@"download_queue";
        instance.downloadQueue=queue;
        NSOperationQueue *downloadRecieveQueue = [[NSOperationQueue alloc]init];
        downloadRecieveQueue.name=@"downloadRecieve_queue";
        instance.downloadRecieveQueue=downloadRecieveQueue;
        NSOperationQueue *noProgressDownloadQueue = [[NSOperationQueue alloc]init];
        noProgressDownloadQueue.name=@"noProgressDownload_queue";
        instance.noProgressDownloadQueue=noProgressDownloadQueue;
    });
    
    return instance;
}

//MARK: - 无进度下载
-(void)sendDownLoadRequest:(NetworkingRequest *)request success:(DownLoadSuccess)success failure:(DownLoadFailure)failure
{
    [self.noProgressDownloadQueue addOperationWithBlock:^{
        NSURL *url = [NSURL URLWithString:request.url];
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *task = [[NSURLSession sharedSession]downloadTaskWithRequest:req completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
            if (error) {
                if (failure) {
                    failure(error);
                }
            }else
            {
                NSHTTPURLResponse *re=(NSHTTPURLResponse *)response;
                if (re.statusCode!=200) {
                    if (failure) {
                        failure([NSError errorWithDomain:response.URL.absoluteString code:re.statusCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@,%@",[NSHTTPURLResponse localizedStringForStatusCode:re.statusCode],[re allHeaderFields]]}]);
                    }
                }else
                {
                    if (success) {
                        success(location,nil);
                    }
                }
            }
            
        }];
        [task resume];
    }];
}
//MARK: - 有进度 下载
-(void)sendBigDownLoadRequest:(NetworkingRequest *)request success:(DownLoadSuccess)success failure:(DownLoadFailure)failure
{
    NetworkingDownloadModel *model=[[NetworkingDownloadModel alloc]init];
    model.success = success;
    model.failure = failure;
    model.url = request.url;
    NSURL *url = [NSURL URLWithString:request.url];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
    
    NSInteger length = 0;
    
    if(request.filePath)
    {
        BOOL isDirectory = [self createCacheDirectory:request.filePath];
        model.filePath=request.filePath;
        model.startLength=length;
        model.isDirectory=isDirectory;
        if (!isDirectory)
        {
            length=[self fileLengthForPath:request.filePath];
            model.startLength = length;
        }
    }
    // 设置HTTP请求头中的Range
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", length];
    [req setValue:range forHTTPHeaderField:@"Range"];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    //后面队列的作用  如果给子线程队列则协议方法在子线程中执行 给主线程队列就在主线程中执行
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:self.downloadRecieveQueue];
    //NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:req];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:req];
    
    NSUInteger taskIdentifier = [self getArc4Random];
    [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    model.task = task;
    model.taskId=taskIdentifier;
    [self.downloadModels setObject:model forKey:@(taskIdentifier).stringValue];
    
    [self.downloadQueue addOperationWithBlock:^{
        [task resume];
    }];
}

//MARK: - 继续下载
-(void)continueDownload:(NSUInteger)taskId
{
    if (taskId) {
        NetworkingDownloadModel *model = [self.downloadModels objectForKey:@(taskId).stringValue];
        if (model) {
            NSURLSessionDataTask *task = model.task;
            if (task&&task.state == NSURLSessionTaskStateSuspended) {
                [task resume];
            }
        }
    }
}
//MARK: - 暂停下载
-(void)suspendDownload:(NSUInteger)taskId
{
    if (taskId) {
        NetworkingDownloadModel *model = [self.downloadModels objectForKey:@(taskId).stringValue];
        if (model) {
            NSURLSessionDataTask *task = model.task;
            if (task&&task.state == NSURLSessionTaskStateRunning) {
                [task suspend];
            }
        }
    }
}
//MARK: - 取消下载
- (void)cancelDownload:(NSUInteger)taskId
{
    if (taskId) {
        NetworkingDownloadModel *model = [self.downloadModels objectForKey:@(taskId).stringValue];
        if (model) {
            NSURLSessionDataTask *task = model.task;
            if (task&&(task.state == NSURLSessionTaskStateRunning||task.state == NSURLSessionTaskStateSuspended)) {
                [task cancel];
            }
        }
    }
}

//MARK: - 下载完成
//- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
//    NSLog(@"location -- %@",location);
//    dispatch_async(kNetworkingTool.callbackQueue, ^{
//        NetworkingDownloadModel *model =[self.downloadModels objectForKey:@(downloadTask.taskIdentifier).stringValue];
//        model.success(location, nil);
//    });
//}
////MARK: - 下载进度
//- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
//      didWriteData:(int64_t)bytesWritten
// totalBytesWritten:(int64_t)totalBytesWritten
//totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
//{
//    NSLog(@"%lf",1.0 * totalBytesWritten / totalBytesExpectedToWrite);
//    NetworkingProgressModel *progressModel =[[NetworkingProgressModel alloc]init];
//    progressModel.bytesWritten=bytesWritten;
//    progressModel.totalBytesWritten=totalBytesWritten;
//    progressModel.totalBytesExpectedToWrite=totalBytesExpectedToWrite;
//    progressModel.taskId = downloadTask.taskIdentifier;
//    progressModel.progress = 1.0 * totalBytesWritten / totalBytesExpectedToWrite;
//
//    NetworkingDownloadModel *model =[self.downloadModels objectForKey:@(downloadTask.taskIdentifier).stringValue];
//    dispatch_async(kNetworkingTool.callbackQueue, ^{
//        model.success(nil, progressModel);
//    });
//}
////MARK: - 重新恢复下载的代理方法
//-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
//didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
//
//}

//MARK: - 接收到响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NetworkingDownloadModel *model =[self.downloadModels objectForKey:@(dataTask.taskIdentifier).stringValue];
    model.fileLength = response.expectedContentLength + model.startLength;
    if (!model.filePath)
    {
        model.filePath = [UserCachesDirectory stringByAppendingPathComponent:response.suggestedFilename];
    }else
    {
        model.filePath = model.isDirectory?[model.filePath stringByAppendingPathComponent:response.suggestedFilename]:model.filePath;
    }
    NSError *error = [self checkFilePath:model.filePath];
    if (error)
    {
        [dataTask cancel];
        return;
    }
    NSLog(@"Path---%@",model.filePath);
    model.fileHandle = [NSFileHandle fileHandleForWritingAtPath:model.filePath];
    
    // 允许处理服务器的响应，才会继续接收服务器返回的数据
    completionHandler(NSURLSessionResponseAllow);
}


//MARK: - 接收到服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSLog(@"接收到数据");
    NetworkingDownloadModel *model =[self.downloadModels objectForKey:@(dataTask.taskIdentifier).stringValue];
    // 指定数据的写入位置 -- 文件内容的最后面
    [model.fileHandle seekToEndOfFile];
    // 向沙盒写入数据
    [model.fileHandle writeData:data];
    model.startLength += data.length;
    NetworkingProgressModel *progressModel =[[NetworkingProgressModel alloc]init];
    progressModel.taskId = dataTask.taskIdentifier;
    progressModel.progress = 1.0 * model.startLength / model.fileLength;
    progressModel.downloadedLength = model.startLength;
    progressModel.filePath=model.filePath;
    progressModel.fileLength=model.fileLength;
    dispatch_async(kNetworkingTool.callbackQueue, ^{
        model.success(nil, progressModel);
    });
}

//MARK: - 请求完成，错误调用的代理方法
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSLog(@"error --%@",error);
    NetworkingDownloadModel *model =[self.downloadModels objectForKey:@(task.taskIdentifier).stringValue];
    [model.fileHandle closeFile];
    model.fileHandle=nil;
    if (error) {
        dispatch_async(kNetworkingTool.callbackQueue, ^{
            if (model&&model.failure) {
                model.failure(error);
            }
        });
    }
    [self.downLoadlock lock];
    if ([self.downloadModels objectForKey:@(task.taskIdentifier).stringValue]) {
        [self.downloadModels removeObjectForKey:@(task.taskIdentifier).stringValue];
    }
    [self.downLoadlock unlock];
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
//MARK: - 校验文件路径
-(NSError *)checkFilePath:(NSString *)path
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:path]) {
        return nil;
    }else
    {
        NSError *err = [NSError errorWithDomain:path code:-10097 userInfo:@{NSLocalizedDescriptionKey:@"创建文件失败"}];
        NSString *directory = [path stringByDeletingLastPathComponent];
        if (![fileManager fileExistsAtPath:directory]) {
            BOOL isCreateDir = [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
            if(!isCreateDir)
            {
                return err;
            }
        }
        if([fileManager createFileAtPath:path contents:nil attributes:nil])
        {
            return nil;
        }else
        {
            return err;
        }
    }
    return nil;
}

//MARK: - 获取已下载的文件大小
- (NSInteger)fileLengthForPath:(NSString *)path {
    NSInteger fileLength = 0;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if ([fileManager fileExistsAtPath:path]) {
        NSError *error = nil;
        NSDictionary *fileDict = [fileManager attributesOfItemAtPath:path error:&error];
        if (!error && fileDict) {
            fileLength = [fileDict fileSize];
        }
    }
    return fileLength;
}
@end

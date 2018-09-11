//  Created by 黄坚 on 2017/11/30.
//  Copyright © 2017年 黄坚. All rights reserved.
//

#import "NetworkingTool.h"

@interface NetworkingTool ()<NSURLSessionDownloadDelegate>
@property (nonatomic,copy)Success success;
@property (nonatomic,copy)Failure failure;

@property (nonatomic,copy)DownLoadSuccess downloadSuccess;
@property (nonatomic,copy)DownLoadFailure downloadFailure;

@property (nonatomic, strong, nullable) dispatch_queue_t requestQueue;

@property (nonatomic, strong, nullable) NSOperationQueue *downloadQueue;

@property (nonatomic, strong, nullable) NSOperationQueue *noProgressDownloadQueue;

@property (nonatomic, strong, nullable) NSOperationQueue *downloadRecieveQueue;

@property (nonatomic,strong)NSLock *downLoadlock;
@end
@implementation NetworkingTool
-(NSLock *)downLoadlock
{
    if (!_downLoadlock) {
        _downLoadlock = [[NSLock alloc]init];
    }
    return _downLoadlock;
}
+(instancetype)sharedInstance
{
    static NetworkingTool *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance=[[NetworkingTool alloc]init];
        instance.generalServer=@"";
        instance.generalHeaders=nil;
        instance.showRequestLog=NO;
        instance.callbackQueue=dispatch_queue_create("networking_queue", DISPATCH_QUEUE_CONCURRENT);
        instance.timeoutInterval=30;
        instance.requestQueue=dispatch_queue_create("request_queue", DISPATCH_QUEUE_CONCURRENT);
        NSOperationQueue *queue = [[NSOperationQueue alloc]init];
        queue.name=@"download_queue";
        queue.maxConcurrentOperationCount=1;
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
//MARK:http请求配置
-(void)setUpConfig:(void (^)(NetworkingConfig *))block
{
    NetworkingConfig *config = [[NetworkingConfig alloc] init];
    SAFE_BLOCK(block, config);
    if (config.generalServer) {
        self.generalServer=config.generalServer;
    }
    if (config.generalHeaders) {
        self.generalHeaders=config.generalHeaders;
    }
    if (config.callbackQueue != NULL) {
        self.callbackQueue=config.callbackQueue;
    }
    if (config.timeoutInterval<=0) {
        self.timeoutInterval=30;
    }else if(config.timeoutInterval>90)
    {
        self.timeoutInterval=90;
    }else
    {
        self.timeoutInterval=config.timeoutInterval;
    }
    self.showRequestLog = config.showRequestLog;
}
// 无进度下载
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
                        success(location);
                    }
                }
            }
            
        }];
        [task resume];
    }];
}
//有进度 下载
-(void)sendBigDownLoadRequest:(NetworkingRequest *)request success:(DownLoadSuccess)success failure:(DownLoadFailure)failure
{
    [self.downloadQueue addOperationWithBlock:^{
        [self.downLoadlock lock];
        self.downloadSuccess = success;
        self.downloadFailure = failure;
        NSURL *url = [NSURL URLWithString:request.url];
        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
        
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        //后面队列的作用  如果给子线程队列则协议方法在子线程中执行 给主线程队列就在主线程中执行
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:self.downloadRecieveQueue];
        
        NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:req];
        [task resume];
    }];
}
//MARK:发起请求
-(void)sendRequest:(NetworkingRequest *)request success:(Success)success failure:(Failure)failure
{
    dispatch_async(self.requestQueue, ^{
        [self requestStart:request success:success failure:failure];
    });
}
-(void)requestStart:(NetworkingRequest *)request success:(Success)success failure:(Failure)failure
{
    NSURL *url = [self getUrlWithRequestType:request.type api:request.api params:request.params];
    if (request.url) {
        url=[NSURL URLWithString:request.url];
    }
    [self checkShowLogWithUrlString:url.absoluteString header:request.headers params:request.params];
    NSMutableURLRequest *reques = [NSMutableURLRequest requestWithURL:url];
    [self setUpRequest:reques networkingRequest:request];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:reques completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *re=(NSHTTPURLResponse *)response;
        dispatch_async(self.callbackQueue, ^{
            [self dealResponseWithData:data response:re error:error success:success failure:failure];
        });
    }];
    //开始请求
    [task resume];
}
//MARK:Request配置
-(void)setUpRequest:(NSMutableURLRequest *)request networkingRequest:(NetworkingRequest *)networkingRequest
{
    if (self.generalHeaders) {
        [self.generalHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    if (networkingRequest.headers) {
        [networkingRequest.headers enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }
    if (networkingRequest.timeout<=0) {
        //self.timeoutInterval=30;
    }else if(networkingRequest.timeout>90)
    {
        self.timeoutInterval=90;
    }else
    {
        self.timeoutInterval=networkingRequest.timeout;
    }
    request.timeoutInterval=self.timeoutInterval;
    request.HTTPMethod=[self getHttpMethodStringWithRequestType:networkingRequest.type];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    if (networkingRequest.type==HttpMethod_POST||networkingRequest.type==HttpMethod_PUT) {
        NSData *jsonData;
        if (networkingRequest.params &&[NSJSONSerialization isValidJSONObject:networkingRequest.params]&&networkingRequest.params.count>0) {
            jsonData = [[self dealWithParam:networkingRequest.params] dataUsingEncoding:NSUTF8StringEncoding];
            [request  setHTTPBody:jsonData];
        }
    }
}

//MARK: 获取url
-(NSURL *)getUrlWithRequestType:(Request_Type)type api:(NSString *)api params:(NSDictionary *)params
{
    if (type==HttpMethod_GET||type==HttpMethod_DELETE) {
        NSString *path=self.generalServer;
        path=[NSString stringWithFormat:@"%@%@",path,api];
        if (params&&params.count>0) {
            NSString *param=[self dealWithParam:params];
            path=[NSString stringWithFormat:@"%@?%@",path,param];
        }
        NSString*  pathStr = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        NSURL *url = [NSURL URLWithString:pathStr];
        
        return url;
    }else if (type==HttpMethod_POST||type==HttpMethod_PUT)
    {
        NSString *path=self.generalServer;
        path=[NSString stringWithFormat:@"%@%@",path,api];
        NSString*  pathStr = [path stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        
        NSURL *url = [NSURL URLWithString:pathStr];
        return url;
    }
    return nil;
}
//MARK: 处理请求回调
-(void)dealResponseWithData:(NSData *)data response:(NSHTTPURLResponse *)response error:(NSError *)error success:(Success)success failure:(Failure)failure
{
    if (error) {
        if (self.failure) {
            self.failure(error);
        }
        if (failure) {
            failure(error);
            if (self.showRequestLog) {
                NSLog(@"\n============ [NetworkingResponse Error] ===========\nresponse data: \n%@\n==========================================\n", error);
            }
        }
    }else
    {
        if (response.statusCode!=200) {
            if (self.failure) {
                self.failure([NSError errorWithDomain:response.URL.absoluteString code:response.statusCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@,%@",[NSHTTPURLResponse localizedStringForStatusCode:response.statusCode],[response allHeaderFields]]}]);
            }
            if (failure) {
                failure([NSError errorWithDomain:response.URL.absoluteString code:response.statusCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@,%@",[NSHTTPURLResponse localizedStringForStatusCode:response.statusCode],[response allHeaderFields]]}]);
            }
            return;
        }
        id  jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (self.success) {
            self.success(jsonData);
        }
        if (success) {
            success(jsonData);
            if (self.showRequestLog) {
                NSLog(@"\n============ [NetworkingResponse Data] ===========\nresponse data: \n%@\n==========================================\n", jsonData);
            }
            
        }
    }
}
//MARK: 处理字典参数
-(NSString *)dealWithParam:(NSDictionary *)param
{
    NSMutableString *result = [NSMutableString string];
    [param enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSString *str = [NSString stringWithFormat:@"%@=%@&",key,obj];
        
        [result appendString:str];
    }];
    if (result.length==0) {
        return nil;
    }
    return [result substringWithRange:NSMakeRange(0, result.length-1)];
    
}
//MARK: 统一处理需求
-(void)requestUnifiedProcessingOnSuccess:(Success)success onFailure:(Failure)failure
{
    self.success = success;
    self.failure = failure;
}
//MARK: 请求log打印
-(void)checkShowLogWithUrlString:(NSString *)urlString header:(NSDictionary *)header params:(NSDictionary *)params
{
    if (self.showRequestLog) {
        NSLog(@"\n============ [Networking Info] ============\nrequest url: %@ \nrequest headers: \n%@ \nrequest parameters: \n%@ \n==========================================\n", urlString, header, params);
    }
}
-(NSString *)getHttpMethodStringWithRequestType:(Request_Type)type
{
    switch (type) {
        case HttpMethod_GET:
            return @"GET";
            break;
        case HttpMethod_POST:
            return @"POST";
            break;
        case HttpMethod_PUT:
            return @"PUT";
            break;
        case HttpMethod_DELETE:
            return @"DELETE";
            break;
        default:
            break;
    }
}

//MARK: - 下载完成
- (void)URLSession:(nonnull NSURLSession *)session downloadTask:(nonnull NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(nonnull NSURL *)location {
    NSLog(@"location -- %@",location);
    self.downloadSuccess(location);
}
//MARK: - 下载进度
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    NSLog(@"%lf",1.0 * totalBytesWritten / totalBytesExpectedToWrite);
}
//MARK: - 重新恢复下载的代理方法
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask
didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    
}
//MARK: - 请求完成，错误调用的代理方法
-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error{
    NSLog(@"error --%@",error);
    [self.downLoadlock unlock];
}

@end

@implementation NetworkingConfig
@end

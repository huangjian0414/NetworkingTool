




//
//  NetworkingUploadTool.m
//  NetworkingTool
//
//  Created by huangjian on 2018/9/12.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import "NetworkingUploadTool.h"
#import "NetworkingTool.h"
@interface NetworkingUploadTool ()<NSURLSessionTaskDelegate>

@end
@implementation NetworkingUploadTool

+(instancetype)shareInstance
{
    static NetworkingUploadTool * singleClass = nil;
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        singleClass = [[NetworkingUploadTool alloc] init] ;
    }) ;
    
    return singleClass ;
}
// 以流的方式上传
//-(void)uploadFileWithData:(NSData *)fileData{
//    // 1.创建url
//    NSString *urlString = @"http://服务端/upload.jpg";
//    NSURL *url = [NSURL URLWithString:urlString];
//
//    // 2.创建请求
//    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
//    // 文件上传使用post
//    request.HTTPMethod = @"POST";
//
//    // 3.开始上传   request的body data将被忽略，而由fromData提供
//    [[[NSURLSession sharedSession] uploadTaskWithRequest:request fromData:fileData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
//        if (error == nil) {
//            NSLog(@"upload success：%@",[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
//        } else {
//            NSLog(@"upload error:%@",error);
//        }
//    }] resume];
//}
-(void)sendUpload:(NetworkingRequest *)request success:(UpLoadSuccess)success failure:(UpLoadFailure)failure
{
    if (request.timeout<=0||request.timeout>90) {
        request.timeout=kNetworkingTool.timeoutInterval;
    }
    //上传请求
    NSMutableURLRequest *imgRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:request.url] cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:request.timeout];
    [imgRequest setHTTPMethod:@"POST"];
    
    for (NSString *key in request.headers) {
        [imgRequest setValue:[request.headers objectForKey:key] forHTTPHeaderField:key];
    }
    //设请求头信息
    [imgRequest setValue:[NSString stringWithFormat:@"multipart/form-data; boundary=%@",request.uploadBoundary] forHTTPHeaderField:@"Content-Type"];
    
    NSMutableData* postData = [NSMutableData data];
    if (!request.fileName) {
        // 设置上传的名字   filename 需要
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyyMMddHHmmss";
        NSString *imgNameStr = [formatter stringFromDate:[NSDate date]];
        NSString *fileName = [NSString stringWithFormat:@"%@.png", imgNameStr];
        request.fileName=fileName;
    }
    NSDictionary *params=request.params;
    for (NSString *key in params) {
        NSString *pair=@"";
        id value = [params objectForKey:key];
        if ([value isKindOfClass:[NSString class]]) {
            pair=[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\"\r\n\r\n",request.uploadBoundary,key];
            [postData appendData:[pair dataUsingEncoding:NSUTF8StringEncoding]];
            [postData appendData:[value dataUsingEncoding:NSUTF8StringEncoding]];
        }else if ([value isKindOfClass:[NSData class]]){
            pair=[NSString stringWithFormat:@"--%@\r\nContent-Disposition: form-data; name=\"%@\";filename=\"%@\"\r\nContent-Type: image/png, image/jpeg, image/jpeg, image/pjpeg, image/pjpeg\r\n\r\n",request.uploadBoundary,key,request.fileName];
            [postData appendData:[pair dataUsingEncoding:NSUTF8StringEncoding]];
            [postData appendData:value];
        }
        [postData appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
    }
    [postData appendData:[[NSString stringWithFormat:@"--%@--\r\n",request.uploadBoundary] dataUsingEncoding:NSUTF8StringEncoding]];
    imgRequest.HTTPBody = postData;
    
    //设置Content-Length
    [imgRequest setValue:[NSString stringWithFormat:@"%ld", (unsigned long)[postData length]]
      forHTTPHeaderField:@"Content-Length"];
    
    // URLSession
    NSURLSession *session = [NSURLSession sharedSession];
    // 上传任务
    NSURLSessionUploadTask *task = [session uploadTaskWithRequest:imgRequest fromData:nil completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        NSHTTPURLResponse *re=(NSHTTPURLResponse *)response;
        dispatch_async(dispatch_get_main_queue(), ^{
            [self dealResponseWithData:data response:re error:error success:success failure:failure];
        });
    }];
    //开始请求
    [task resume];
}
//MARK: 处理请求回调
-(void)dealResponseWithData:(NSData *)data response:(NSHTTPURLResponse *)response error:(NSError *)error success:(UpLoadSuccess)success failure:(UpLoadFailure)failure
{
    if (error) {
        if (failure) {
            failure(error);
            if (kNetworkingTool.showRequestLog) {
                NSLog(@"\n============ [UploadResponse Error] ===========\nresponse data: \n%@\n==========================================\n", error);
            }
        }
    }else
    {
        if (response.statusCode!=200) {
            NSError *err=[NSError errorWithDomain:response.URL.absoluteString code:response.statusCode userInfo:@{NSLocalizedDescriptionKey:[NSString stringWithFormat:@"%@,%@",[NSHTTPURLResponse localizedStringForStatusCode:response.statusCode],[response allHeaderFields]]}];
            if (failure) {
                failure(err);
            }
            if (kNetworkingTool.showRequestLog) {
                NSLog(@"\n============ [UploadResponse Error] ===========\nresponse data: \n%@\n==========================================\n", err);
            }
            return;
        }
        id  jsonData = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (success) {
            success(jsonData);
            if (kNetworkingTool.showRequestLog) {
                NSLog(@"\n============ [UploadResponse Data] ===========\nrequest url: %@\nresponse data: \n%@\n==========================================\n", response.URL.absoluteString,jsonData);
            }
        }
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didSendBodyData:(int64_t)bytesSent totalBytesSent:(int64_t)totalBytesSent totalBytesExpectedToSend:(int64_t)totalBytesExpectedToSend
{
    float progress = (float)1.0*totalBytesSent / totalBytesExpectedToSend;
    NSLog(@"%f",progress);
}
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSLog(@"%s",__func__);
}

@end

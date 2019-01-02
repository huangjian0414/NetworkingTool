//  Created by 黄坚 on 2017/11/30.
//  Copyright © 2017年 黄坚. All rights reserved.
//

#import "NetworkingTool.h"

@interface NetworkingTool ()
@property (nonatomic,copy)Success success;
@property (nonatomic,copy)Failure failure;

@property (nonatomic, strong, nullable) dispatch_queue_t requestQueue;


@end
@implementation NetworkingTool

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
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
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
        NSString *str = [NSString stringWithFormat:@"%@=%@&",[self transferredWithString:key],[self transferredWithString:[NSString stringWithFormat:@"%@",obj]]];
        
        [result appendString:str];
    }];
    if (result.length==0) {
        return nil;
    }
    return [result substringWithRange:NSMakeRange(0, result.length-1)];
    
}
//参数特殊字符转义
-(NSString *)transferredWithString:(NSString *)string
{
    NSString *charactersToEscape = @"?!@#$^&%*+,:;='\"`<>()[]{}/\\| ";
    NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
    NSString *encodedUrl = [string stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
    return encodedUrl;
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


@end

@implementation NetworkingConfig
@end

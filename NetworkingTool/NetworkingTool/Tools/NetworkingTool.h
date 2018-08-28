//  Created by 黄坚 on 2017/11/30.
//  Copyright © 2017年 黄坚. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkingRequest.h"
typedef void(^Success)(id responseObject);
typedef void(^Failure)(NSError *error);

@class NetworkingConfig;
@interface NetworkingTool : NSObject
+(instancetype)sharedInstance;

@property (nonatomic,copy)NSString *generalServer;
@property (nonatomic,strong)NSDictionary *generalHeaders;
@property (nonatomic,assign)BOOL showRequestLog;
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

//请求超时  defalut:30s
@property NSTimeInterval timeoutInterval;

//网络请求配置
-(void)setUpConfig:(void(^)(NetworkingConfig *config))block;
//发起请求
-(void)sendRequest:(NetworkingRequest *)request success:(Success)success failure:(Failure)failure;
//请求回调统一处理
-(void)requestUnifiedProcessingOnSuccess:(Success)success onFailure:(Failure)failure;
@end

@interface NetworkingConfig : NSObject
/**
 The general server address to assign for NetworingTool.
 */
@property (nonatomic, copy, nullable) NSString *generalServer;

/**
 The general headers to assign for NetworingTool.
 */
@property (nonatomic, strong, nullable) NSDictionary<NSString *, NSString *> *generalHeaders;

/**
 The dispatch callback queue to assign for NetworingTool.
 */
@property (nonatomic, strong, nullable) dispatch_queue_t callbackQueue;

/**
 The console log BOOL value to assign for NetworingTool.
 */
@property (nonatomic, assign) BOOL showRequestLog;
/**
 The timeoutInterval for NetworingTool.  1-90s  defalut 30s
 */
@property NSTimeInterval timeoutInterval;
@end



#define kNetworingTool NetworkingTool.sharedInstance
#define SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })


//
//  NetworkingBKdownloadTool.h
//  NetworkingTool
//
//  Created by huangjian on 2018/9/20.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkingRequest.h"
#import "NetworkingDownloadModel.h"

typedef void(^DownLoadSuccess)(NSURL *location,NetworkingProgressModel * model);
typedef void(^DownLoadFailure)(NSError *error);
@interface NetworkingBKdownloadTool : NSObject
+(instancetype)shareInstance;
@property (nonatomic,strong)NSURLSession *session;

-(void)sendDownLoadRequest:(NetworkingRequest *)request success:(DownLoadSuccess)success failure:(DownLoadFailure)failure;

-(void)addCompletionHandler:(void (^)(void))completionHandler identifier:(NSString *)identifier;

@end


#define kNetworkingBKdownloadTool NetworkingBKdownloadTool.shareInstance


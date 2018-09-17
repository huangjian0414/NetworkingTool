//
//  NetworkingUploadTool.h
//  NetworkingTool
//
//  Created by huangjian on 2018/9/12.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NetworkingRequest.h"

typedef void(^UpLoadSuccess)(BOOL isSuccess);
typedef void(^UpLoadFailure)(NSError *error);
@interface NetworkingUploadTool : NSObject
+(instancetype)shareInstance;
//-(void)sendUpload:(NetworkingRequest *)request success:(UpLoadSuccess)success failure:(UpLoadFailure)failure;;
@end

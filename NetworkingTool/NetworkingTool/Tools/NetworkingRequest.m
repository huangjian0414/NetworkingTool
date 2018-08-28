


//
//  NetworkingRequest.m
//  MindIntelligenceDemo
//
//  Created by huangjian on 2018/8/28.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import "NetworkingRequest.h"

@implementation NetworkingRequest
-(instancetype)init
{
    if (self=[super init]) {
        self.type=HttpMethod_POST;
    }
    return self;
}
+(NetworkingRequest *)setUpRequest:(void(^)(NetworkingRequest *request))block
{
    NetworkingRequest *reque = [[NetworkingRequest alloc] init];
    reque.type=HttpMethod_POST;
    SAFE_BLOCK(block, reque);
   
    return reque;
}
@end

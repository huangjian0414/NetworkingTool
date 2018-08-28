//
//  NetworkingRequest.h
//  MindIntelligenceDemo
//
//  Created by huangjian on 2018/8/28.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger,Request_Type)
{
    HttpMethod_GET,
    HttpMethod_POST,
    HttpMethod_PUT,
    HttpMethod_DELETE
};
@interface NetworkingRequest : NSObject
@property (nonatomic,copy)NSString *url;
@property (nonatomic,copy)NSString *api;
@property(nonatomic,strong) NSDictionary *params;
@property(nonatomic,strong) NSDictionary *headers;

@property NSTimeInterval timeout;

@property (nonatomic,assign)Request_Type type;
//Request配置
+(NetworkingRequest *)setUpRequest:(void(^)(NetworkingRequest *request))block;
@end



#define SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })

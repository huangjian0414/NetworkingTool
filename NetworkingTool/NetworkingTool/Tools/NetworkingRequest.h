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
@property (nonatomic,copy)NSString *url;//完整接口地址 会忽略api
@property (nonatomic,copy)NSString *api;//接口地址，会拼接host
@property(nonatomic,strong) NSDictionary *params;
@property(nonatomic,strong) NSDictionary *headers;
@property (nonatomic,assign)Request_Type type;//请求方法
@property NSTimeInterval timeout;


//文件存储的文件夹路径(下载)
@property (nonatomic,copy)NSString *filePath;

//上传图片
@property (nonatomic,copy)NSString *uploadBoundary;
@property (nonatomic,copy)NSString *fileName;

//Request配置
+(NetworkingRequest *)setUpRequest:(void(^)(NetworkingRequest *request))block;
@end



#define SAFE_BLOCK(BlockName, ...) ({ !BlockName ? nil : BlockName(__VA_ARGS__); })

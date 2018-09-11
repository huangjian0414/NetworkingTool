//
//  ViewController.m
//  NetworkingTool
//
//  Created by huangjian on 2018/8/28.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import "ViewController.h"
#import "NetworkingTool.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [kNetworingTool sendDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
//        request.url = @"https://fog-pub-test.gz.bcebos.com/fog-pub-app/543db1c62f5a11e8b824fa163e9e4aa3_1531893017444.png";
//    }] success:^(NSURL *location) {
//        NSData *data=[NSData dataWithContentsOfURL:location];
//        UIImage *img = [UIImage imageWithData:data];
//        dispatch_async(dispatch_get_main_queue(), ^{
//            UIImageView *v =[[UIImageView alloc]initWithImage:img];
//            v.frame =CGRectMake(30, 30, 100, 100);
//            [self.view addSubview:v];
//        });
//    } failure:^(NSError *error) {
//
//    }];

   
    [kNetworingTool sendBigDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
        request.url = @"http://img.zcool.cn/community/0117e2571b8b246ac72538120dd8a4.jpg@1280w_1l_2o_100sh.jpg";
    }] success:^(NSURL *location) {
        NSLog(@"1111111111111");
    } failure:^(NSError *error) {
        
    }];
    [kNetworingTool sendBigDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
        request.url = @"http://img.zcool.cn/community/0117e2571b8b246ac72538120dd8a4.jpg@1280w_1l_2o_100sh.jpg";
    }] success:^(NSURL *location) {
        NSLog(@"222222222222");
    } failure:^(NSError *error) {
        
    }];
    [kNetworingTool sendBigDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
        request.url = @"http://img.zcool.cn/community/0117e2571b8b246ac72538120dd8a4.jpg@1280w_1l_2o_100sh.jpg";
    }] success:^(NSURL *location) {
        NSLog(@"33333333333");
    } failure:^(NSError *error) {
        
    }];
}


@end

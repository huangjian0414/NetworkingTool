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
    [kNetworingTool sendRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
        request.api=@"";
        request.params=@{};
        request.type=HttpMethod_POST;
        request.headers=@{};
        request.timeout=30;
    }] success:^(id responseObject) {
        
    } failure:^(NSError *error) {
        
    }];
}


@end

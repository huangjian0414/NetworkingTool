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
@property (weak, nonatomic) IBOutlet UISlider *firstSlider;
@property (weak, nonatomic) IBOutlet UISlider *secondSlider;
@property (weak, nonatomic) IBOutlet UISlider *thirtySlider;

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
        request.url = @"http://video.yueshichina.com/video/2016/0812/pengyuyan.mp4";
    }] success:^(NSURL *location, NetworkingProgressModel *model) {
        NSLog(@"1111111--%@--%lf",location,1.0 *  model.totalBytesWritten/ model.totalBytesExpectedToWrite);
        if (location) {
            
        }else
        {
            self.firstSlider.value = model.progress;
        }
    } failure:^(NSError *error) {
        NSLog(@"1111111- %@",error);
    }];
    [kNetworingTool sendBigDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
        request.url = @"http://video.yueshichina.com/video/2016/0812/youzi.mp4";
    }] success:^(NSURL *location, NetworkingProgressModel *model) {
        NSLog(@"2222222--%@--%lf",location,(1.0 *  model.totalBytesWritten/ model.totalBytesExpectedToWrite));
        if (location) {
            //下载完成
        }else
        {
           self.secondSlider.value = model.progress;
        }
    } failure:^(NSError *error) {

    }];
    
    [kNetworingTool sendBigDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
        request.url = @"http://video.yueshichina.com/video/2016/0812/liaofan.mp4";
    }] success:^(NSURL *location, NetworkingProgressModel *model) {
        NSLog(@"3333333--%@--%lf",location,1.0 *  model.totalBytesWritten/ model.totalBytesExpectedToWrite);
        if (location) {
            
        }else
        {
            self.thirtySlider.value = model.progress;
        }
    } failure:^(NSError *error) {

    }];
}


@end

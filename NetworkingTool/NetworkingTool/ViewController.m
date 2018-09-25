//
//  ViewController.m
//  NetworkingTool
//
//  Created by huangjian on 2018/8/28.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import "ViewController.h"
#import "NetworkingTool.h"
#import "NetworkingDownloadTool.h"
#import "NetworkingBKdownloadTool.h"

@interface ViewController ()<NSURLSessionDataDelegate>
@property (weak, nonatomic) IBOutlet UISlider *firstSlider;
@property (weak, nonatomic) IBOutlet UISlider *secondSlider;
@property (weak, nonatomic) IBOutlet UISlider *thirtySlider;

@property (nonatomic,assign)NSUInteger taskID;

@end

@implementation ViewController
- (IBAction)clickBtn:(UIButton *)sender {
    sender.selected=!sender.selected;
    if (sender.selected) {
        [kNetworkingDownloadTool suspendDownload:self.taskID];
    }else
    {
        [kNetworkingDownloadTool continueDownload:self.taskID];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [kNetworkingTool sendRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
//        request.api=@"/enduser/login/";
//        request.params=@{@"password": @"12345678", @"account": @"1832193****", @"app_id": @"e55297d89b11de79b3a1a1457d0033"};
//    }] success:^(id responseObject) {
//
//    } failure:^(NSError *error) {
//
//    }];
    [kNetworkingBKdownloadTool sendDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
        //request.url=@"http://video.yueshichina.com/video/2016/0812/pengyuyan.mp4";
        request.url=@"https://timgsa.baidu.com/timg?image&quality=80&size=b9999_10000&sec=1537864820569&di=0d448c7f68f8d2f3f24d8747d2af69d4&imgtype=0&src=http%3A%2F%2Fimages6.fanpop.com%2Fimage%2Fphotos%2F40400000%2FOne-Piece-maouki-40446148-2000-1000.jpg";
        
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"UserDownLoads/MyVideo"];
        request.filePath=path;
    }] success:^(NSURL *location, NetworkingProgressModel *model) {
        if (location) {
            //下载完成
            NSLog(@"下载完成-- %@",location.path);
        }else
        {
            self.firstSlider.value = model.progress;

        }
    } failure:^(NSError *error) {
        
    }];
    //return;
    [kNetworkingBKdownloadTool sendDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
        request.url=@"http://video.yueshichina.com/video/2016/0812/youzi.mp4";
        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"UserDownLoads/MyVideo"];
        request.filePath=path;
    }] success:^(NSURL *location, NetworkingProgressModel *model) {
        if (location) {
            //下载完成
            NSLog(@"下载完成-- %@",location.path);
        }else
        {
            self.secondSlider.value = model.progress;
           
        }
    } failure:^(NSError *error) {
        
    }];
    return;
//    [kNetworkingDownloadTool sendBigDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
//        request.url = @"http://video.yueshichina.com/video/2016/0812/pengyuyan.mp4";
//
//        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"UserDownLoads/MyVideo"];
//        request.filePath=path;
//    }] success:^(NSURL *location, NetworkingProgressModel *model) {
//        NSLog(@"1111111--%@--%lf",location,model.progress);
//        if (location) {
//            //下载完成
//        }else
//        {
//            self.firstSlider.value = model.progress;
//            self.taskID = model.taskId;
//        }
//    } failure:^(NSError *error) {
//        NSLog(@"--- %@",error);
//    }];
//    return;
//    [kNetworkingDownloadTool sendBigDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
//        request.url = @"http://video.yueshichina.com/video/2016/0812/youzi.mp4";
//        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"UserDownLoads/MyVideo"];
//        request.filePath=path;
//    }] success:^(NSURL *location, NetworkingProgressModel *model) {
//        if (location) {
//            //下载完成
//        }else
//        {
//            self.secondSlider.value = model.progress;
//            //self.taskID = model.taskId;
//        }
//    } failure:^(NSError *error) {
//
//    }];
//
//    [kNetworkingDownloadTool sendBigDownLoadRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
//        request.url = @"http://video.yueshichina.com/video/2016/0812/liaofan.mp4";
//        NSString *path = [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"UserDownLoads/MyVideo"];
//        request.filePath=path;
//    }] success:^(NSURL *location, NetworkingProgressModel *model) {
//
//        if (location) {
//            //下载完成
//        }else
//        {
//            self.thirtySlider.value = model.progress;
//        }
//    } failure:^(NSError *error) {
//
//    }];
    

}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
}

@end

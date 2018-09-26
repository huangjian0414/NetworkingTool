//
//  NetworkingDownloadModel.m
//  NetworkingTool
//
//  Created by huangjian on 2018/9/12.
//  Copyright © 2018年 huangjian. All rights reserved.
//

#import "NetworkingDownloadModel.h"

@implementation NetworkingDownloadModel
-(void)setUrl:(NSString *)url
{
    if (url) {
        _url=[[url stringByRemovingPercentEncoding]stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    }
}
@end
@implementation NetworkingProgressModel

@end

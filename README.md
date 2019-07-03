# NetworkingTool
原生网络请求（仿XMNetworking）支持GET,POST,PUT,DELETE ,下载,断点下载,后台下载,上传



##### 全局网络配置

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [kNetworkingTool setUpConfig:^(NetworkingConfig *config) {
        config.generalServer=@"";//host
        config.showRequestLog=YES;//log是否开启
        config.callbackQueue=dispatch_get_main_queue();//主线程回调
    }];

    return YES;
}
```

##### 发起请求

```
[kNetworkingTool sendRequest:[NetworkingRequest setUpRequest:^(NetworkingRequest *request) {
        request.api=@"/enduser/login/";
        request.params=@{@"password": @"12345678", @"account": @"1832193****"};
        
}] success:^(id responseObject) {

} failure:^(NSError *error) {

}];

```


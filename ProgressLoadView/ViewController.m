//
//  ViewController.m
//  ProgressLoadView
//
//  Created by bjovov on 2017/9/21.
//  Copyright © 2017年 CaoXueLiang.cn. All rights reserved.
//

#import "ViewController.h"
#import "DownLoadProgressView.h"
#import "AFNetworking.h"

@interface ViewController ()<JSDownloadAnimationDelegate>
@property (nonatomic,strong) DownLoadProgressView *progressView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithRed:28/255.0 green:136/255.0 blue:238/255.0 alpha:1];
    _progressView = [[DownLoadProgressView alloc]initWithFrame:CGRectMake(0, 0, 100, 100)];
    _progressView.center = self.view.center;
    _progressView.delegate = self;
    [self.view addSubview:_progressView];
}

- (void)startDownLoad{
    [self downLoad];
}

- (void)downLoad{
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *urlString = @"http://sw.bos.baidu.com/sw-search-sp/software/e81362253956d/thunder_mac_3.1.0.2968.dmg";
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    //下载任务
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        NSString *progressString  = [NSString stringWithFormat:@"%.2f",1.0 * downloadProgress.completedUnitCount / downloadProgress.totalUnitCount];
        NSLog(@"%@",progressString);
        _progressView.progress = [progressString floatValue];
        
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        //设置下载路径，通过沙盒获取缓存地址，最后返回NSURL对象
        NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
        return [NSURL fileURLWithPath:filePath];
        
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
     
    }];
    //开始启动任务
    [task resume];
}


@end

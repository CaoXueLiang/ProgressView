//
//  DownLoadProgressView.h
//  ProgressLoadView
//
//  Created by bjovov on 2017/9/21.
//  Copyright © 2017年 CaoXueLiang.cn. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol JSDownloadAnimationDelegate <NSObject>
- (void)startDownLoad;
@end

@interface DownLoadProgressView : UIView
@property (nonatomic,weak) id<JSDownloadAnimationDelegate> delegate;
/**
 进度条的进度
 */
@property (nonatomic,assign) CGFloat progress;
@end

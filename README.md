# ProgressView
一个炫酷的进度条动画

最近在看[@kitten Yang](http://kittenyang.com)的《A GUIDE TO IOS ANIMATION 2.0》这本书，学到了很多做动画的知识。在网上看到了下面这个[下载动画](https://www.uplabs.com/posts/download-animation)，非常炫酷，于是想自己动手实现一下。

![download.gif](http://upload-images.jianshu.io/upload_images/979175-d8c9cdafe12c4447.gif?imageMogr2/auto-orient/strip)

####动画分解
> 任何复杂的动画都是由一个个简单的动画组合而成的

可以使用Mac自带的Keynote逐帧查看视频或者GIF。通过逐帧查看动画，我们可以观察到该动画都是由CoreAnimation基本动画组合而成的，下面我们来分析一下动画的几个关键帧。

######1. 第一步动画
![动画第一步.png](http://upload-images.jianshu.io/upload_images/979175-79f9ebd0d313f685.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
我们可以看到该动画分为两步：
1. 箭头的竖线变化为点。
2. 箭头变化为直线，并且伴随有弹簧效果。
```
/*竖线-->点*/
- (void)VerticalLineToPointAnimation{
CAKeyframeAnimation *keyAnimation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
keyAnimation.values = @[(__bridge id)[self beginVerticalLinePath].CGPath,
(__bridge id)[self verticalLinePointPath].CGPath];
keyAnimation.duration = 1;
keyAnimation.beginTime = CACurrentMediaTime();
keyAnimation.delegate = self;
keyAnimation.removedOnCompletion = NO;
keyAnimation.fillMode = kCAFillModeForwards;
[keyAnimation setValue:@"lineToPoint" forKey:AnimationKey];
[self.verticalLineLayer addAnimation:keyAnimation forKey:nil];
}
```

```
/*箭头-->直线*/
- (void)arrowToLineAnimation{
CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
animation.values = @[(__bridge id)[self beginArrawPath].CGPath,
(__bridge id)[self arrowDownPath].CGPath,
(__bridge id)[self arrowUpPath].CGPath,
(__bridge id)[self horizontalArrowLinePath].CGPath,];
animation.duration = 1.4;
animation.keyTimes = @[@0,@0.15,@0.25,@0.28];
animation.removedOnCompletion = NO;
animation.fillMode = kCAFillModeForwards;
animation.delegate = self;
animation.beginTime = CACurrentMediaTime() + 0.6;
[animation setValue:@"arrowToLine" forKey:AnimationKey];
[self.arrowsLayer addAnimation:animation forKey:nil];
}
```
######2. 第二步动画
![第二步.png](http://upload-images.jianshu.io/upload_images/979175-6642a1c48bc99070.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这步动画比较简单:就是一个`Position`弹性动画。
```
/*点上弹动画*/
- (void)pointPopUpAnimation{
CASpringAnimation *positionAnimation = [CASpringAnimation animationWithKeyPath:@"position"];
positionAnimation.toValue = [NSValue valueWithCGPoint:CGPointMake(0, -(CGRectGetHeight(self.frame)/2.0) + CircleLineWidth/2.0 + 1)];
positionAnimation.mass = 1.0;
positionAnimation.damping = 10.0;
positionAnimation.initialVelocity = 0.0;
positionAnimation.duration = 1;
positionAnimation.removedOnCompletion = NO;
positionAnimation.fillMode = kCAFillModeForwards;
positionAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
positionAnimation.delegate = self;
[positionAnimation setValue:@"popUp" forKey:AnimationKey];
[self.verticalLineLayer addAnimation:positionAnimation forKey:nil];
}
```

######3. 第三步动画
![第三步动画.png](http://upload-images.jianshu.io/upload_images/979175-f54c498faf603b54.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这一步动画比较多,我们一个一个来看：
1. 根据下载进度`Progress`绘制圆环。
2. 箭头直线变为正弦曲线波浪线，通过改变相位，进行移动。
3. 下载进度标签，`Size`从小变大，`alpha`透明度从零到一，根据`progress`实时更新。
```
/**下载进度path*/
- (UIBezierPath *)circleProgressPath{
CGFloat startPoint = M_PI*3/2.0;
CGFloat endAngle = startPoint - M_PI*2.0 *_progress;
UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetWidth(self.frame)/2.0, CGRectGetHeight(self.frame)/2.0) radius:CGRectGetWidth(self.frame)/2.0 startAngle:startPoint endAngle:endAngle clockwise:NO];
return circlePath;
}
```

```
/*波浪线path*/
- (UIBezierPath *)wavePathMenthod{
UIBezierPath *wavePath = [UIBezierPath bezierPath];
CGFloat start = (CGRectGetWidth(self.frame) - _horizontalArrowWidth)/2.0;
[wavePath moveToPoint:CGPointMake(start,CGRectGetHeight(self.frame)/2.0)];
CGFloat Y = 0.0;
for (int i = start; i <= start + _horizontalArrowWidth; i++) {
Y = _amplitude *sinf(_angularVelocity * i + _offSetX) + _offSetY;
[wavePath addLineToPoint:CGPointMake(i, Y)];
}
return wavePath;
}
```

通过CADisplayLink定时器实时重绘界面。
```
- (void)UpDate:(CADisplayLink *)link{
self.circleLayer.path = [self circleProgressPath].CGPath;
self.offSetX += 0.3;
self.arrowsLayer.path = [self wavePathMenthod].CGPath;
self.progressLabel.text = [NSString stringWithFormat:@"%.0f %@",_progress *100,@"%"];

if (_progress == 1.0) {
[_link invalidate];
}
}
```
######4. 第四步动画

![第四步动画.png](http://upload-images.jianshu.io/upload_images/979175-594ebca0280399a5.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

这一段动画也由两部分构成：
1. 波浪线变为对勾`Path`动画。
2. 下载进度标签`Size`和`alpha`动画组合。
```
/*波浪线--->对勾*/
- (void)curveToCheckAnimation{
CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
animation.values = @[(__bridge id)[self horizontalArrowLinePath].CGPath,(__bridge id)[self checkPath].CGPath];
animation.duration = 0.3;
animation.removedOnCompletion = NO;
animation.fillMode = kCAFillModeForwards;
animation.delegate = self;
[animation setValue:@"cureToCheck" forKey:AnimationKey];
[self.arrowsLayer addAnimation:animation forKey:nil];
}
```

```
/*将进度label缩小*/
[UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
self.progressLabel.bounds = CGRectMake(0, 0,5,2);
self.progressLabel.font = [UIFont systemFontOfSize:5];
self.progressLabel.alpha = 0.0;
} completion:^(BOOL finished) {
self.progressLabel.hidden = YES;
}];
```
######5. 第五步动画

![第五步动画.png](http://upload-images.jianshu.io/upload_images/979175-dbf43e064540c791.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)
这部分动画分为三步:
1. 圆环线宽`lineWidth`变为0，透明度`opacity`变为0。
2. 对勾变为初始箭头的`path`动画。
3. 对勾左侧部分变为箭头竖线的`path`动画。
```
/*进度圆环变细,透明度变0*/
- (void)progressCircleToAlpha{
CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"lineWidth"];
animation.toValue = @0.5;
animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];

CABasicAnimation *animation2 = [CABasicAnimation animationWithKeyPath:@"opacity"];
animation2.toValue = @0;
animation2.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];

CAAnimationGroup *group = [[CAAnimationGroup alloc]init];
group.animations = @[animation,animation2];
group.duration = 1.0;
group.delegate = self;

[group setValue:@"CircleToAlpha" forKey:AnimationKey];
[self.circleLayer addAnimation:group forKey:nil];
}
```

```
/*对勾变箭头*/
- (void)checkToArrowAnimation{
CAKeyframeAnimation *lineAnimation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
lineAnimation.values = @[(__bridge id)[self checkShortLinePath].CGPath,(__bridge id)[self beginVerticalLinePath].CGPath];
lineAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
lineAnimation.duration = 1.0;
lineAnimation.removedOnCompletion = NO;
lineAnimation.fillMode = kCAFillModeForwards;
[self.verticalLineLayer addAnimation:lineAnimation forKey:nil];

CAKeyframeAnimation *checkAnimation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
checkAnimation.values = @[(__bridge id)[self checkPath].CGPath,(__bridge id)[self beginArrawPath].CGPath];
checkAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
checkAnimation.duration = 1.0;
checkAnimation.removedOnCompletion = NO;
checkAnimation.fillMode = kCAFillModeForwards;
[self.arrowsLayer addAnimation:checkAnimation forKey:nil];
}
```

至此，所有的动画已经全部完成。最终效果如下。
![最终效果.gif](http://upload-images.jianshu.io/upload_images/979175-cb65e4a549946ba2.gif?imageMogr2/auto-orient/strip)
####总结
开始看到这个动画时无从下手，但是将动画分解成一个个简单的组合后，就非常简单了。完整的代码到[gitHub下载](https://github.com/CaoXueLiang/AnimationCollection/tree/master/ProgressLoadView)。

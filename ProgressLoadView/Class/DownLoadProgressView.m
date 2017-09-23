//
//  DownLoadProgressView.m
//  ProgressLoadView
//
//  Created by bjovov on 2017/9/21.
//  Copyright © 2017年 CaoXueLiang.cn. All rights reserved.
//

#import "DownLoadProgressView.h"

#define AnimationKey  @"animationKeys"
#define CircleLineWidth 4 //圆环线宽
#define ArrowLineWidth  3 //箭头宽度

@interface DownLoadProgressView()<CAAnimationDelegate>
@property (nonatomic,strong) CADisplayLink *link;
/*白色进度条*/
@property (nonatomic,strong) CAShapeLayer *circleLayer;
/*淡色进度条背景*/
@property (nonatomic,strong) CAShapeLayer *backCircleLayer;
/*箭头竖线*/
@property (nonatomic,strong) CAShapeLayer *verticalLineLayer;
/*箭头端点线*/
@property (nonatomic,strong) CAShapeLayer *arrowsLayer;
/*进度条label*/
@property (nonatomic,strong) UILabel *progressLabel;

/*正弦函数参数*/
/*振幅*/
@property (nonatomic,assign) CGFloat amplitude;
/*角速度*/
@property (nonatomic,assign) CGFloat angularVelocity;
/*初相*/
@property (nonatomic,assign) CGFloat offSetX;
/*偏距*/
@property (nonatomic,assign) CGFloat offSetY;
@end

@implementation DownLoadProgressView{
    CGFloat _middleX;      //中心轴x
    CGFloat _LineHeight;   //竖线长度
    CGFloat _arrowWidth;   //箭头宽度
    CGFloat _arrowHeight;  //箭头长度
    CGFloat _horizontalArrowWidth;//箭头水平宽度
    CGFloat _arrowMoveDownPading; //箭头下移距离
    CGFloat _arrowMoveUpPading;   //箭头上移距离
}

#pragma mark - Init Menthod
- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor colorWithRed:28/255.0 green:136/255.0 blue:238/255.0 alpha:1];
        [self setUp];
        [self addSubViews];
        [self addTapGesture];
    }
    return self;
}

- (void)addSubViews{
    [self.layer addSublayer:self.backCircleLayer];
    [self.layer addSublayer:self.circleLayer];
    [self.layer addSublayer:self.verticalLineLayer];
    [self.layer addSublayer:self.arrowsLayer];
    [self addSubview:self.progressLabel];
}

- (void)setUp{
    /*初始化参数值*/
    _middleX = CGRectGetWidth(self.frame)/2.0;
    _LineHeight = CGRectGetHeight(self.frame) *0.5;
    _arrowWidth = CGRectGetWidth(self.frame) *0.16;
    _arrowHeight = CGRectGetHeight(self.frame) *0.16;
    _horizontalArrowWidth = CGRectGetWidth(self.frame) * 0.7;
    _arrowMoveDownPading = CGRectGetHeight(self.frame) *0.06;
    _arrowMoveUpPading = CGRectGetHeight(self.frame) *0.03;
    
    /*波浪线参数*/
    _amplitude = 3;
    _angularVelocity = 0.3;
    _offSetX = 1;
    _offSetY = CGRectGetHeight(self.frame)/2.0;
}

- (void)addTapGesture{
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(startAniamtion:)];
    tap.numberOfTapsRequired = 1;
    [self addGestureRecognizer:tap];
}

- (void)UpDate:(CADisplayLink *)link{
    self.circleLayer.path = [self circleProgressPath].CGPath;
    self.offSetX += 0.3;
    self.arrowsLayer.path = [self wavePathMenthod].CGPath;
    self.progressLabel.text = [NSString stringWithFormat:@"%.0f %@",_progress *100,@"%"];
    
    if (_progress == 1.0) {
        [_link invalidate];
        /*将进度label缩小*/
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.progressLabel.bounds = CGRectMake(0, 0,5,2);
            self.progressLabel.font = [UIFont systemFontOfSize:5];
            self.progressLabel.alpha = 0.0;
        } completion:^(BOOL finished) {
            self.progressLabel.hidden = YES;
        }];
        [self curveToCheckAnimation];
    }
}

- (void)setProgress:(CGFloat)progress{
    _progress = progress;
}

#pragma mark - Animations
- (void)startAniamtion:(UITapGestureRecognizer *)recognizer{
    //动画开始时不能响应事件
    self.userInteractionEnabled = NO;
    _progress = 0;
    [self VerticalLineToPointAnimation];
    [self arrowToLineAnimation];
}

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

/*对勾放大缩小弹性动画*/
- (void)checkAmplificationMenthod{
    CASpringAnimation *animation = [CASpringAnimation animationWithKeyPath:@"transform"];
    CATransform3D transform = CATransform3DIdentity;
    CATransform3D transitionFrom = CATransform3DScale(transform, 1.1, 1.1, 1);
    CATransform3D transitionTo = CATransform3DScale(transform, 1.0, 1.0, 1);
    animation.fromValue = [NSValue valueWithCATransform3D:transitionFrom];
    animation.toValue = [NSValue valueWithCATransform3D:transitionTo];
    animation.duration = 0.3;
    animation.mass = 1;
    animation.damping = 10.0;
    animation.initialVelocity = 0;
    animation.delegate = self;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [animation setValue:@"checkLarge" forKey:AnimationKey];
    [self.arrowsLayer addAnimation:animation forKey:nil];
}

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

#pragma mark - CAAnimationDelegate
- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if ([[anim valueForKey:AnimationKey] isEqualToString:@"lineToPoint"]) {
        [self pointPopUpAnimation];
        
    }else if ([[anim valueForKey:AnimationKey] isEqualToString:@"popUp"]){
        [_link invalidate];
        _link = nil;
        _link = [CADisplayLink displayLinkWithTarget:self selector:@selector(UpDate:)];
        [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
        
        
        [self.arrowsLayer removeFromSuperlayer];
        self.arrowsLayer = nil;
        [self.layer addSublayer:self.arrowsLayer];
        
        self.progressLabel.hidden = NO;
        [UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.progressLabel.bounds = CGRectMake(0, 0,50,20);
            self.progressLabel.font = [UIFont systemFontOfSize:14];
            self.progressLabel.alpha = 1.0;
        } completion:^(BOOL finished) {
            
            //将verticalLineLayer删除
            [self.verticalLineLayer removeFromSuperlayer];
            self.verticalLineLayer = nil;
            
        }];
        
        if ([self.delegate respondsToSelector:@selector(startDownLoad)]) {
            [self.delegate startDownLoad];
        }
        
    }else if ([[anim valueForKey:AnimationKey] isEqualToString:@"arrowToLine"]){
    
    }else if ([[anim valueForKey:AnimationKey] isEqualToString:@"cureToCheck"]){
        [self checkAmplificationMenthod];
        
    }else if ([[anim valueForKey:AnimationKey]isEqualToString:@"checkLarge"]){
        
        /*对勾绘制完成后,将箭头添加上*/
        self.verticalLineLayer.path = [self checkShortLinePath].CGPath;
        [self.layer addSublayer:self.verticalLineLayer];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self checkToArrowAnimation];
            [self progressCircleToAlpha];
        });
    }else if ([[anim valueForKey:AnimationKey]isEqualToString:@"CircleToAlpha"]){
        [self.circleLayer removeFromSuperlayer];
        self.circleLayer = nil;
        [self.layer addSublayer:self.circleLayer];
        
        //动画结束后才能响应事件
        self.userInteractionEnabled = YES;
    }
}

#pragma mark - UIBezierPath
/**初始竖线path*/
- (UIBezierPath *)beginVerticalLinePath{
    UIBezierPath *linePath = [UIBezierPath bezierPath];
    [linePath moveToPoint:CGPointMake(_middleX, (CGRectGetHeight(self.frame)-_LineHeight)/2.0)];
    [linePath addLineToPoint:CGPointMake(_middleX, ((CGRectGetHeight(self.frame)-_LineHeight)/2.0) + _LineHeight)];
    return linePath;
}

/*竖线变成点后的path*/
- (UIBezierPath *)verticalLinePointPath{
    UIBezierPath *pointPath = [UIBezierPath bezierPath];
    [pointPath moveToPoint:CGPointMake(_middleX, CGRectGetHeight(self.frame)/2.0-3)];
    [pointPath addLineToPoint:CGPointMake(_middleX, CGRectGetHeight(self.frame)/2.0-3)];
    return pointPath;
}

/*竖线变为对勾的左侧*/
- (UIBezierPath *)checkShortLinePath{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect rectInCircle = CGRectInset(self.bounds, self.bounds.size.width*0.3, self.bounds.size.width*0.3);
    [path moveToPoint:CGPointMake(rectInCircle.origin.x + rectInCircle.size.width/9, rectInCircle.origin.y + rectInCircle.size.height*2/3)];
    [path addLineToPoint:CGPointMake(rectInCircle.origin.x + rectInCircle.size.width/3,rectInCircle.origin.y + rectInCircle.size.height*9/10)];
    return path;
}

/**初始箭头path*/
- (UIBezierPath *)beginArrawPath{
    CGFloat currentHeight = ((CGRectGetHeight(self.frame)-_LineHeight)/2.0) + _LineHeight;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(_middleX - _arrowWidth, currentHeight - _arrowHeight)];
    [path addLineToPoint:CGPointMake(_middleX, currentHeight)];
    [path addLineToPoint:CGPointMake(_middleX + _arrowWidth, currentHeight - _arrowHeight)];
    return path;
}

/*箭头下移Path*/
- (UIBezierPath *)arrowDownPath{
    CGFloat currentHeight = ((CGRectGetHeight(self.frame)-_LineHeight)/2.0) + _LineHeight;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(_middleX - _arrowWidth, currentHeight - _arrowHeight + _arrowMoveDownPading)];
    [path addLineToPoint:CGPointMake(_middleX, currentHeight + _arrowMoveDownPading)];
    [path addLineToPoint:CGPointMake(_middleX + _arrowWidth, currentHeight - _arrowHeight + _arrowMoveDownPading)];
    return path;
}

/*箭头上移Path*/
- (UIBezierPath *)arrowUpPath{
    CGFloat start = (CGRectGetWidth(self.frame) - _horizontalArrowWidth)/2.0;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(start, CGRectGetHeight(self.frame)/2.0)];
    [path addLineToPoint:CGPointMake(_middleX, CGRectGetHeight(self.frame)/2.0 - _arrowMoveUpPading)];
    [path addLineToPoint:CGPointMake(start + _horizontalArrowWidth, CGRectGetHeight(self.frame)/2.0)];
    return path;
}

/*箭头变成水平线*/
- (UIBezierPath *)horizontalArrowLinePath{
    CGFloat start = (CGRectGetWidth(self.frame) - _horizontalArrowWidth)/2.0;
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(start, CGRectGetHeight(self.frame)/2.0)];
    [path addLineToPoint:CGPointMake(_middleX, CGRectGetHeight(self.frame)/2.0)];
    [path addLineToPoint:CGPointMake(start + _horizontalArrowWidth, CGRectGetHeight(self.frame)/2.0)];
    return path;
}

/**初始下载进度path*/
- (UIBezierPath *)circleProgressPath{
    CGFloat startPoint = M_PI*3/2.0;
    CGFloat endAngle = startPoint - M_PI*2.0 *_progress;
    UIBezierPath *circlePath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(CGRectGetWidth(self.frame)/2.0, CGRectGetHeight(self.frame)/2.0) radius:CGRectGetWidth(self.frame)/2.0 startAngle:startPoint endAngle:endAngle clockwise:NO];
    return circlePath;
}

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

/*对勾路径*/
- (UIBezierPath *)checkPath{
    UIBezierPath *path = [UIBezierPath bezierPath];
    CGRect rectInCircle = CGRectInset(self.bounds, self.bounds.size.width*0.3, self.bounds.size.width*0.3);
    [path moveToPoint:CGPointMake(rectInCircle.origin.x + rectInCircle.size.width/9, rectInCircle.origin.y + rectInCircle.size.height*2/3)];
    [path addLineToPoint:CGPointMake(rectInCircle.origin.x + rectInCircle.size.width/3,rectInCircle.origin.y + rectInCircle.size.height*9/10)];
    [path addLineToPoint:CGPointMake(rectInCircle.origin.x + rectInCircle.size.width*8/10, rectInCircle.origin.y + rectInCircle.size.height*2/10)];
    return path;
}

#pragma mark - Setter && Getter
- (CAShapeLayer *)backCircleLayer{
    if (!_backCircleLayer) {
        _backCircleLayer = [CAShapeLayer layer];
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:self.frame];
        _backCircleLayer.path = path.CGPath;
        _backCircleLayer.lineWidth = CircleLineWidth;
        _backCircleLayer.strokeColor = [[UIColor whiteColor]colorWithAlphaComponent:0.3].CGColor;
        _backCircleLayer.fillColor = [UIColor clearColor].CGColor;
    }
    return _backCircleLayer;
}

- (CAShapeLayer *)circleLayer{
    if (!_circleLayer) {
        _circleLayer = [CAShapeLayer layer];
        _circleLayer.lineWidth = CircleLineWidth;
        _circleLayer.fillColor = [UIColor clearColor].CGColor;
        _circleLayer.strokeColor = [UIColor whiteColor].CGColor;
        //_circleLayer.lineJoin = kCALineJoinRound;
        //_circleLayer.lineCap = kCALineCapRound;
    }
    return _circleLayer;
}

- (CAShapeLayer *)verticalLineLayer{
    if (!_verticalLineLayer) {
        _verticalLineLayer = [CAShapeLayer layer];
        _verticalLineLayer.path = [self beginVerticalLinePath].CGPath;
        _verticalLineLayer.strokeColor = [UIColor whiteColor].CGColor;
        _verticalLineLayer.fillColor = [UIColor clearColor].CGColor;
        _verticalLineLayer.lineCap = kCALineCapRound;
        _verticalLineLayer.lineJoin = kCALineJoinRound;
        _verticalLineLayer.lineWidth = ArrowLineWidth;
    }
    return _verticalLineLayer;
}

- (CAShapeLayer *)arrowsLayer{
    if (!_arrowsLayer) {
        _arrowsLayer = [CAShapeLayer layer];
        _arrowsLayer.path = [self beginArrawPath].CGPath;
        _arrowsLayer.strokeColor = [UIColor whiteColor].CGColor;
        _arrowsLayer.fillColor = [UIColor clearColor].CGColor;
        _arrowsLayer.lineCap = kCALineCapRound;
        _arrowsLayer.lineJoin = kCALineJoinRound;
        _arrowsLayer.lineWidth = ArrowLineWidth;
    }
    return _arrowsLayer;
}

- (UILabel *)progressLabel{
    if (!_progressLabel) {
        _progressLabel = [UILabel new];
        _progressLabel.font = [UIFont systemFontOfSize:5];
        _progressLabel.textColor = [UIColor whiteColor];
        _progressLabel.bounds = CGRectMake(0, 0,5, 2);
        _progressLabel.center = CGPointMake(_middleX, CGRectGetHeight(self.frame)/4.0*3);
        _progressLabel.text = [NSString stringWithFormat:@"%.0f %@",_progress *100,@"%"];
        _progressLabel.textAlignment = NSTextAlignmentCenter;
        _progressLabel.alpha = 0;
        _progressLabel.hidden = YES;
    }
    return _progressLabel;
}

@end



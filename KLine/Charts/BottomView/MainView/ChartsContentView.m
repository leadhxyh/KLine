//
//  ChartsContentView.m
//  KLine
//
//  Created by 陈蕃坊 on 2017/7/29.
//  Copyright © 2017年 DanDanLiCai. All rights reserved.
//

#import "ChartsContentView.h"

//model
#import "TimeLineTotalModel.h"
#import "ChartsDetailStaticDataModel.h"
#import "ChartsDetailDynamicDataModel.h"

//view
#import "ChartsDetailView.h"

@interface ChartsContentView()


//分时图数据模型
@property (nonatomic, strong) TimeLineTotalModel *timeLineTotalModel;

/** 详细信息的view */
@property (nonatomic, weak) ChartsDetailView *detailView;

//图表类型
@property (nonatomic, assign) KLine_Enum_ChartsType chartsType;

/** 区间个数 */
@property (nonatomic, assign) NSUInteger sectionCount;

/** 时间数组 */
@property (nonatomic, strong) NSArray *timeArr;





@end

@implementation ChartsContentView


//=================================================================
//                              初始化
//=================================================================
#pragma mark - 初始化

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        //长按手势
        UILongPressGestureRecognizer *longGes = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
        [self addGestureRecognizer:longGes];
    }
    return self;
}

//=================================================================
//                           懒加载
//=================================================================
#pragma mark - 懒加载
- (NSArray *)timeArr {
    if (_timeArr == nil) {
        _timeArr = @[
                     @"9:30",
                     @"10:00",
                     @"10:30",
                     @"11:00",
                     @"11:30",
                     @"12:00",
                     @"13:30",
                     @"14:00",
                     @"14:30",
                     @"15:00",
                     @"15:30",
                     ];
    }
    
    return _timeArr;
}

- (ChartsDetailView *)detailView {
    if (_detailView == nil) {
        UIView *chartsMainView = self.superview.superview;
        for (UIView *subView in chartsMainView.subviews) {
            if ([subView isMemberOfClass:[ChartsDetailView class]]) {
                _detailView = (ChartsDetailView *)subView;
                break;
            }
        }
    }
    return _detailView;
}



//=================================================================
//                           绘图
//=================================================================
#pragma mark - 绘图

- (void)reDrawWithLineData:(id)lineData chartsType:(KLine_Enum_ChartsType)chartsType {
    self.timeLineTotalModel = lineData;
    self.chartsType = chartsType;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (self.timeLineTotalModel == nil) {
        return;
    }
    
    [self detailView];
    
    self.sectionCount = 11;
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGFloat y = 0;
    CGFloat width = rect.size.width;
    CGFloat x = 0;
    CGFloat height = 0;
    //绘制MA
    height = KLine_Const_MAHeight;
//    [self drawBackgroundInRect:CGRectMake(x, y, width, height) ctx:ctx];
    
    //=================
    //     绘制背景
    //=================
    height = rect.size.height - KLine_Const_MAHeight;
    y = KLine_Const_MAHeight;
    [self drawBackgroundInRect:CGRectMake(x, y, width, height) ctx:ctx];
    
    
    //=================
    //    绘制折线图
    //=================
    height = (rect.size.height - KLine_Const_MAHeight - KLine_Const_DateHeight) * KLine_Const_LinechartHeightRate;
    [self drawChartsLineInRect:CGRectMake(x, y, width, height) ctx:ctx];
    
    //=================
    //    绘制时间
    //=================
    y = y + height;
    height = KLine_Const_DateHeight;
    [self drawDateInRect:CGRectMake(x + 1, y, width - 2, height) ctx:ctx];
    
    
    //=================
    //   绘制成交量
    //=================
    y = y + height;
    height = rect.size.height - y;
    [self drawVolumeInRect:CGRectMake(x, y, width, height) ctx:ctx];
    

    [_detailView reDraw];
    
    
}



//=================================================================
//                           绘制背景
//=================================================================
#pragma mark - 绘制背景

- (void)drawBackgroundInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    CGContextSetStrokeColorWithColor(ctx, KLine_Color_BackgroundLineColor.CGColor);
    //绘制矩形
    CGContextAddRect(ctx, rect);
    
    //绘制竖线
    CGFloat x;
    CGFloat startY = rect.origin.y;
    CGFloat endY = startY + rect.size.height;
    CGFloat width = rect.size.width / self.sectionCount;
    
    for (int i = 1; i < self.sectionCount; i++) {
        x = width * i;
        
        CGContextMoveToPoint(ctx, x, startY);
        CGContextAddLineToPoint(ctx, x, endY);
        CGContextStrokePath(ctx);
    }
    
    _detailView.dynamicDataModel.rect = rect;
    
}

//=================================================================
//                           绘制MA
//=================================================================
#pragma mark - 绘制MA
- (void)drawMAInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
}


//=================================================================
//                         绘制折线图
//=================================================================
#pragma mark - 绘制折线图
- (void)drawChartsLineInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
    CGFloat rectHeight = rect.size.height;
    CGFloat maxY = rect.size.height + rect.origin.y;
    
    //垂直区间数
    NSInteger verticalSections = 6;
    CGFloat verticalPerSectionHeight = rectHeight / verticalSections;
    CGFloat startX = rect.origin.x;
    CGFloat endX = rect.size.width;
    CGFloat y = rect.origin.y;
    
    //画横线
    for (int i = 1; i <= verticalSections; i++) {
        y = y + verticalPerSectionHeight;
        CGContextMoveToPoint(ctx, startX, y);
        CGContextAddLineToPoint(ctx, endX, y);
        CGContextStrokePath(ctx);
    }
    
    //获取最大值，最小值，计算差值
    NSArray <TimeLineModel *>*modelArr = self.timeLineTotalModel.dataArr;
    NSArray *priceArr = [modelArr valueForKeyPath:@"price"];
    CGFloat maxPrice = [[priceArr valueForKeyPath:@"@max.floatValue"] floatValue];
    CGFloat minPrice = [[priceArr valueForKeyPath:@"@min.floatValue"] floatValue];
    CGFloat deltaPrice = maxPrice - minPrice;
    
    
    //计算竖直方向每个像素所代表的价钱（为了使不会太过于充满屏幕，减去一点高度）
    CGFloat verticalPerPxPrice = deltaPrice / (rectHeight - verticalPerSectionHeight);
    //计算水平方向每个分钟占的宽度
    CGFloat averageTimeWidth = rect.size.width / 330;
    
    
    
    //=================
    //     绘制折现图
    //=================
    CGContextSetStrokeColorWithColor(ctx, KLine_Color_TimeLineCharColor.CGColor);
    CGFloat lineX = 0;
    CGFloat lineY;
    CGFloat price = 0;
    for (int i = 0; i < modelArr.count; i++) {
        TimeLineModel *model = modelArr[i];
        price = model.price;
        CGFloat height = (price - minPrice) / verticalPerPxPrice;
        lineX = i * averageTimeWidth;
        lineY = maxY - height;
        
        if (i == 0) {
            CGContextMoveToPoint(ctx, lineX, lineY);
        } else {
            CGContextAddLineToPoint(ctx, lineX, lineY);
        }
    }
    CGContextStrokePath(ctx);
    
    //填充色的处理
    CGContextSetFillColorWithColor(ctx, KLine_Color_TimeLineCharFillColor.CGColor);
    CGContextMoveToPoint(ctx, 0, maxY);
    for (int i = 0; i < modelArr.count; i++) {
        TimeLineModel *model = modelArr[i];
        price = model.price;
        CGFloat height = (price - minPrice) / verticalPerPxPrice;
        lineX = i * averageTimeWidth;
        lineY = maxY - height;
        
        CGContextAddLineToPoint(ctx, lineX, lineY);
    }
    
    CGContextAddLineToPoint(ctx, lineX, maxY);
    CGContextClosePath(ctx);
    CGContextFillPath(ctx);
    
    
    //均线的处理
    CGContextSetStrokeColorWithColor(ctx, KLine_Color_TimeLineAveragePriceColor.CGColor);
    for (int i = 0; i < modelArr.count; i++) {
        TimeLineModel *model = modelArr[i];
        lineX = i * averageTimeWidth;
        CGFloat heiht = (model.averagePrice - minPrice) / verticalPerPxPrice;
        lineY = maxY - heiht;
        
        if (i == 0) {
            CGContextMoveToPoint(ctx, lineX, lineY);
        } else {
            CGContextAddLineToPoint(ctx, lineX, lineY);
        }
    }
    
    CGContextStrokePath(ctx);
    
    
    
    _detailView.staticDataModel.chartRect = rect;
    _detailView.staticDataModel.chartVerticalSections = verticalSections;
    _detailView.staticDataModel.chartVerticalPerSectionHeight = verticalPerSectionHeight;
    _detailView.staticDataModel.prePrice = self.timeLineTotalModel.preClosePrice;
    _detailView.staticDataModel.minPrice = minPrice;
    _detailView.staticDataModel.verticalPerPxPrice = verticalPerPxPrice;
    
    
    //===========================
    //   计算折线图左右边相关数据的值
    //===========================
    
    //跌涨幅相关数据的计算
    CGFloat maxUpAndDown = maxPrice / self.timeLineTotalModel.preClosePrice - 1;
    CGFloat minUpAndDown = minPrice / self.timeLineTotalModel.preClosePrice - 1;
    //竖直方向每一个像素代表的涨跌幅
    CGFloat verticalPerPxUpAndDown = (maxUpAndDown - minUpAndDown) / (rectHeight - verticalPerSectionHeight);
    _detailView.staticDataModel.minUpAndDown = minUpAndDown;
    _detailView.staticDataModel.verticalPerPxUpAndDown = verticalPerPxUpAndDown;
}

//=================================================================
//                        绘制日期、时间
//=================================================================
#pragma mark - 绘制日期、时间
- (void)drawDateInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
    CGContextSetFillColorWithColor(ctx, KLine_Color_BackgroundColor.CGColor);
    CGContextAddRect(ctx, rect);
    CGContextFillPath(ctx);
    
    NSDictionary *attributes = @{
                                NSForegroundColorAttributeName : [UIColor lightGrayColor],
                                NSFontAttributeName : [UIFont systemFontOfSize:KLine_FontSize_TimeAndDateFontSize]
                                };

    CGFloat width = rect.size.width / self.sectionCount;
    
    NSString *timeStr = nil;
    CGFloat x = 0;
    CGFloat y = rect.origin.y;
    for (int i = 0; i < self.sectionCount; i++) {
        x = width * i;
        timeStr = self.timeArr[i];
        [timeStr drawAtPoint:CGPointMake(x, y) withAttributes:attributes];
    }
    
    _detailView.dynamicDataModel.timeRect = rect;
    
}

//=================================================================
//                           绘制MAVOL
//=================================================================
#pragma mark - 绘制MAVOL
- (void)drawMAVOLInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
}


//=================================================================
//                           绘制成交量
//=================================================================
#pragma mark - 绘制成交量
- (void)drawVolumeInRect:(CGRect)rect ctx:(CGContextRef)ctx {
    
    CGContextSetStrokeColorWithColor(ctx, KLine_Color_BackgroundLineColor.CGColor);
    
    //绘制3条横线（3个区块）
    NSInteger verticalSections = 3;
    CGFloat rectHeight = rect.size.height;
    CGFloat verticalPerSectionHeight = rectHeight / verticalSections;
    CGFloat width = rect.size.width;
    CGFloat minY = rect.origin.y;
    CGFloat y = 0;
    CGFloat startX = 0;
    CGFloat endX = width;
    for (int i = 0; i < verticalSections; i++) {
        y = i * verticalPerSectionHeight + minY;
        CGContextMoveToPoint(ctx, startX, y);
        CGContextAddLineToPoint(ctx, endX, y);
        CGContextStrokePath(ctx);
    }
    
    
    
    
    
    //获取交易量的  最大值，最小值，计算差值
    NSArray <TimeLineModel *>*modelArr = self.timeLineTotalModel.dataArr;
    NSArray *volumeArr = [modelArr valueForKeyPath:@"amount"];
    NSInteger maxVolume = [[volumeArr valueForKeyPath:@"@max.integerValue"] integerValue];
    
    //每像素代表多少成交量
    CGFloat verticalPerPxVolume = maxVolume / rectHeight;
    
    //区间个数
    NSInteger sectionCount = 330;
    
    CGFloat volumeX = 0;
    CGFloat volumeY = 0;
    CGFloat volumeWidth = (width - (sectionCount - 1) * KLine_Const_VolumeMargin) / sectionCount;
    CGFloat volumeHeight = 0;
    //昨收价
    CGFloat prePrice = self.timeLineTotalModel.preClosePrice;
    
    for (int i = 0; i < sectionCount; i++) {
        TimeLineModel *model = modelArr[i];
        //跌
        if (model.price < prePrice) {
            
            CGContextSetFillColorWithColor(ctx, KLine_Color_StockFallColor.CGColor);
        } else {
            CGContextSetFillColorWithColor(ctx, KLine_Color_StockRiseColor.CGColor);
        }
        
        prePrice = model.price;
        
        volumeHeight = model.amount / verticalPerPxVolume;
        volumeY = (rectHeight - volumeHeight) + minY;
        volumeX = (KLine_Const_VolumeMargin + volumeWidth) * i;
        CGRect volumeRect = CGRectMake(volumeX, volumeY, volumeWidth, volumeHeight);
        CGContextAddRect(ctx, volumeRect);
        CGContextFillPath(ctx);
    }
    
    
    
    _detailView.staticDataModel.volumeRect = rect;
    _detailView.staticDataModel.maxVolume = maxVolume;
    _detailView.staticDataModel.volumeVerticalSections = verticalSections;
    _detailView.staticDataModel.volumeVerticalPerSectionHeight = verticalPerSectionHeight;
    _detailView.staticDataModel.verticalPerPxVolume = verticalPerPxVolume;
}


//=================================================================
//                           长按手势的处理
//=================================================================
#pragma mark - 长按手势的处理

- (void)longPress:(UILongPressGestureRecognizer *)ges {
    
    //长按结束
    if (ges.state == UIGestureRecognizerStateEnded) {
        _detailView.dynamicDataModel.isLongPress = NO;
        [self.detailView reDraw];
        return;
    }
    
    if (ges.state == UIGestureRecognizerStateBegan) {
        _detailView.dynamicDataModel.isShowFirstValue = YES;
        
    } else {
        _detailView.dynamicDataModel.isShowFirstValue = NO;
    }
    
    
    CGPoint point = [ges locationInView:self.detailView];
    //区间个数
    NSInteger sectionCount = 330;
    
    CGFloat volumeWidth = (self.frame.size.width - (sectionCount - 1) * KLine_Const_VolumeMargin) / sectionCount;
    
    NSInteger index = (NSInteger)(point.x / (volumeWidth + KLine_Const_VolumeMargin));
    
    //防止数组越界
    if (index < 0 || index > self.timeLineTotalModel.dataArr.count - 1) {
        return;
    }
    
    CGFloat touchX = index * (volumeWidth + KLine_Const_VolumeMargin) + volumeWidth / 2.0;
    CGFloat touchY = point.y;
    CGPoint touchPoint = CGPointMake(touchX, touchY);
    
    TimeLineModel *model = self.timeLineTotalModel.dataArr[index];
    _detailView.dynamicDataModel.timeLineModel = model;
    _detailView.dynamicDataModel.date = self.timeLineTotalModel.date;
    _detailView.dynamicDataModel.touchPoint = touchPoint;
    _detailView.dynamicDataModel.isLongPress = YES;
    [self.detailView reDraw];
    
}


@end

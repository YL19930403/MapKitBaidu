//
//  ViewController.m
//  BaiduMap
//
//  Created by 余亮 on 16/2/22.
//  Copyright © 2016年 余亮. All rights reserved.
//

#import "ViewController.h"
#import <BaiduMapAPI/BMapKit.h>
#import "BNCoreServices.h"

@interface ViewController ()<BMKMapViewDelegate,BMKPoiSearchDelegate,BNNaviRoutePlanDelegate>{
    BMKPointAnnotation * _selection ;
}

@property (weak, nonatomic) IBOutlet BMKMapView *MapView;

@property(nonatomic,strong)BMKPoiSearch * searcher ;
@end

@implementation ViewController

- (BMKPoiSearch *)searcher
{
    if (!_searcher) {
        _searcher = [[BMKPoiSearch alloc] init];
        _searcher.delegate = self ;
    }
    return _searcher ;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.MapView.delegate = self ;



}

- (void)addAnnoWithPT:(CLLocationCoordinate2D)coor andTitle:(NSString *)title andAddress:(NSString *)address
{
    //    // 添加一个PointAnnotation
    BMKPointAnnotation* annotation = [[BMKPointAnnotation alloc]init];
    annotation.coordinate = coor;
    annotation.title = title ;
    annotation.subtitle = address ;
   [self.MapView addAnnotation:annotation];
}


//发起导航
- (void)startNaviWithEndPT:(CLLocationCoordinate2D)endPT
{
    //节点数组
    NSMutableArray *nodesArray = [[NSMutableArray alloc]    initWithCapacity:2];
    
    //起点
    BNRoutePlanNode *startNode = [[BNRoutePlanNode alloc] init];
    startNode.pos = [[BNPosition alloc] init];
    startNode.pos.x = 113.375924;
    startNode.pos.y = 23.132931 ;
    startNode.pos.eType = BNCoordinate_BaiduMapSDK;
    [nodesArray addObject:startNode];
    
    //终点
    BNRoutePlanNode *endNode = [[BNRoutePlanNode alloc] init];
    endNode.pos = [[BNPosition alloc] init];
    endNode.pos.x = endPT.longitude;
    endNode.pos.y = endPT.latitude;
    endNode.pos.eType = BNCoordinate_BaiduMapSDK;
    [nodesArray addObject:endNode];
    //发起路径规划
    [BNCoreServices_RoutePlan startNaviRoutePlan:BNRoutePlanMode_Recommend naviNodes:nodesArray time:nil delegete:self userInfo:nil];
}

- (void)mapView:(BMKMapView *)mapView regionDidChangeAnimated:(BOOL)animated
{
    NSLog(@"%lf - %lf",mapView.region.span.latitudeDelta,mapView.region.span.longitudeDelta);
}


//点击大头针的时候调用
- (void)mapView:(BMKMapView *)mapView didSelectAnnotationView:(BMKAnnotationView *)view
{
    _selection = view.annotation ;
}

//长按的时候调用
- (void)mapview:(BMKMapView *)mapView onLongClick:(CLLocationCoordinate2D)coordinate
{
    //发起检索
    self.searcher.delegate = self ;
    BMKNearbySearchOption *option = [[BMKNearbySearchOption alloc]init];
    option.pageIndex = 0;
    option.pageCapacity = 10;
    option.location = coordinate ;//(CLLocationCoordinate2D){39.915, 116.404};
    option.keyword = @"小吃";
    BOOL flag = [_searcher poiSearchNearBy:option];
    if(flag)
    {
        NSLog(@"周边检索发送成功");
    }
    else
    {
        NSLog(@"周边检索发送失败");
    }
    
    CLLocationCoordinate2D center = option.location ;
    BMKCoordinateSpan span = BMKCoordinateSpanMake(0.021686, 0.014705);
    BMKCoordinateRegion region = BMKCoordinateRegionMake(center, span);
    [self.MapView setRegion:region animated:YES];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
//    [self.MapView setCenterCoordinate:CLLocationCoordinate2DMake(23.132931, 113.375924)];
}

#pragma mark - BNNaviRoutePlanDelegate
//算路成功回调
-(void)routePlanDidFinished:(NSDictionary *)userInfo
{
    NSLog(@"算路成功");
    
    //路径规划成功，开始导航
    [BNCoreServices_UI showNaviUI: BN_NaviTypeReal delegete:self isNeedLandscape:YES];
}

//实现PoiSearchDeleage处理回调结果
- (void)onGetPoiResult:(BMKPoiSearch*)searcher result:(BMKPoiResult*)poiResultList errorCode:(BMKSearchErrorCode)error
{
    if (error == BMK_SEARCH_NO_ERROR) {
        //在此处理正常结果
//        NSLog(@"%@",poiResultList.poiInfoList);
        [poiResultList.poiInfoList enumerateObjectsUsingBlock:^(BMKPoiInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self addAnnoWithPT:obj.pt andTitle:obj.name andAddress:obj.address];
            
        }];
    }
    else if (error == BMK_SEARCH_AMBIGUOUS_KEYWORD){
        //当在设置城市未找到结果，但在其他城市找到结果时，回调建议检索城市列表
        // result.cityList;
        NSLog(@"起始点有歧义");
    } else {
        NSLog(@"抱歉，未找到结果");
    }
}

- (BMKAnnotationView *)mapView:(BMKMapView *)mapView viewForAnnotation:(id <BMKAnnotation>)annotation
{
    if ([annotation isKindOfClass:[BMKPointAnnotation class]]) {
        //大头针的循环利用
        static NSString * ID = @"annotation";
        BMKPinAnnotationView *newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ID];
        if (newAnnotationView == nil) {
            newAnnotationView = [[BMKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:ID];
        }
        newAnnotationView.annotation = annotation ;
        
        newAnnotationView.pinColor = BMKPinAnnotationColorPurple;
        newAnnotationView.animatesDrop = YES;// 设置该标注点动画显示
        
        UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeContactAdd];
        newAnnotationView.rightCalloutAccessoryView = rightBtn ;
        [rightBtn addTarget:self action:@selector(rightBtnClick) forControlEvents:UIControlEventTouchUpInside];
        
        return newAnnotationView;
    }
    return nil;
}

- (void) rightBtnClick
{
    CLLocationCoordinate2D coordinate = _selection.coordinate ;
    [self startNaviWithEndPT:coordinate];
}

@end

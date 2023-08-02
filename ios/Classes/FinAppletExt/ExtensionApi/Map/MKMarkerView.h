//
//  MKMarkerView.h
//  FBRetainCycleDetector
//
//  Created by 王兆耀 on 2021/9/14.
//

#import <MapKit/MapKit.h>

NS_ASSUME_NONNULL_BEGIN

///标记
@interface MKMarker : NSObject <MKAnnotation>
@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *subtitle;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, copy) NSString *idString;
@end

@interface MKMarkerView : MKAnnotationView

+ (instancetype)dequeueMarkerViewWithMap:(MKMapView *)mapView annotation:(id<MKAnnotation>)annotation;

@end

NS_ASSUME_NONNULL_END

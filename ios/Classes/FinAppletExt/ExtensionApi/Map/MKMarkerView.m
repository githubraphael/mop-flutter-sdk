//
//  MKMarkerView.h
//  FBRetainCycleDetector
//
//  Created by 王兆耀 on 2021/9/14.
//

#import "MKMarkerView.h"

@implementation MKMarker
@synthesize title;
@synthesize coordinate = _coordinate;

- (void)setCoordinate:(CLLocationCoordinate2D)newCoordinate {
    _coordinate = newCoordinate;
}

- (CLLocationCoordinate2D)coordinate {
    return _coordinate;
}

@end

@interface MKMarkerView ()
@property (nonatomic, strong) UIImageView *imageView;
@end

@implementation MKMarkerView

+ (instancetype)dequeueMarkerViewWithMap:(MKMapView *)mapView annotation:(id<MKAnnotation>)annotation {
    if ([annotation isKindOfClass:MKMarker.class]) {
        MKMarker *marker = (MKMarker *)annotation;
        MKMarkerView *markerView = (MKMarkerView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"markerView"];
        if (markerView == nil) {
            markerView = [[MKMarkerView alloc] initWithAnnotation:marker reuseIdentifier:@"markerView"];
        }
        markerView.annotation = marker;
        markerView.image = marker.image;
        return markerView;
    }
    return nil;
}

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
        //        self.calloutOffset = CGPointMake(0.5f, 0.97f);
        self.canShowCallout = YES; //显示标题与描述
                                   //        [self addSubview:self.imageView];
    }
    return self;
}

- (BOOL)isEnabled {
    return YES;
}

- (BOOL)isSelected {
    return YES;
}

@end

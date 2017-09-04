//
//  ShadowView.m
//  it2
//
//  Created by Vasiliy Makarov on 17.04.13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "ShadowView.h"

@implementation ShadowView

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        CAGradientLayer *gradient = (CAGradientLayer*)self.layer;
        UIColor* lightColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
        UIColor* darkColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
        gradient.colors = [NSArray arrayWithObjects:
                           (id)darkColor.CGColor,
                           (id)lightColor.CGColor,
                           nil];
        gradient.locations = [NSArray arrayWithObjects:
                              [NSNumber numberWithFloat:0.0f],
                              [NSNumber numberWithFloat:1.0f],
                              nil];
    }
    return self;
}

@end

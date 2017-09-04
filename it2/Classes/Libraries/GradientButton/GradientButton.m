//
//  GradientButton.m
//  it2
//
//  Created by Vasiliy Makarov on 16.03.13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "GradientButton.h"

@interface GradientButton () {
    UIColor* bg2;
}

@end

@implementation GradientButton

+(id)buttonWithType:(UIButtonType)buttonType
{
    GradientButton *b = [[GradientButton alloc] init];
    return b;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super initWithCoder:aDecoder])) {
        [self setupView];
    }
    return self;
}

-(id)initWithFrame:(CGRect)frame
{
    if((self = [super initWithFrame:frame])) {
        [self setupView];
    }
    return self;
}

-(id)init
{
    if((self = [super init])) {
        [self setupView];
    }
    return self;
}

+ (Class)layerClass {
    return [CAGradientLayer class];
}

- (void)setupView
{
    self.layer.cornerRadius = 10;
    self.layer.borderWidth = 1.0;
    self.layer.borderColor = [UIColor whiteColor].CGColor;//[UIColor colorWithRed:167.0/255.0 green:140.0/255.0 blue:98.0/255.0 alpha:0.5].CGColor;
    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowRadius = 3.0;
    if(bg2 == nil)
        self.backgroundColor = [UIColor grayColor];
}

-(void)setBackgroundColor:(UIColor *)backgroundColor
{
    super.backgroundColor = backgroundColor;
    CGFloat r, g, b, a;
    if(![backgroundColor getRed:&r green:&g blue:&b alpha:&a]) {
        if([backgroundColor getWhite:&r alpha:&a]) {
            r = 1.f - (1.f-r)*0.7f;
            bg2 = [UIColor colorWithWhite:r alpha:a];
        } else {
            NSLog(@"not compatible color space");
            
        }
    } else {
        r = 1.f - (1.f-r)*0.7f;
        g = 1.f - (1.f-g)*0.7f;
        b = 1.f - (1.f-b)*0.7f;
        bg2 = [UIColor colorWithRed:r green:g blue:b alpha:a];
    }
    [self clearHighlightView];
}

- (void)highlightView
{
    self.layer.shadowOffset = CGSizeMake(1.0f, 1.0f);
    self.layer.shadowOpacity = 0.25;
    CAGradientLayer *gradient = (CAGradientLayer*)self.layer;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)self.backgroundColor.CGColor,
                       (id)bg2.CGColor,
                       nil];
    gradient.locations = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0.0f],
                          [NSNumber numberWithFloat:1.0f],
                          nil];
}

- (void)clearHighlightView {
    self.layer.shadowOffset = CGSizeMake(2.0f, 2.0f);
    self.layer.shadowOpacity = 0.5;
    CAGradientLayer *gradient = (CAGradientLayer*)self.layer;
    gradient.colors = [NSArray arrayWithObjects:
                       (id)bg2.CGColor,
                       (id)self.backgroundColor.CGColor,
                       nil];
    gradient.locations = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0.0f],
                          [NSNumber numberWithFloat:1.0f],
                          nil];
}

- (void)setHighlighted:(BOOL)highlighted
{
    if (highlighted) {
        [self highlightView];
    } else {
        [self clearHighlightView];
    }
    [super setHighlighted:highlighted];
}

-(void)dealloc
{
    bg2 = nil;
}

@end

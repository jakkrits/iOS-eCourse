//
//  ColourSwitcher.m
//  it2
//

#import "ColorSwitcher.h"

@implementation ColorSwitcher

@synthesize tintColor;

@synthesize hue, saturation, processedImages, brightness, contrast;

-(id)initWithScheme:(NSString*)scheme
{
    self = [super init];
    
    if(self)
    {
        self.processedImages = [NSMutableDictionary dictionary];
        if([scheme isEqualToString:@"gray"])
        {
            hue = 5;
            saturation = 0.25;
            brightness = 0;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:110.0/255.0 green:100.0/255 blue:118.0/255 alpha:1.0];
        }
        else if([scheme isEqualToString:@"blue"])
        {         
            hue = 0;
            saturation = 1;
            brightness = 0;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:0.0 green:68.0/255 blue:118.0/255 alpha:1.0];
        }
        else if([scheme isEqualToString:@"magenta"])
        {
            hue = 0.713114;
            saturation = 0.760714;
            brightness = 0;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:100.0/255 green:20.0/255 blue:120.0/255 alpha:1.0];
        }
        else if([scheme isEqualToString:@"pink"])
        {
            hue = 1.8;
            saturation = 1;
            brightness = 0;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:183.0/255 green:67.0/255 blue:156.0/255 alpha:1.0];;
        }
        else if([scheme isEqualToString:@"red"])
        {
            hue = 2.3;
            saturation = 0.9;
            brightness = -0.1;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:140.0/255 green:38.0/255 blue:25.0/255 alpha:1.0];
        }
        else if([scheme isEqualToString:@"orange"])
        {
            hue = 2.7;
            saturation = 1.2;
            brightness = 0;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:140.0/255 green:58.0/255 blue:15.0/255 alpha:1.0];
        }
        else if([scheme isEqualToString:@"yellow"])
        {
            hue = 3.1;
            saturation = 1.0;
            brightness = 0.3;
            contrast = 1.3;
            self.tintColor = [UIColor colorWithRed:150.0/255 green:130.0/255 blue:25.0/255 alpha:1.0];
        }
        else if([scheme isEqualToString:@"brown"])
        {   
            hue = 3.14;
            saturation = 0.760714;
            brightness = 0;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:106.0/255 green:65.0/255 blue:12.0/255 alpha:1.0];
        }
        else if([scheme isEqualToString:@"acid"])
        {
            hue = 5.0;
            saturation = 1.5;
            brightness = 0.25;
            contrast = 1.5;
            self.tintColor = [UIColor colorWithRed:109.0/255 green:197.0/255 blue:34.0/255 alpha:1.0];
        }
        else if([scheme isEqualToString:@"green"])
        {
            hue = 5.0;
            saturation = 1;
            brightness = 0;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:20.0/255 green:118.0/255 blue:15.0/255 alpha:1.0];
        }
        else if([scheme isEqualToString:@"aqua"])
        {
            hue = 5.7;
            saturation = 1;
            brightness = 0.1;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:80.0/255 green:188.0/255 blue:190.0/255 alpha:1.0];
        }
        else
        {
            hue = 0;
            saturation = 1;
            brightness = 0;
            contrast = 1;
            self.tintColor = [UIColor colorWithRed:0.0 green:68.0/255 blue:118.0/255 alpha:1.0];
        }
        
    }
    
    return self;
}


-(UIImage*)processImageWithName:(NSString*)imageName
{
    UIImage* existingImage = [processedImages objectForKey:imageName];
    
    if(existingImage)
    {
        return existingImage;
    }
    
    UIImage* originalImage = [UIImage imageNamed:imageName];
    if(nil == originalImage) return nil;
    
    CIImage *beginImage = [CIImage imageWithData:UIImagePNGRepresentation(originalImage)];
    
    CIContext* context = [CIContext contextWithOptions:nil];
    
    CIFilter* hueFilter = [CIFilter filterWithName:@"CIHueAdjust" keysAndValues:kCIInputImageKey, beginImage, @"inputAngle", [NSNumber numberWithFloat:hue], nil];
    
    CIImage *outputImage = [hueFilter outputImage];
    
    CIFilter* saturationFilter = [CIFilter filterWithName:@"CIColorControls" keysAndValues:kCIInputImageKey, outputImage,
                                  @"inputSaturation", [NSNumber numberWithFloat:saturation],
                                  @"inputBrightness", [NSNumber numberWithFloat:brightness],
                                  @"inputContrast", [NSNumber numberWithFloat:contrast],
                                  nil];
    
    outputImage = [saturationFilter outputImage];

    
    CGImageRef cgimg = [context createCGImage:outputImage fromRect:[outputImage extent]];
    
    
    UIImage *processed;
    if ( [[[UIDevice currentDevice] systemVersion] intValue] >= 4 && [[UIScreen mainScreen] scale] == 2.0 )
    {
        processed = [UIImage imageWithCGImage:cgimg scale:2.0 orientation:UIImageOrientationUp]; 
    }
    else
    {
        processed = [UIImage imageWithCGImage:cgimg]; 
    }
    
    CGImageRelease(cgimg);
    
    [processedImages setObject:processed forKey:imageName];

    return processed;
}

@end
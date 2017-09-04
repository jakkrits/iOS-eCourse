//
//  ColourSwitcher.h
//  it2
//

#import <Foundation/Foundation.h>

@interface ColorSwitcher : NSObject

-(id)initWithScheme:(NSString*)scheme;

@property (nonatomic, retain) UIColor* tintColor;

@property (nonatomic, assign) float hue;
@property (nonatomic, assign) float saturation;
@property (nonatomic, assign) float brightness;
@property (nonatomic, assign) float contrast;

@property (nonatomic, retain) NSMutableDictionary* processedImages;

-(UIImage*)processImageWithName:(NSString*)imageName;

//-(UIImage*)mask:(UIImage*)image;

@end

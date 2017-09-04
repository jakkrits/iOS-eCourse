//
//  UIImage+iPhone5.m
//  
//
//  Created by Valentin Filip on 9/24/12.
//  Copyright (c) 2012 AppDesignVault. All rights reserved.
//

#import "UIImage+iPhone5.h"
#import "AppDelegate.h"

@implementation UIImage (iPhone5)

+ (BOOL)isTall {
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPhone
        && [UIScreen mainScreen].bounds.size.height == 568)
    {
        return YES;
    }
    return NO;
}

+ (UIImage *)tallImageNamed:(NSString *)name {
    
    UIImage *image;
    if ([self isTall]) {
        NSString *fileName = [[[NSFileManager defaultManager] displayNameAtPath:name] stringByDeletingPathExtension];
        NSString *extension = [name pathExtension];
        
        NSString *nameTall = [NSString stringWithFormat:@"%@-568h", fileName];
        if (extension) {
            nameTall = [nameTall stringByAppendingFormat:@".%@", extension];
        }
        image = [[AppDelegate instance].colorSwitcher processImageWithName:nameTall];
    }
    
    if (!image) {
        image = [[AppDelegate instance].colorSwitcher processImageWithName:name];
    }
    
    return image;
}


@end

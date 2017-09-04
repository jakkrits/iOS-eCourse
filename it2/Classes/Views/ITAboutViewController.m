//
//  ITAboutViewController.m
//  it2
//
//  Created by Vasiliy Makarov on 25.03.13.
//
//

#import "ITAboutViewController.h"

@interface ITAboutViewController ()

@end

@implementation ITAboutViewController

-(NSString*)htmlFile
{
    return [[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:@"data/Author"];
}

@end

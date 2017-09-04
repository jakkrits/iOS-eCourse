//
//  ITHelpViewController.m
//  it2
//
//  Created by Vasiliy Makarov on 20.03.13.
//
//

#import "ITHelpViewController.h"

@implementation ITHelpViewController

-(NSString*)htmlFile
{
    return [[NSBundle mainBundle] pathForResource:@"help" ofType:@"html" inDirectory:@"data"];
}

@end

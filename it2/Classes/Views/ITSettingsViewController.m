//
//  ITSettingsViewController.m
//  it2
//
//  Created by Vasiliy Makarov on 23.04.13.
//
//

#import "ITSettingsViewController.h"
#import "AppDelegate.h"

@interface ITSettingsViewController ()

@end

@implementation ITSettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
#pragma mark IASKAppSettingsViewControllerDelegate protocol
- (void)settingsViewController:(IASKAppSettingsViewController *)sender buttonTappedForSpecifier:(IASKSpecifier *)specifier
{
	if ([specifier.key isEqualToString:@"ButtonLogout"]) {
        [[AppDelegate instance] userLogOut];
        [[AppDelegate instance] userLogIn];
    }
}

-(void)settingsViewControllerDidEnd:(IASKAppSettingsViewController *)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

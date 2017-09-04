//
//  DetailThemeiPadController.h
//  ocean
//
//  Created by Tope on 12/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>

#import "MasterViewController.h"
#import "ADVPopoverProgressBar.h"
#import "KSCustomPopoverBackgroundView.h"
#import "PopoverDemoController.h"
#import "ITTextViewController.h"
#import "ITQuizViewController.h"
#import "ITTodoViewController.h"
#import "CMPopTipView.h"
#import <AdMob/GADBannerView.h>

@interface DetailThemeiPadController : UIViewController<UIPopoverControllerDelegate, MasterViewControllerDelegate, PopoverDemoControllerDelegate, UITableViewDataSource, UITableViewDelegate, AVAudioPlayerDelegate, CMPopTipViewDelegate, GADBannerViewDelegate, UISplitViewControllerDelegate> {
}

@property (strong, nonatomic) IBOutlet UINavigationItem *myNavigationItem;
@property (nonatomic, strong) IBOutlet UIToolbar* toolbar;

@property (nonatomic, strong) IBOutlet UIView* shadowView;

@property (nonatomic, strong) IBOutlet UIScrollView* scrollView;

@property (nonatomic, strong) IBOutlet UIBarButtonItem *showPopoverButton;

@property (nonatomic, strong) ADVPopoverProgressBar *progressBar;

@property (nonatomic, strong) UIPopoverController *coursesController;
@property (strong, nonatomic) IBOutlet UIView *viewTestImg;
@property (nonatomic, strong) IBOutlet UILabel *subtitle;
@property (nonatomic, strong) IBOutlet UILabel *courseSubtitle;
@property (nonatomic, strong) IBOutlet UITableView *table;
@property (nonatomic, strong) NSArray *contents;
@property (nonatomic, strong) ITTextViewController *textViewController;
@property (nonatomic, strong) MPMoviePlayerViewController *movieController;
@property (nonatomic, strong) ITQuizViewController *quizViewController;
@property (nonatomic, strong) ITTodoViewController *todoViewController;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) AVPlayer *aPlayer;

@property (nonatomic, strong) IBOutlet UIImageView *logoImage;

-(IBAction)valueChanged:(id)sender;

-(CALayer *)createShadowWithFrame:(CGRect)frame;

-(UIBarButtonItem*)createBarButtonWithImageName:(NSString *)imageName andSelectedImage:(NSString*)selectedImageName;

-(UIBarButtonItem*)createBarButtonWithImageName:(NSString *)imageName selectedImage:(NSString*)selectedImageName andSelector:(SEL)selector;

- (IBAction)showHelp:(id)sender;

- (IBAction)togglePopover:(id)sender;

+(DetailThemeiPadController*)instance;
@end

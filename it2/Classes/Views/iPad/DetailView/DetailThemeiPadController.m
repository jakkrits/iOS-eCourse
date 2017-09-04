//
//  DetailThemeiPadController.m
//  ocean
//
//  Created by Tope on 12/01/2012.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DetailThemeiPadController.h"
#import "AppDelegate.h"
#import "STSegmentedControl.h"
#import "RCSwitchOnOff.h"
#import "PopoverDemoController.h"
#import "CustomPopoverBackgroundView.h"
#import <QuartzCore/QuartzCore.h>
#import "BlockAlertView.h"
#import "MasterCell.h"
#import "SoundViewController.h"
#import "ITHelpViewController.h"
#import "ITLockView.h"
#import "ITAboutViewController.h"

DetailThemeiPadController *_DetailControllerInstance = nil;

@interface DetailThemeiPadController () {
    BOOL interruptedOnPlayback;
    NSTimer *myTimer;
    NSManagedObject *audioContent;
#ifndef NOADS
    GADBannerView *_banner;
#endif
    BOOL adsShown;
}

@property (nonatomic, strong) NSIndexPath *selectedIndex;
@property (nonatomic, strong) UIBarButtonItem *speakerButton;
@property (nonatomic, strong) UIPopoverController *soundController;
@property (nonatomic, strong) UIBarButtonItem *helpItem;
@property (nonatomic, strong) UIBarButtonItem *downloadButton;
@end

@implementation DetailThemeiPadController
@synthesize myNavigationItem;
@synthesize viewTestImg;

@synthesize toolbar, shadowView, progressBar, scrollView, showPopoverButton, coursesController, subtitle, table=_table, contents, textViewController = _textViewController, movieController = _movieController, audioPlayer = _audioPlayer, todoViewController = _todoViewController, selectedIndex, speakerButton, soundController, helpItem;


+(DetailThemeiPadController*)instance
{
    return _DetailControllerInstance;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _DetailControllerInstance = self;
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    if((self = [super initWithCoder:aDecoder])) {
        _DetailControllerInstance = self;
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    if(nil == self.myNavigationItem) self.myNavigationItem = self.navigationItem;
    UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage tallImageNamed:@"ipad-BG-pattern.png"]];
    [self.view setBackgroundColor:bgColor];
    [self.table setBackgroundView:nil];
    [self.table setBackgroundColor:bgColor];
    
    CALayer* shadowLayer = [self createShadowWithFrame:CGRectMake(0, 0, 768, 5)];
    
    [shadowView.layer addSublayer:shadowLayer];
    
    [self.view addSubview:shadowView];
    
    self.helpItem = [self createBarButtonWithImageName:@"bar-icon-help.png" selectedImage:@"bar-icon-help-white.png" andSelector:@selector(showHelp:)];
    UIBarButtonItem *speechItem = [self createBarButtonWithImageName:@"bar-icon-speech.png" selectedImage:@"bar-icon-speech-white.png" andSelector:@selector(showAbout:)];
    self.speakerButton = [self createBarButtonWithImageName:@"speaker1.png" selectedImage:@"speaker1-white.png" andSelector:@selector(showSoundPanel:)];

    if([[AppDelegate instance] certificate] != nil) {
        UIBarButtonItem *cert = [self createBarButtonWithImageName:@"certificate.png" selectedImage:@"certificate.png" andSelector:@selector(showCertificate:)];
        self.myNavigationItem.leftBarButtonItems = [NSArray arrayWithObjects:helpItem, speechItem, self.speakerButton, cert, nil];
    } else {
        self.myNavigationItem.leftBarButtonItems = [NSArray arrayWithObjects:helpItem, speechItem, self.speakerButton, nil];
    }
    
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"downloadable"]) {
        self.downloadButton = [self createBarButtonWithImageName:@"download.png" selectedImage:@"download-white.png" andSelector:@selector(startDownloadingCourse:)];
        self.myNavigationItem.rightBarButtonItems = @[self.downloadButton];
    } else {
        self.myNavigationItem.rightBarButtonItems = nil;
    }
    
    self.table.dataSource = self;
    self.table.delegate = self;
    self.table.layer.cornerRadius = 5;
    self.table.layer.borderWidth = 1;
    self.table.layer.borderColor = [[UIColor lightGrayColor] CGColor];

    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chapterDidChange:) name:nCHAPTER_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressDidChange:) name:nPROGRESS_CHANGED object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstStart:) name:nFIRST_START object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showHelp:) name:nSHOW_HELP object:nil];
    [self.logoImage setImage:[UIImage imageNamed:@"data/Icon-72.png"]];
    [self.courseSubtitle setText:[AppDelegate instance].subtitle];

    NSManagedObject *curCh = [AppDelegate instance].curChapter;
    if(curCh != nil) [self processChapter:curCh];
    
#ifndef NOADS
    if(AdMob) {
        // Создание представления стандартного размера внизу экрана.
        _banner = [[GADBannerView alloc]
                   initWithFrame:CGRectMake((self.view.frame.size.width-GAD_SIZE_468x60.width)*.5f,
                                            self.view.frame.size.height,
                                            GAD_SIZE_468x60.width,
                                            GAD_SIZE_468x60.height)];
        [_banner setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        // Назначение идентификатора объявлению. Указывается идентификатор издателя AdMob.
        _banner.adUnitID = [AppDelegate instance].adMobId;
        _banner.delegate = self;
        
        // Укажите, какой UIViewController необходимо восстановить после перехода
        // пользователя по объявлению и добавить в иерархию представлений.
        _banner.rootViewController = [AppDelegate instance].window.rootViewController;
        [self.view addSubview:_banner];
        
        // Инициирование общего запроса на загрузку вместе с объявлением.
        GADRequest *request = [GADRequest request];
        [_banner loadRequest:request];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideBanner:) name:nHIDE_ADS object:nil];
    }
#endif
}

-(void)viewDidAppear:(BOOL)animated
{
    myTimer = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSRunLoopCommonModes];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [myTimer invalidate];
    myTimer = nil;
}

- (IBAction)showHelp:(id)sender
{
    ITHelpViewController *hvc = (ITHelpViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"HelpViewController"];
    hvc.modalPresentationStyle = UIModalPresentationFormSheet;
    hvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:hvc animated:YES completion:^(void){}];
}

-(IBAction)showAbout:(id)sender
{
    ITAboutViewController *hvc = (ITAboutViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
    hvc.modalPresentationStyle = UIModalPresentationFormSheet;
    hvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self presentViewController:hvc animated:YES completion:^(void){}];
}

-(IBAction)showSoundPanel:(id)sender
{
    if(self.soundController != nil) {
        [self.soundController dismissPopoverAnimated:YES];
        self.soundController = nil;
    } else {
        SoundViewController *svc = (SoundViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"SoundViewController"];
        if(self.audioPlayer) svc.audioPlayer = self.audioPlayer;
        else svc.aPlayer = self.aPlayer;
        svc.content = audioContent;
        UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage tallImageNamed:@"ipad-BG-pattern.png"]];
        [svc.view setBackgroundColor:bgColor];
        self.soundController = [[UIPopoverController alloc]initWithContentViewController:svc];
        soundController.popoverBackgroundViewClass = [KSCustomPopoverBackgroundView class];
        [soundController setDelegate:self];
        [soundController presentPopoverFromBarButtonItem:self.speakerButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

-(void)showCertificate:(id)sender
{
    [[AppDelegate instance] showCertificate];
}

-(void)playAudio:(BOOL)play
{
    if(play) {
        [_audioPlayer play];
        [_aPlayer play];
        UIButton *b = (UIButton*)self.speakerButton.customView;
        UIImage *img = [UIImage tallImageNamed:@"speaker2.png"];
        CGRect r = b.frame;
        r.size = img.size;
        b.frame = r;
        [b setImage:img forState:UIControlStateNormal];
        [b setImage:[UIImage tallImageNamed:@"speaker2-white.png"] forState:UIControlStateHighlighted];
    } else {
        [_audioPlayer stop];
        [_aPlayer pause];
        UIButton *b = (UIButton*)self.speakerButton.customView;
        UIImage *img = [UIImage tallImageNamed:@"speaker1.png"];
        CGRect r = b.frame;
        r.size = img.size;
        b.frame = r;
        [b setImage:img forState:UIControlStateNormal];
        [b setImage:[UIImage tallImageNamed:@"speaker1-white.png"] forState:UIControlStateHighlighted];
    }
}

-(IBAction)valueChanged:(id)sender
{
    if([sender isKindOfClass:[UISlider class]])
    {
        UISlider *s = (UISlider*)sender;
        
        if(s.value >= 0.0 && s.value <= 1.0)
        {
            [progressBar setProgress:s.value];
        }
    }
}


-(CALayer *)createShadowWithFrame:(CGRect)frame
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = frame;
    
    
    UIColor* lightColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
    UIColor* darkColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    
    gradient.colors = [NSArray arrayWithObjects:(id)darkColor.CGColor, (id)lightColor.CGColor, nil];
    
    return gradient;
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setViewTestImg:nil];
    [self setMyNavigationItem:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

- (void)popoverDemoControllerDidFinish:(PopoverDemoController *)controller
{
    [self.coursesController dismissPopoverAnimated:YES];
    self.coursesController = nil;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    if(popoverController == self.soundController) {
        self.soundController = nil;
    } else if(popoverController == self.coursesController) {
        self.coursesController = nil;
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showPopover"]) 
    {
        [self togglePopover:nil];
        [[segue destinationViewController] setDelegate:self];
        UIPopoverController *p = [(UIStoryboardPopoverSegue *)segue popoverController];
        p.popoverBackgroundViewClass = [KSCustomPopoverBackgroundView class];
        self.coursesController = p;
        
        coursesController.delegate = self;
    }
}

- (IBAction)togglePopover:(id)sender
{
    if (self.coursesController) {
        [self.coursesController dismissPopoverAnimated:YES];
        self.coursesController = nil;
    }
}



- (void)splitViewController: (UISplitViewController *)splitViewController 
     willHideViewController:(UIViewController *)viewController 
          withBarButtonItem:(UIBarButtonItem *)barButtonItem
       forPopoverController: (UIPopoverController *)popoverController
{
    barButtonItem.title = NSLocalizedString(@"Contents", @"button");
    NSMutableArray *items = [self.myNavigationItem.leftBarButtonItems mutableCopy];
    [items insertObject:barButtonItem atIndex:0];
    self.myNavigationItem.leftBarButtonItems = items;

}


- (void)splitViewController:(UISplitViewController *)splitController 
     willShowViewController:(UIViewController *)viewController
  invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem
{
    NSMutableArray *items = [self.myNavigationItem.leftBarButtonItems mutableCopy];
    [items removeObject:barButtonItem];
    self.myNavigationItem.leftBarButtonItems = items;
}



-(UIBarButtonItem*)createBarButtonWithImageName:(NSString *)imageName andSelectedImage:(NSString*)selectedImageName
{
    UIImage* buttonImage = [UIImage tallImageNamed:imageName];
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button setImage:[UIImage tallImageNamed:selectedImageName] forState:UIControlStateHighlighted];
    
    
    UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return barButton;
}

-(UIBarButtonItem*)createBarButtonWithImageName:(NSString *)imageName selectedImage:(NSString*)selectedImageName andSelector:(SEL)selector
{
    UIImage* buttonImage = [UIImage tallImageNamed:imageName];
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button setImage:[UIImage tallImageNamed:selectedImageName] forState:UIControlStateHighlighted];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return barButton;
}

-(void)viewWillLayoutSubviews
{
    CGRect r = self.view.frame;
    r.origin.x = 0;
    r.origin.y = 0;
    self.scrollView.frame = r;
    [super viewWillLayoutSubviews];
}

-(void)videoPlaybackDidFinish:(NSNotification*)notification
{
    [_movieController dismissMoviePlayerViewControllerAnimated];
    NSTimeInterval pr = _movieController.moviePlayer.currentPlaybackTime;
    [AppDelegate setProgress:pr forContent:[AppDelegate instance].curContent];
    self.movieController = nil;
}

-(void)setVideoPosition:(NSTimer*)timer
{
    [_movieController.moviePlayer setCurrentPlaybackTime:[timer.userInfo floatValue]];
    float length = [[[AppDelegate instance].curContent valueForKey:@"length"] floatValue];
    NSNumber *nl = [NSNumber numberWithFloat:[_movieController.moviePlayer duration]];
    if(length == 0.f) [[AppDelegate instance].curContent setValue:nl forKey:@"length"];
}

#pragma mark - Process Notifications

- (void)chapterDidChange:(NSNotification*)notification
{
    NSManagedObject *chapter = notification.object;
    [self processChapter:chapter];
}

-(void)progressDidChange:(NSNotification*)notification
{
    NSManagedObject *content = notification.object;
    NSInteger ind = [contents indexOfObject:content];
    if(ind != NSNotFound) {
        NSIndexPath *index = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:ind];
        MasterCell *c = (MasterCell*)[self.table cellForRowAtIndexPath:index];
        float rec = [[content valueForKey:@"record"] floatValue];
        c.roundProgress.progress = rec;
    }
}

-(void)processChapter:(NSManagedObject*)chapter
{
    self.myNavigationItem.title = [chapter valueForKey:@"title"];
    self.subtitle.text = [chapter valueForKey:@"name"];
    
    self.contents = [[chapter valueForKey:@"contents"] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        int key1 = [[obj1 valueForKey:@"key"] intValue];
        int key2 = [[obj2 valueForKey:@"key"] intValue];
        if(key1 < key2) return NSOrderedAscending;
        if(key1 > key2) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    float progress = [[chapter valueForKey:@"progress"] floatValue];
    if(progress < 0.f) {
        // chapter is locked
        if(![self.table viewWithTag:-1]) {
            ITLockView *lock = (ITLockView*)[[[NSBundle mainBundle] loadNibNamed:@"LockView_iPad" owner:self options:nil] objectAtIndex:0];
            CGRect r = self.table.frame;
            lock.frame = r;
            lock.tag = -1;
            [lock initLock];
            UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage tallImageNamed:@"ipad-BG-pattern.png"]];
            [self.view addSubview:lock];
        }
    } else {
        UIView *v = nil;
        while((v=[self.view viewWithTag:-1])) {
            [v removeFromSuperview];
        }
    }
    [self.table reloadData];
}

-(void)firstStart:(NSNotification*)notification
{
    ITAboutViewController *hvc = (ITAboutViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
    hvc.modalPresentationStyle = UIModalPresentationFormSheet;
    hvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [hvc setOnCloseHandler:self selector:@selector(firstStart2:) object:nil];
    [self presentViewController:hvc animated:YES completion:^(void){}];
}

-(void)firstStart2:(id)sender
{
    ITHelpViewController *hvc = (ITHelpViewController*)[self.storyboard instantiateViewControllerWithIdentifier:@"HelpViewController"];
    hvc.modalPresentationStyle = UIModalPresentationFormSheet;
    hvc.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [hvc setOnCloseHandler:self selector:@selector(firstStart3:) object:nil];
    [self presentViewController:hvc animated:YES completion:^(void){}];
}

-(void)firstStart3:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showAboutAtFirstStart"];
    CMPopTipView *helpPopTipView = [[CMPopTipView alloc] initWithMessage:NSLocalizedString(@"Press this button to show help", @"button tip")];
    helpPopTipView.delegate = self;
    [helpPopTipView presentPointingAtView:self.helpItem.customView inView:self.view animated:YES];
    [helpPopTipView autoDismissAnimated:YES atTimeInterval:3.f];
}

#pragma mark - UITableViewDataSource

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContentCell";
    
    MasterCell *cell = (MasterCell *)[_table dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.contents == nil) return 0;
    return [self.contents count];
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [contents objectAtIndex:[indexPath indexAtPosition:1]];
    [AppDelegate instance].curContent = object;
    self.selectedIndex = indexPath;
    int type = [[object valueForKey:@"type"] intValue];
    double position = [[object valueForKey:@"progress"] doubleValue];
    switch (type) {
        case 0:
            // video
        {
            [self playAudio:NO];
            NSString *file = [object valueForKey:@"file"];
            if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Video"];
            if(nil != file) {
                // local video file
                _movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:file]];
            } else {
                // remote video file
                _movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:[object valueForKey:@"file"]]];
            }
            [self presentMoviePlayerViewControllerAnimated:_movieController];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_movieController.moviePlayer];
            if(![_movieController.moviePlayer isPreparedToPlay])
                [_movieController.moviePlayer prepareToPlay];
            {
                NSTimer *setVideoPosition = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(setVideoPosition:) userInfo:[NSNumber numberWithFloat:position] repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer:setVideoPosition forMode:NSRunLoopCommonModes];
            }
        }
            break;
        case 1:
            // audio
        {
            [self playAudio:NO];
            self.audioPlayer = nil;
            self.aPlayer = nil;
            audioContent = object;
            CGFloat speed = [[object valueForKey:@"rate"] floatValue];
            NSString *file = [object valueForKey:@"file"];
            if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Audio"];
            if(nil != file) {
                NSError *err;
                _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&err];
                if(err != nil) NSLog(@"%@", err);
                [_audioPlayer setEnableRate:YES];
                [_audioPlayer setDelegate:self];
                [_audioPlayer prepareToPlay];
                [self playAudio:YES];
                [_audioPlayer setCurrentTime:position];
                [_audioPlayer setRate:speed];
            } else {
                // remote audio file
                _aPlayer = [AVPlayer playerWithURL:[NSURL URLWithString:[object valueForKey:@"file"]]];
                [self playAudio:YES];
                [_aPlayer seekToDate:[NSDate dateWithTimeIntervalSince1970:position]];
                [_aPlayer setRate:speed];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(audioPlayerDidFinishPlaying) name:AVPlayerItemDidPlayToEndTimeNotification object:_aPlayer.currentItem];
            }
            
            CMPopTipView *audioPopTipView = [[CMPopTipView alloc] initWithMessage:NSLocalizedString(@"Press this button to show  audio controls", @"button tip")];
            audioPopTipView.delegate = self;
            [audioPopTipView presentPointingAtView:((UIBarButtonItem*)[self.myNavigationItem.leftBarButtonItems lastObject]).customView inView:self.view animated:YES];
            [audioPopTipView autoDismissAnimated:YES atTimeInterval:3.f];
        }
            break;
        case 2:
            // text
            self.textViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            self.textViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            self.textViewController.detailItem = object;
            [self presentViewController:self.textViewController animated:YES completion:^(void){}];
            break;
        case 3:
            // quiz
        {
            NSString *file = [object valueForKey:@"file"];
            if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Quiz"];
            if(nil != file) {
                [self.quizViewController loadQuizFromFile:file];
            } else {
                [self.quizViewController loadQuizFromUrl:[object valueForKey:@"file"]];
            }
            self.quizViewController.detailItem = object;
            self.quizViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            self.quizViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:self.quizViewController animated:YES completion:^(void){}];
        }
            break;
        case 4:
            // todo
        {
            self.todoViewController.detailItem = object;
            NSString *file = [object valueForKey:@"file"];
            if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Todo"];
            if(nil != file) {
                [self.todoViewController loadTodoFromFile:file];
            } else {
                [self.todoViewController loadTodoFromUrl:[object valueForKey:@"file"]];
            }
            self.todoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            self.todoViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:self.todoViewController animated:YES completion:^(void){}];
        }
            break;
    }
}

-(void)configureCell:(MasterCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if(cell.tag == 0) {
        cell.roundProgress.fontSize = 20;
        cell.roundProgress.tintColor = [UIColor colorWithRed:0 green:1.0 blue:0 alpha:0.5];
        cell.tag = 1;
    }
    int lastIndex = [self tableView:self.table numberOfRowsInSection:indexPath.section] - 1;
    if(cell.tag == 1 && indexPath.row == lastIndex) {
        CALayer* shadow = [self createShadowWithFrame:CGRectMake(0, 96, self.view.frame.size.width, 5)];
        shadow.name = @"shadow";
        [cell.layer addSublayer:shadow];
        cell.tag = 2;
    } else if(cell.tag == 2 && indexPath.row != lastIndex) {
        CALayer *sh = nil;
        for (CALayer *l in cell.layer.sublayers) {
            if([l.name isEqualToString:@"shadow"]) {
                sh = l;
                break;
            }
        }
        [sh removeFromSuperlayer];
        cell.tag = 1;
    }
    NSManagedObject *content = [self.contents objectAtIndex:[indexPath indexAtPosition:1]];
    NSString *file = [content valueForKey:@"file"];
    NSInteger type = [[content valueForKey:@"type"] intValue];
    switch (type) {
        case 0:
            // video
            cell.titleLabel.text = NSLocalizedString(@"Video", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Watch the video of this lesson. Obviously, watching the video is the easiest way to learn.", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"video.png"]];

            if([AppDelegate instance].allowSaveVideoToCameraRoll) {
                if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                    file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Video"];
                if(nil != file) {
                    // local video file
                    UIButton *sv = [UIButton buttonWithType:UIButtonTypeCustom];
                    sv.frame = CGRectMake(380, 17, 30, 25);
                    [sv setImage:[UIImage imageNamed:@"share-button.png"] forState:UIControlStateNormal];
                    [cell addSubview:sv];
                    [sv addTarget:self action:@selector(saveVideoTrack:) forControlEvents:UIControlEventTouchDown];
                    sv.tag = [indexPath indexAtPosition:1];
                }
            }
            break;
        case 1:
            // audio
            cell.titleLabel.text = NSLocalizedString(@"Audio", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Listen to this lesson. Use this option when you're doing something else.", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"headphones.png"]];
            break;
        case 2:
            // text
            cell.titleLabel.text = NSLocalizedString(@"Text", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Read the lesson. It helps you to study it thoughtfully.", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"paper.png"]];
            break;
        case 3:
            // quiz
            cell.titleLabel.text = NSLocalizedString(@"Quiz", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Test yourself. Do you remember all the terms from this lesson?", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"penpaper.png"]];
            break;
        case 4:
            // todo
            cell.titleLabel.text = NSLocalizedString(@"ToDo", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Checklist for this lesson. What exactly should you do for getting the result.", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"checklist.png"]];
            break;
        default:
            break;
    }
    NSString *customTitle = [content valueForKey:@"title"];
    if(customTitle != nil && [customTitle length] > 0) cell.titleLabel.text = customTitle;
    NSString *customSubtitle = [content valueForKey:@"subtitle"];
    if(customSubtitle != nil && [customSubtitle length] > 0) cell.textLabel.text = customSubtitle;
    float record = [[content valueForKey:@"record"] floatValue];
    [cell.roundProgress setProgress:record];
}

-(ITTextViewController*)textViewController
{
    if(_textViewController == nil) {
        _textViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TextViewController"];
    }
    return _textViewController;
}

-(ITQuizViewController*)quizViewController
{
    if(_quizViewController == nil) {
        _quizViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"QuizViewController"];
    }
    return _quizViewController;
}

-(ITTodoViewController*)todoViewController
{
    if(_todoViewController == nil) {
        _todoViewController = [self.storyboard  instantiateViewControllerWithIdentifier:@"TodoViewController"];
    }
    return _todoViewController;
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerBeginInterruption: (AVAudioPlayer *) player {
    if ([player isPlaying]) {
        interruptedOnPlayback = YES;
    }
}

- (void) audioPlayerEndInterruption: (AVAudioPlayer *) player {
    if (interruptedOnPlayback) {
        [player prepareToPlay];
        [player play];
        interruptedOnPlayback = NO;
    }
}

-(void)audioPlayerDidFinishPlaying
{
    [self audioPlayerDidFinishPlaying:nil successfully:YES];
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if(flag) {
        [AppDelegate setProgress:[[audioContent valueForKey:@"length"] floatValue] forContent:audioContent];
    }
    [self playAudio:NO];
    self.audioPlayer = nil;
    self.aPlayer = nil;
    audioContent = nil;
    if(self.soundController != nil) {
        [self.soundController dismissPopoverAnimated:YES];
        self.soundController = nil;
    }
}

#pragma mark - CMPopTipViewDelegate

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    // nothing to do
}

#pragma mark -

-(void) updateTimer:(NSTimer*)timer
{
    float position = -1.f;
    float length = -1.f;
    if(_audioPlayer != nil && audioContent != nil) {
        position = _audioPlayer.currentTime;
        length = _audioPlayer.duration;
    } else
    if(_aPlayer != nil && audioContent != nil) {
        AVPlayerItem *playerItem = [_aPlayer currentItem];
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            length = CMTimeGetSeconds([[playerItem asset] duration]);
        }
        position = CMTimeGetSeconds(_aPlayer.currentTime);
    }
    if(length > 0.f) [audioContent setValue:[NSNumber numberWithFloat:length] forKey:@"length"];
    if(position >= 0.f) [AppDelegate setProgress:position forContent:audioContent];
}

-(void)startDownloadingCourse:(id)sender
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"downloadable"]) return;

    BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"Start downloading", @"download confirmation") message:NSLocalizedString(@"Do you want to download all course content?", @"download confirmation")];
    
    [alert setDestructiveButtonWithTitle:NSLocalizedString(@"Cancel", @"cancel downloading") block:nil];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"") block:^{
        [[AppDelegate instance] downloadAllContent];
    }];
    [alert show];
}

-(void)saveVideoTrack:(UIButton*)sender
{
    NSManagedObject *content = [self.contents objectAtIndex:sender.tag];
    NSString *file = [content valueForKey:@"file"];
    NSInteger type = [[content valueForKey:@"type"] intValue];
    if(type == 0) {
            // video
        if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
            file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Video"];
        if(nil != file) {
            // local video file
            if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(file)) {
                UISaveVideoAtPathToSavedPhotosAlbum(file, self, @selector(videoTrackSavedToCameraRoll:withError:userData:), (__bridge void *)(sender));
            } else {
                NSLog(@"Video file not compatible: %@", file);
            }
        }
    }
}

-(void)videoTrackSavedToCameraRoll:(NSString*)file withError:(NSError*)error userData:(void*)data
{
    UIButton *bt = (__bridge UIButton*)data;
    NSManagedObject *content = [self.contents objectAtIndex:bt.tag];
    NSString *customTitle = [content valueForKey:@"title"];
    if(nil == customTitle || customTitle.length <= 0) customTitle = NSLocalizedString(@"Video file", @"video file title");
    NSString *msg = NSLocalizedString(@"was saved to camera roll", @"file saved message");
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:customTitle message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"button") otherButtonTitles: nil];
    [av show];
}

#pragma mark GADBannerViewDelegate

-(void)adViewDidReceiveAd:(GADBannerView *)view
{
    if(!adsShown) {
        [UIView beginAnimations:@"BannerSlide" context:nil];
        CGPoint bc = view.center;
        bc.y -= view.frame.size.height;
        view.center = bc;
        [UIView commitAnimations];
        adsShown = YES;
    }
}

-(void)hideBanner:(NSNotification*)notification
{
#ifndef NOADS
    if(adsShown) {
        [UIView animateWithDuration:1.f animations:^(void){
            CGPoint bc = _banner.center;
            bc.y += _banner.frame.size.height;
            _banner.center = bc;
        } completion:^(BOOL finished) {
            [_banner removeFromSuperview];
            _banner = nil;
        }];
        adsShown = NO;
    }
#endif
}

@end

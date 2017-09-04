//
//  ITTextViewController.m
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 16.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import "ITTextViewController.h"
#import "IASKSettingsReader.h"
#import "AppDelegate.h"

@interface ITTextViewController () {
    UITapGestureRecognizer *recognizer;
}

@end

@implementation ITTextViewController

@synthesize navigationItem, returnButton;

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
    canRecordProgress = NO;
    textLoaded = NO;
    [self.webView setDelegate:self];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(settingDidChange:) name:kIASKAppSettingChanged object:nil];

    self.returnButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleReturnButton:)];
    NSMutableArray *items = [self.navigationItem.leftBarButtonItems mutableCopy];
    if(items == nil) {
        items = [NSMutableArray array];
    }
    [items insertObject:returnButton atIndex:0];
    self.navigationItem.leftBarButtonItems = items;

    [self configureView];
    [self initAdBanner];
}

-(void)viewDidAppear:(BOOL)animated
{
    timer = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    canRecordProgress = YES;

    recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:recognizer];
}

-(void)viewDidDisappear:(BOOL)animated
{
    canRecordProgress = NO;
    [timer invalidate];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)handleReturnButton:(id)sender
{
    [self.view.window removeGestureRecognizer:recognizer];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
}

- (void)handleTapBehind:(UITapGestureRecognizer *)sender
{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        CGPoint location = [sender locationInView:nil]; //Passing nil gives us coordinates in the window
        
        //Then we convert the tap's location into the local view's coordinate system, and test to see if it's in or outside. If outside, dismiss the view.
        
        if (![self.view pointInside:[self.view convertPoint:location fromView:self.view.window] withEvent:nil])
        {
            // Remove the recognizer first so it's view.window is valid.
            [self.view.window removeGestureRecognizer:sender];
            [self dismissViewControllerAnimated:YES completion:^(void){}];
        }
    }
}

#pragma mark - Managing the detail item

- (void)setDetailItem:(id)newDetailItem
{
    if (_detailItem != newDetailItem) {
        _detailItem = newDetailItem;
        
        // Update the view.
        [self configureView];
    }
    
}

-(void) configureView
{
    if(_detailItem && _webView) {
        self.navigationItem.title = [[_detailItem valueForKey:@"chapter"] valueForKey:@"title"];
        NSString *fn, *textFile = [_detailItem valueForKey:@"file"];
        if(![[NSFileManager defaultManager] isReadableFileAtPath:textFile])
            fn = [[NSBundle mainBundle] pathForResource:textFile ofType:nil inDirectory:@"data/Text"];
        else fn = textFile;
        NSURL *url;
        if(nil == fn) {
            // remote file
            url = [NSURL URLWithString:textFile];
        } else {
            // local file
            url = [NSURL fileURLWithPath:fn isDirectory:NO];
        }
        [_webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

#pragma mark - WebViewDelegate methods

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection error", @"web view error") message:NSLocalizedString(@"Can't load web page. Check your Internet connection.", @"web view error description") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

-(void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self setDefaultFontFamily];
    [self setDefaultFontSize];
    float progress = [[_detailItem valueForKey:@"progress"] floatValue] - _webView.frame.size.height;
    if(progress < 0.f) progress = 0.f;
    [_webView.scrollView setContentOffset:CGPointMake(0, progress) animated:YES];
    textLoaded = YES;
}

-(void)setDefaultFontFamily
{
    int ffId = [[[NSUserDefaults standardUserDefaults] valueForKey:@"fontFamily"] intValue];
    NSString *ff = nil;
    switch (ffId) {
        case 0:
            ff = @"Arial";
            break;
        case 1:
            ff = @"Comic Sans MS";
            break;
        case 2:
            ff = @"Courier New";
            break;
        case 3:
            ff = @"Gadget";
            break;
        case 4:
            ff = @"Georgia";
            break;
        case 5:
            ff = @"Helvetica";
            break;
        case 6:
            ff = @"LucidaGrande";
            break;
        case 7:
            ff = @"Palatino";
            break;
        case 8:
            ff = @"Times";
            break;
        case 9:
            ff = @"Tahoma";
            break;
        case 10:
            ff = @"Verdana";
            break;
        default:
            break;
    }
    [_webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"document.body.style.fontFamily = '%@'", ff]];
}

-(void)setDefaultFontSize
{
    NSString *fs = [[NSUserDefaults standardUserDefaults] valueForKey:@"fontSize"];
    [_webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@"document.body.style.fontSize = '%@'", fs]];
}

-(void)updateTimer:(id)userInfo
{
    if(_detailItem && _webView && canRecordProgress && textLoaded) {
        float progress = (_webView.scrollView.contentOffset.y + _webView.scrollView.frame.size.height);
        float length = _webView.scrollView.contentSize.height;
        [_detailItem setValue:[NSNumber numberWithFloat:length] forKey:@"length"];
        [AppDelegate setProgress:progress forContent:_detailItem];
    }
}

#pragma mark kIASKAppSettingChanged notification
- (void)settingDidChange:(NSNotification*)notification {
	if ([notification.object isEqual:@"fontFamily"]) {
        [self setDefaultFontFamily];
    } else if([notification.object isEqual:@"fontSize"]) {
        [self setDefaultFontSize];
    }
}

@end

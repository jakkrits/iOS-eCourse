//
//  ITHtmlViewController.m
//  it2
//
//  Created by Vasiliy Makarov on 25.03.13.
//
//

#import "ITHtmlViewController.h"

@interface ITHtmlViewController () {
    UITapGestureRecognizer *recognizer;
    id closeTarget, closeObject;
    SEL closeSelector;
}
@end

@implementation ITHtmlViewController

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
    [self.webView setDelegate:self];
    
    self.returnButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleReturnButton:)];
    NSMutableArray *items = [self.navigationItem.leftBarButtonItems mutableCopy];
    if(items == nil) {
        items = [NSMutableArray array];
    }
    [items insertObject:returnButton atIndex:0];
    self.navigationItem.leftBarButtonItems = items;
    
    NSURL *url = [NSURL fileURLWithPath:[self htmlFile] isDirectory:NO];
    [_webView loadRequest:[NSURLRequest requestWithURL:url]];
}

-(NSString*) htmlFile
{
    return [[NSBundle mainBundle] pathForResource:@"noname" ofType:@"html" inDirectory:@"data"];
}

-(void)viewDidAppear:(BOOL)animated
{
    recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:recognizer];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setOnCloseHandler:(id)target selector:(SEL)selector object:(id)object
{
    closeTarget = target;
    closeSelector = selector;
    closeObject = object;
}

-(void)handleReturnButton:(id)sender
{
    [self.view.window removeGestureRecognizer:recognizer];
    [self dismissViewControllerAnimated:YES completion:^(void){}];
    [closeTarget performSelector:closeSelector withObject:closeObject afterDelay:1.f];
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
            [closeTarget performSelector:closeSelector withObject:closeObject afterDelay:1.f];
        }
    }
}

#pragma mark - WebViewDelegate methods

-(void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection error", @"web view error") message:NSLocalizedString(@"Can't load web page. Check your Internet connection.", @"web view error description") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    [alert show];
}

@end

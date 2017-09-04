//
//  ITQuizViewController.m
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 19.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import "ITTodoViewController.h"
#import "AppDelegate.h"

#define MAX_TODO_ITEMS 128

@interface ITTodoViewController () {
    int buttonState;
    int states[MAX_TODO_ITEMS];
    UITapGestureRecognizer *recognizer;
}

@end

@implementation ITTodoViewController

@synthesize navigationItem, returnButton;

-(void)setDetailItem:(id)detailItem
{
    _detailItem = detailItem;
    buttonState = (int)[[_detailItem valueForKey:@"progress"] floatValue];
}

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
    UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage tallImageNamed:@"ipad-BG-pattern.png"]];
    [self.scroll setBackgroundColor:bgColor];

    self.returnButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleReturnButton:)];
    self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:self.returnButton, nil];

    _pageControl.backgroundColor = [AppDelegate instance].colorSwitcher.tintColor;
    
    [self initAdBanner];
}

-(void)viewWillAppear:(BOOL)animated
{
    CGRect b = _scroll.frame;
    b.origin = CGPointZero;
    if(AdMob) {
        b.size.height -= 60;
    }
    int i = 0;
    for (NSString* cont in todoContent) {
        ITTodoView* nextItem = [[ITTodoView alloc] initWithFrame:b andContent:cont];
        nextItem.state = states[i];
        nextItem.delegate = self;
        [_scroll addSubview:nextItem];
        b.origin.x += b.size.width;
        i ++;
    }
    b.size.width = b.origin.x;
    [_scroll setContentSize:b.size];
    _scroll.contentOffset = CGPointZero;
    _pageControl.numberOfPages = [todoContent count];
    _pageControl.currentPage = 0;
    currentItemNum = 0;
    self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Task %i from %i", @"todo header"), currentItemNum+1, [todoContent count]];
}

-(void)viewDidAppear:(BOOL)animated
{
    recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:recognizer];
}

-(void)viewDidDisappear:(BOOL)animated
{
    for (UIView *v in _scroll.subviews) {
        [v removeFromSuperview];
    }
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

-(void)loadTodoFromFile:(NSString *)fileName
{
    NSData *plistData = [NSData dataWithContentsOfFile:fileName];
    [self loadTodoFromData:plistData];
}

-(void)loadTodoFromUrl:(NSString *)fileUrl
{
    NSData *plistData = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileUrl]];
    [self loadTodoFromData:plistData];
}

-(void)loadTodoFromData:(NSData*)plistData
{
    NSError *error;
    NSPropertyListFormat format;
    todoContent = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&format error:&error ];
    if (!todoContent) {
        NSLog(@"Failed to read todo list content. Error: %@", error);
    }
    score = 0;
    currentItemNum = 0;
    for(int i=0; i<[todoContent count]; i++) {
        int mask = 0x3 << (i*2);
        int bs = buttonState & mask;
        bs = (bs >> (i*2)) + 1;
        states[i] = bs;
    }
}

#pragma mark - UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    int curpage = scrollView.contentOffset.x / scrollView.frame.size.width;
    _pageControl.currentPage = curpage;
    currentItemNum = curpage;
    self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Task %i from %i", @"todo header"), currentItemNum+1, [todoContent count]];
}

-(IBAction)pageChanged:(id)sender
{
    CGRect r = _scroll.frame;
    r.origin.x = _pageControl.currentPage * r.size.width;
    [_scroll scrollRectToVisible:r animated:YES];
    currentItemNum = _pageControl.currentPage;
    self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Task %i from %i", @"todo header"), currentItemNum+1, [todoContent count]];
}

#pragma mark - ITTodoViewDelegate

-(void) todoView:(ITTodoView *)todo withResult:(int)res
{
    states[currentItemNum] = res;
    [self performSelectorInBackground:@selector(processTodoProgress) withObject:nil];
}

-(void) processTodoProgress
{
    buttonState = 0;
    int rec = 0;
    for(int i=0; i<[todoContent count]; i++) {
        int st = (states[i] - 1) << (i*2);
        buttonState |= st;
        if(states[i] == 3) rec ++;
    }
    float record = ((float)rec)/[todoContent count];
    [_detailItem setValue:[NSNumber numberWithFloat:buttonState] forKey:@"progress"];
    [_detailItem setValue:[NSNumber numberWithFloat:record] forKey:@"record"];
    [[NSNotificationCenter defaultCenter] postNotificationName:nPROGRESS_CHANGED object:_detailItem];
    if(rec >= [todoContent count])
        [[NSNotificationCenter defaultCenter] postNotificationName:nCHAPTER_FINISHED object:[_detailItem valueForKey:@"chapter"]];
    [AppDelegate storeProgress:record forContent:_detailItem];
}

@end

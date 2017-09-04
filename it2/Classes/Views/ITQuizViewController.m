//
//  ITQuizViewController.m
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 19.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import "ITQuizViewController.h"
#import "AppDelegate.h"

@interface ITQuizViewController () {
    UITapGestureRecognizer *recognizer;
}

@property (nonatomic, strong) UILabel *finalLabel;
@end

@implementation ITQuizViewController

@synthesize navigationItem, returnButton, finalLabel;

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
    [self.view setBackgroundColor:bgColor];

    self.returnButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleReturnButton:)];
    NSMutableArray *items = [self.navigationItem.leftBarButtonItems mutableCopy];
    if(items == nil) {
        items = [NSMutableArray array];
    }
    [items insertObject:returnButton atIndex:0];
    self.navigationItem.leftBarButtonItems = items;
    [self initAdBanner];
}

-(void)viewWillAppear:(BOOL)animated
{
    [self showNext];
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
    if(finalLabel) {
        [finalLabel removeFromSuperview];
        finalLabel = nil;
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

-(void)showNext
{
    currentQuestion ++;
    if(currentQuestion >= [quizContent count]) {
        [currentQuiz removeFromSuperview];
        currentQuiz = nil;
        if(finalLabel) {
            [finalLabel removeFromSuperview];
            finalLabel = nil;
        }
        finalLabel = [[UILabel alloc] initWithFrame:self.view.frame];
        finalLabel.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        finalLabel.numberOfLines = 0;
        finalLabel.backgroundColor = [UIColor clearColor];
        finalLabel.textAlignment = NSTextAlignmentCenter;
        finalLabel.font = [UIFont fontWithName:@"Baskerville-BoldItalic" size:22];
        NSString *tt = [NSString stringWithFormat:NSLocalizedString(@"Your result: %i from %i ", @"quiz result"), score, [quizContent count]];
        [self.view addSubview:finalLabel];
        self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Correct %i from %i", "quiz header"), score, [quizContent count]];
        if(_detailItem) {
            float pr = [[_detailItem valueForKey:@"record"] floatValue];
            float len = [quizContent count];
            [_detailItem setValue:[NSNumber numberWithFloat:len] forKey:@"length"];
            [AppDelegate setProgress:score forContent:_detailItem];
            if(score > pr) {
                if(score >= len/2 && pr < len/2) {
                    if([[AppDelegate instance] unlockNextChapter]) {
                        tt = [NSString stringWithFormat:NSLocalizedString(@"%@\n\nCONGRATULATIONS!\nNew chapter have been unlocked for you!", "quiz final"), tt];
                    }
                }
            }
        }
        [finalLabel setText:tt];
    } else {
        self.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Question %i from %i", @"quiz header"), currentQuestion+1, [quizContent count]];
        CGRect b = self.view.frame;
        nextQuiz = [[ITQuizView alloc] initWithFrame:b andContent:[quizContent objectAtIndex:currentQuestion]];
        nextQuiz.delegate = self;
        nextQuiz.alpha = 0.f;
        [_scroll setContentSize:b.size];
        [_scroll addSubview:nextQuiz];
        [UIView animateWithDuration:0.5f animations:^(void){
            if(currentQuiz) {
                currentQuiz.alpha = 0.f;
            }
            nextQuiz.alpha = 1.f;
        } completion:^(BOOL finished){
            if(currentQuiz) {
                [currentQuiz removeFromSuperview];
                currentQuiz = nil;
            }
            currentQuiz = nextQuiz;
            nextQuiz = nil;
        }];
    }
}

-(void)loadQuizFromFile:(NSString *)fileName
{
    NSData *plistData = [NSData dataWithContentsOfFile:fileName];
    [self loadQuizFromData:plistData];
}

-(void)loadQuizFromUrl:(NSString *)fileUrl
{
    NSData *plistData = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileUrl]];
    [self loadQuizFromData:plistData];
}

-(void)loadQuizFromData:(NSData*)plistData
{
    NSError *error;
    NSPropertyListFormat format;
    NSMutableArray *qc = [[NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&format error:&error ] mutableCopy];
    if (!qc) {
        NSLog(@"Failed to read quiz content. Error: %@", error);
    }
    score = 0;
    currentQuestion = -1;
    if(quizContent != nil) [quizContent removeAllObjects];
    else quizContent = [NSMutableArray array];
    
    while([qc count] > 0) {
        int cur = random() % [qc count];
        [quizContent addObject:[qc objectAtIndex:cur]];
        [qc removeObjectAtIndex:cur];
    }
}

#pragma mark - UIScrollViewDelegate

#pragma mark - ITQuizViewDelegate

-(void) quizView:(ITQuizView *)quiz withResult:(BOOL)res
{
    if(res) score ++;
    [self performSelector:@selector(showNext) withObject:nil afterDelay:0.5f];
}

@end

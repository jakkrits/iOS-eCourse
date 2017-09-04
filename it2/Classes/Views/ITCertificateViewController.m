//
//  ITCertificateViewController.m
//  it2
//
//  Created by Vasiliy Makarov on 24.04.13.
//
//

#import "ITCertificateViewController.h"
#import <Parse/Parse.h>

@interface ITCertificateViewController () {
    UITapGestureRecognizer *recognizer;
}

@end

@implementation ITCertificateViewController

@synthesize navigationItem, returnButton, image;

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
    self.returnButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(handleReturnButton:)];
    NSMutableArray *items = [self.navigationItem.leftBarButtonItems mutableCopy];
    if(items == nil) {
        items = [NSMutableArray array];
    }
    [items insertObject:returnButton atIndex:0];
    self.navigationItem.leftBarButtonItems = items;
    
    PFFile *cer = [[PFUser currentUser] valueForKey:@"certificate"];
    [image setImage:[UIImage imageWithData:[cer getData]]];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewDidAppear:(BOOL)animated
{
    recognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTapBehind:)];
    [recognizer setNumberOfTapsRequired:1];
    recognizer.cancelsTouchesInView = NO; //So the user can still interact with controls in the modal view
    [self.view.window addGestureRecognizer:recognizer];
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

@end

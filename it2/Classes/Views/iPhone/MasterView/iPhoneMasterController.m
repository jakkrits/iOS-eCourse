//
//  iPhoneElementsController.m
//  it2
//

#import "iPhoneMasterController.h"

#import "iPhoneMasterController.h"
#import "MasterCell.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import "iPhoneDetailController.h"
#import "ITAboutViewController.h"
#import "ITLockView.h"

@implementation iPhoneMasterController

#pragma mark - View lifecycle

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    self.title = NSLocalizedString(@"Course", @"iPhone main tab");
    
    self.managedObjectContext = [[AppDelegate instance] managedObjectContext];
    
    super.masterTableView.delegate = self;
    super.masterTableView.dataSource = self;
    
    UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage tallImageNamed:@"ipad-BG-pattern.png"]];
    [self.view setBackgroundColor:bgColor];
    
    NSIndexPath *ind = [NSIndexPath indexPathWithIndex:0];
    ind = [ind indexPathByAddingIndex:0];
    [self.masterTableView selectRowAtIndexPath:ind animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chapterFinished:) name:nCHAPTER_FINISHED object:nil];

    [[AppDelegate instance] prepareIPhoneViewController:self leftButtons:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(firstStart:) name:nFIRST_START object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:[AppDelegate instance] selector:@selector(showIPhoneInfoScreen:) name:nSHOW_HELP object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(purchaseCompleted:) name:nPURCHASE_COMPLETED object:nil];
}

-(void)firstStart:(id)sender
{
    // info screen for iphone
    ITAboutViewController * aboutViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
    aboutViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    aboutViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [aboutViewController setOnCloseHandler:self selector:@selector(firstStart2:) object:nil];
    [self presentViewController:aboutViewController animated:YES completion:^(void){}];
}

-(void)firstStart2:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"showAboutAtFirstStart"];
    CMPopTipView *helpPopTipView = [[CMPopTipView alloc] initWithMessage:NSLocalizedString(@"Press this button to show help", @"button tip")];
    helpPopTipView.delegate = self;
    [helpPopTipView presentPointingAtView:[[self.navigationItem.rightBarButtonItems objectAtIndex:0] customView] inView:self.view animated:YES];
    [helpPopTipView autoDismissAnimated:YES atTimeInterval:3.f];
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *chapter = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    [[AppDelegate instance] setCurChapter:chapter];
    CGFloat progress = [AppDelegate chapterProgress:chapter];
    if(progress < 0) {
        [self performSegueWithIdentifier:@"LockedSegue" sender:self];
    } else {
        [self performSegueWithIdentifier:@"DetailSegue" sender:self];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([[segue identifier] isEqualToString:@"LockedSegue"]) {
        UIViewController *vc = [segue destinationViewController];
        ITLockView *lv = (ITLockView*)vc.view;
        [lv initLock];        
        [vc.navigationItem setTitle:[[[AppDelegate instance] curChapter] valueForKey:@"title"]];
    } else if([[segue identifier] isEqualToString:@"DetailSegue"]) {
        iPhoneDetailController *det = [segue destinationViewController];
        [det processChapter:[[AppDelegate instance] curChapter]];
    }
}

-(void)chapterFinished:(id)chapter
{
    
}

#pragma mark - CMPopTipViewDelegate

- (void)popTipViewWasDismissedByUser:(CMPopTipView *)popTipView
{
    // nothing to do
}

-(void)purchaseCompleted:(NSNotification*)notification
{
    UIViewController *vc = [self.navigationController.viewControllers lastObject];
    if(vc != self) [self.navigationController popToRootViewControllerAnimated:YES];
}

@end

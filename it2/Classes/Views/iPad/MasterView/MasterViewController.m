//
//  MasterViewController.m
//  it2
//


#import "MasterViewController.h"
#import "MasterCell.h"
#import "AppDelegate.h"
#import "ShadowView.h"

@implementation MasterViewController

@synthesize masterTableView, delegate;
@synthesize models;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
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

- (void)viewDidLoad
{ 
    self.title = NSLocalizedString(@"Contents", @"TOC label");
    
    self.managedObjectContext = [[AppDelegate instance] managedObjectContext];
    UIImage *navBarImage = nil;
    if(NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        navBarImage = [UIImage tallImageNamed:@"ipad-menubar-left.png"];
    } else {
        navBarImage = [UIImage tallImageNamed:@"ipad-menubar-left-ios7.png"];
    }
    
    [self.navigationController.navigationBar setBackgroundImage:navBarImage 
                                       forBarMetrics:UIBarMetricsDefault];
    
    masterTableView.delegate = self;
    masterTableView.dataSource = self;
    
    if(IsIPad) {
        CALayer * shadow = [self createShadowWithFrame:CGRectMake(0, 0, 320, 5)];
        [self.view.layer addSublayer:shadow];
    }
   
    UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage tallImageNamed:@"ipad-BG-pattern.png"]];
    [self.view setBackgroundColor:bgColor];
    
    [super viewDidLoad];
    NSIndexPath *ind = [NSIndexPath indexPathWithIndex:0];
    ind = [ind indexPathByAddingIndex:0];
    [self.masterTableView selectRowAtIndexPath:ind animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(chapterFinished:) name:nCHAPTER_FINISHED object:nil];
}


- (void)viewDidUnload
{
    self.managedObjectContext = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    NSIndexPath *ind = [NSIndexPath indexPathForRow:0 inSection:0];
    [masterTableView selectRowAtIndexPath:ind animated:YES scrollPosition:UITableViewScrollPositionMiddle];
    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:ind];
    [[AppDelegate instance] setCurChapter:object];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark - Table view data source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"MasterCell"; 
    
    MasterCell *cell = (MasterCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
  
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
    
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


-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 67;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (void)configureCell:(MasterCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    int lastIndex = [self tableView:self.masterTableView numberOfRowsInSection:indexPath.section] - 1;
    if(cell.tag == 0 && indexPath.row == lastIndex) {
        CALayer* shadow = [self createShadowWithFrame:CGRectMake(0, 67, self.view.frame.size.width, 5)];
        shadow.name = @"shadow";
        [cell.layer addSublayer:shadow];
        cell.tag = 1;
    } else if(cell.tag == 1 && indexPath.row != lastIndex) {
        CALayer *sh = nil;
        for (CALayer *l in cell.layer.sublayers) {
            if([l.name isEqualToString:@"shadow"]) {
                sh = l;
                break;
            }
        }
        [sh removeFromSuperlayer];
        cell.tag = 0;
    }

    BOOL useLocks = ![[[NSUserDefaults standardUserDefaults] valueForKey:@"unlockAllSwitch"] boolValue];

    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.titleLabel.text = [[object valueForKey:@"title"] description];
    cell.textLabel.text = [[object valueForKey:@"name"] description];
    float progress = [AppDelegate chapterProgress:object];

    if(progress < 0 && useLocks) {
        [cell.avatarImageView setImage:[UIImage imageNamed:@"lock.png"]];
    } else if(progress >= 0.99f) {
        [cell.avatarImageView setImage:[UIImage imageNamed:@"lamp2.png"]];
    } else {
        [cell.avatarImageView setImage:[UIImage imageNamed:@"lamp1.png"]];
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
    [[AppDelegate instance] setCurChapter:object];
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chapter" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"section" cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}

-(void)chapterFinished:(NSNotification*)notification
{
    NSManagedObject *ch = notification.object;
    if(ch == nil) {
        [self.masterTableView reloadData];
    } else {
        float chPr = [AppDelegate chapterProgress:ch];
        if(chPr >= 0.99f)
            [self.masterTableView reloadData];
    }
}

@end

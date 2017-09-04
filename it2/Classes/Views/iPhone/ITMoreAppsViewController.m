//
//  ITMoreAppsViewController.m
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 28.01.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import "ITMoreAppsViewController.h"
#import "AppDelegate.h"
#import "MasterCell.h"

@implementation ITMoreAppsViewCell

-(id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if(([super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier])) {
        // do nothing
        self.textLabel.numberOfLines = 2;
        self.textLabel.font = [UIFont systemFontOfSize:14.f];
    }
    return self;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    self.imageView.bounds = CGRectMake(0, 0, 40, 40);
}

@end

@interface ITMoreAppsViewController ()
@property (nonatomic, retain) NSMutableDictionary *sections;
@property (nonatomic, retain) NSMutableDictionary *sectionTypeMap;
@end

@implementation ITMoreAppsViewController
@synthesize sections = _sections;
@synthesize sectionTypeMap = _sectionTypeMap;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom the table
        self.sections = [NSMutableDictionary dictionary];
        self.sectionTypeMap = [NSMutableDictionary dictionary];
        
        // The className to query on
        super.parseClassName = @"moreApps";
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"title";
        
        // Uncomment the following line to specify the key of a PFFile on the PFObject to display in the imageView of the default cell style
        self.imageKey = @"image";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 25;
        
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithClassName:@"moreApps"];
    self = [super initWithCoder:aDecoder];
    if (self) {
        self.sections = [NSMutableDictionary dictionary];
        self.sectionTypeMap = [NSMutableDictionary dictionary];
        // The className to query on
        self.parseClassName = @"moreApps";
        
        // The key of the PFObject to display in the label of the default cell style
        self.textKey = @"title";
        self.imageKey = @"image";
        
        // Whether the built-in pull-to-refresh is enabled
        self.pullToRefreshEnabled = YES;
        
        // Whether the built-in pagination is enabled
        self.paginationEnabled = YES;
        
        // The number of objects to show per page
        self.objectsPerPage = 25;

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UITableView* table = (UITableView*)self.view;
    [table registerClass:[ITMoreAppsViewCell class] forCellReuseIdentifier:@"Cell"];

    [self loadObjects];
    [[AppDelegate instance] prepareIPhoneViewController:self leftButtons:NO];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return YES;//(interfaceOrientation == UIInterfaceOrientationPortrait);
}


// Override to customize the look of a cell representing an object. The default is to display
// a UITableViewCellStyleDefault style cell with the label being the textKey in the object,
// and the imageView being the imageKey in the object.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath object:(PFObject *)object {
    static NSString *CellIdentifier = @"MoreAppsCell";
 
    MasterCell *cell = (MasterCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[MasterCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:CellIdentifier];
    }
 
    // Configure the cell
    cell.titleLabel.text = [object objectForKey:self.textKey];
    PFFile *imgfile = [object objectForKey:self.imageKey];
    PFImageView *img = (PFImageView*)cell.avatarImageView;
    [img setFile:imgfile];
    [img loadInBackground];
    cell.textLabel.text = [object objectForKey:@"comment"];
    NSString *starL = [object objectForKey:@"action"];
    if(starL != nil && [starL length] > 0) {
        cell.starLabel.text = starL;
        cell.starImageView.hidden = NO;
        cell.starLabel.hidden = NO;
    } else {
        cell.starImageView.hidden = YES;
        cell.starLabel.hidden = YES;
    }
    NSString *url = [object objectForKey:@"url"];
    if(url != nil && [url length] > 0) {
        cell.accessoryType = UITableViewCellSelectionStyleBlue;
    }
    return cell;
}


// Override if you need to change the ordering of objects in the table.
- (PFObject *)objectAtIndexPath:(NSIndexPath *)indexPath {

    NSString *type = [self typeForSection:indexPath.section];
    NSArray *rowIndecesInSection = [self.sections objectForKey:type];
    NSNumber *rowIndex = [rowIndecesInSection objectAtIndex:indexPath.row];
    return [self.objects objectAtIndex:[rowIndex intValue]];
}

- (NSString *)typeForSection:(NSInteger)section {
    return [self.sectionTypeMap objectForKey:[NSNumber numberWithInt:section]];
}

// Override to customize the look of the cell that allows the user to load the next page of objects.
// The default implementation is a UITableViewCellStyleDefault cell with simple labels.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForNextPageAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"NextPage";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
 
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.textLabel.text = NSLocalizedString(@"More...", @"pftable loading");
    
    return cell;
}



#pragma mark - PFQueryTableViewController

- (void)objectsWillLoad {
    [super objectsWillLoad];
    
    // This method is called before a PFQuery is fired to get more objects
}

- (void)objectsDidLoad:(NSError *)error {
    [super objectsDidLoad:error];
    
    // This method is called every time objects are loaded from Parse via the PFQuery

    [self.sections removeAllObjects];
    [self.sectionTypeMap removeAllObjects];
    
    NSInteger section = 0;
    NSInteger rowIndex = 0;
    for (PFObject *object in self.objects) {
        NSString *sportType = [object objectForKey:@"appType"];
        NSMutableArray *objectsInSection = [self.sections objectForKey:sportType];
        if (!objectsInSection) {
            objectsInSection = [NSMutableArray array];
            
            // this is the first time we see this sportType - increment the section index
            [self.sectionTypeMap setObject:sportType forKey:[NSNumber numberWithInt:section++]];
        }
        
        [objectsInSection addObject:[NSNumber numberWithInt:rowIndex++]];
        [self.sections setObject:objectsInSection forKey:sportType];
    }
}


// Override to customize what kind of query to perform on the class. The default is to query for
// all objects ordered by createdAt descending.
- (PFQuery *)queryForTable {
    PFQuery *query = [PFQuery queryWithClassName:self.parseClassName];
 
    // If Pull To Refresh is enabled, query against the network by default.
    if (self.pullToRefreshEnabled) {
        query.cachePolicy = kPFCachePolicyNetworkOnly;
    }
 
    // If no objects are loaded in memory, we look to the cache first to fill the table
    // and then subsequently do a query against the network.
    if (self.objects.count == 0) {
        query.cachePolicy = kPFCachePolicyCacheThenNetwork;
    }
 
    [query orderByAscending:@"appType"];
 
    return query;
}


#pragma mark - Table view data source


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int num = self.sections.allKeys.count;
    return num;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *type = [self typeForSection:section];
    NSArray *rowIndecesInSection = [self.sections objectForKey:type];
    return rowIndecesInSection.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *type = [self typeForSection:section];
    return type;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [super tableView:tableView didSelectRowAtIndexPath:indexPath];
    PFObject *object = [self objectAtIndexPath:indexPath];
    NSString *url = [object objectForKey:@"url"];
    if(url != nil && [url length] > 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
    }
}

@end

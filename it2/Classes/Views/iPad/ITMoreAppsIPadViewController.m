//
//  ITMoreAppsIPadViewController.m
//  it2
//
//  Created by Vasiliy Makarov on 22.03.13.
//
//

#import <QuartzCore/QuartzCore.h>
#import "ITMoreAppsIPadViewController.h"
#import "MasterCell.h"

@interface ITMoreAppsIPadViewController () {
    NSMutableDictionary *category;
}

@end

@implementation ITMoreAppsItem

@synthesize appType, comment, image, title, url, action;

-(NSString*) description
{
    return [NSString stringWithFormat:@"ITMoreAppsItem {appType: %@, comment: %@, title: %@, url: %@, image: %@}", appType, comment, title, url, image];
}

@end

@implementation ITMoreAppsIPadViewController

@synthesize table, textField;

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
    UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage tallImageNamed:@"ipad-BG-pattern.png"]];
    [self.view setBackgroundColor:bgColor];
    [self.table setBackgroundView:nil];
    [self.table setBackgroundColor:bgColor];
    self.table.layer.cornerRadius = 5;
    self.table.layer.borderWidth = 1;
    self.table.layer.borderColor = [[UIColor lightGrayColor] CGColor];
    category = [NSMutableDictionary dictionary];
    
    PFQuery *q = [PFQuery queryWithClassName:@"moreApps"];
    [q findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error){
        [category removeAllObjects];
        if(error != nil) NSLog(@"error: %@", error);
        for (NSDictionary *it in objects) {
            ITMoreAppsItem *i = [[ITMoreAppsItem alloc] init];
            i.appType = [it valueForKey:@"appType"];
            i.comment = [it valueForKey:@"comment"];
            i.image = [it valueForKey:@"image"];
            i.title = [it valueForKey:@"title"];
            i.url = [it valueForKey:@"url"];
            i.action = [it valueForKey:@"action"];
            NSMutableArray *catcontent = [category valueForKey:i.appType];
            if(catcontent == nil) {
                catcontent = [NSMutableArray array];
                [category setValue:catcontent forKey:i.appType];
            }
            [catcontent addObject:i];
        }
        [table reloadData];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(int)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *keys = [category allKeys];
    return [[category valueForKey:[keys objectAtIndex:section]] count];
}

-(int)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [category count];
}

-(UITableViewCell*)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"MoreAppsCell";
    
    MasterCell *cell = (MasterCell *)[self.table dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;

}

-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [[category allKeys] objectAtIndex:section];
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ITMoreAppsItem *it = [[category valueForKey:[[category allKeys] objectAtIndex:[indexPath indexAtPosition:0]]] objectAtIndex:[indexPath indexAtPosition:1]];
    if([it.url length] > 0) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:it.url]];
    }
}

-(void) configureCell:(MasterCell*) cell atIndexPath:(NSIndexPath*)indexPath
{
    ITMoreAppsItem *it = [[category valueForKey:[[category allKeys] objectAtIndex:[indexPath indexAtPosition:0]]] objectAtIndex:[indexPath indexAtPosition:1]];
    cell.titleLabel.text = it.title;
    cell.textLabel.text = it.comment;
    NSData *imgdata = [it.image getData];
    [cell.avatarImageView setImage:[UIImage imageWithData:imgdata]];
    if(it.action != nil && [it.action length] > 0) {
        cell.starLabel.text = it.action;
        cell.starLabel.hidden = NO;
        cell.starImageView.hidden = NO;
    } else {
        cell.starLabel.hidden = YES;
        cell.starImageView.hidden = YES;
    }
}

-(IBAction)subscribeToNewsletter:(id)sender
{
    if([self.textField.text length] > 0) {
        [self performSelectorInBackground:@selector(subscribeThread:) withObject:self.textField.text];
    }
}

-(void)subscribeThread:(NSString*)email
{
    NSLog(@"subscribe to %@", email);

    NSURL *url = [NSURL URLWithString:@"http://web.intropower.ru/order/confirm/?t=10902#form"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSString * str = [NSString stringWithFormat:@"good_name=ii-promo-code&bill_first_name=Дорогой друг&bill_email=%@", email];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:[str dataUsingEncoding:NSUTF8StringEncoding]];
    NSURLResponse *response;
    NSError *err;
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&err];
   
    NSLog(@"%d", [responseData length]);
}

@end

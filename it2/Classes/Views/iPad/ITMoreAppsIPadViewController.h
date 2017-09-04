//
//  ITMoreAppsIPadViewController.h
//  it2
//
//  Created by Vasiliy Makarov on 22.03.13.
//
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface ITMoreAppsItem : NSObject
    
@property (nonatomic, strong) NSString *appType;
@property (nonatomic, strong) NSString *comment;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) PFFile *image;
@property (nonatomic, strong) NSString *action;

@end

@interface ITMoreAppsIPadViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView* table;
@property (nonatomic, strong) IBOutlet UITextField* textField;

-(IBAction)subscribeToNewsletter:(id)sender;

@end

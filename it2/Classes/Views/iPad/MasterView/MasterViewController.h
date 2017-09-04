//
//  MasterViewController.h
//  it2
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <CoreData/CoreData.h>

@protocol MasterViewControllerDelegate;

@interface MasterViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) IBOutlet UITableView* masterTableView;
@property (nonatomic, strong) NSArray* models;
@property (nonatomic, unsafe_unretained) id<MasterViewControllerDelegate> delegate;
@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (strong, nonatomic) NSManagedObjectContext *managedObjectContext;

-(CALayer *)createShadowWithFrame:(CGRect)frame;

@end


@protocol MasterViewControllerDelegate <NSObject>


@end
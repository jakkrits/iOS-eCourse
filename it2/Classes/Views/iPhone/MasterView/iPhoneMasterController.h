//
//  iPhoneElementsController.h
//  it2
//

#import <UIKit/UIKit.h>
#import "MasterViewController.h"
#import "CMPopTipView.h"

@interface iPhoneMasterController : MasterViewController <CMPopTipViewDelegate>

@property (nonatomic, strong) IBOutlet UIBarButtonItem *infoButton;

@end

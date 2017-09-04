//
//  MasterCell.h
//  it2
//

#import <UIKit/UIKit.h>
#import "ADVRoundProgressView.h"

@interface MasterCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel* titleLabel;

@property (nonatomic, strong) IBOutlet UILabel* textLabel;

@property (nonatomic, strong) IBOutlet UIImageView* disclosureImageView;

@property (nonatomic, strong) IBOutlet UIImageView* avatarImageView;

@property (nonatomic, strong) IBOutlet UIImageView* bgImageView;

@property (nonatomic, strong) IBOutlet ADVRoundProgressView* roundProgress;

@property (nonatomic, strong) IBOutlet UIImageView* starImageView;

@property (nonatomic, strong) IBOutlet UILabel* starLabel;

@end

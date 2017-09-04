//
//  MasterCell.m
//  it2
//

#import "MasterCell.h"
#import "AppDelegate.h"

@implementation MasterCell

@synthesize titleLabel, textLabel, avatarImageView, bgImageView, disclosureImageView;

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    if(selected)
    {
        UIImage* bg = [UIImage tallImageNamed:@"ipad-list-item-selected.png"];
        UIImage* disclosureImage = [UIImage tallImageNamed:@"ipad-arrow-selected.png"];
        
        [bgImageView setImage:bg];
        [disclosureImageView setImage:disclosureImage];
        
        [titleLabel setTextColor:[UIColor whiteColor]];
        [titleLabel setShadowColor:[AppDelegate instance].colorSwitcher.tintColor];
        [titleLabel setShadowOffset:CGSizeMake(0, -1)];
        
        
        [textLabel setTextColor:[UIColor whiteColor]];
        [textLabel setShadowColor:[AppDelegate instance].colorSwitcher.tintColor];
        [textLabel setShadowOffset:CGSizeMake(0, -1)];
        
    }
    else
    {
        UIImage* bg = [UIImage tallImageNamed:@"ipad-list-element.png"];
        UIImage* disclosureImage = [UIImage tallImageNamed:@"ipad-arrow.png"];
        
        [bgImageView setImage:bg];
        [disclosureImageView setImage:disclosureImage];
        
        [titleLabel setTextColor:[AppDelegate instance].colorSwitcher.tintColor];
        [titleLabel setShadowColor:[UIColor whiteColor]];
        [titleLabel setShadowOffset:CGSizeMake(0, 1)];
        
        
        [textLabel setTextColor:[UIColor colorWithRed:113.0/255 green:133.0/255 blue:148.0/255 alpha:1.0]];
        [textLabel setShadowColor:[UIColor whiteColor]];
        [textLabel setShadowOffset:CGSizeMake(0, 1)];
        
    }

    
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end

//
//  ITLockView.h
//  it2
//
//  Created by Vasiliy Makarov on 25.03.13.
//
//

#import <UIKit/UIKit.h>

@interface ITLockView : UIView

@property (nonatomic, strong) IBOutlet UIButton *button;
@property (nonatomic, strong) IBOutlet UIButton *restoreButton;
@property (nonatomic, strong) IBOutlet UILabel *label;

-(void)initLock;

@end

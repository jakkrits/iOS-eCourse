//
//  ITAdViewController.h
//  it2
//
//  Created by Vasiliy Makarov on 17.04.13.
//
//

#import <UIKit/UIKit.h>
#import <AdMob/GADBannerView.h>

@interface ITAdViewController : UIViewController <GADBannerViewDelegate>

@property (nonatomic, strong) IBOutlet UIView *mainView;

-(void)initAdBanner;

@end

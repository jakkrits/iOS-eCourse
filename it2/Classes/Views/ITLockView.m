//
//  ITLockView.m
//  it2
//
//  Created by Vasiliy Makarov on 25.03.13.
//
//

#import "ITLockView.h"
#import "AppDelegate.h"
#import "MicroTransactions.h"

@implementation ITLockView

@synthesize label, button, restoreButton;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)initLock
{
    NSString *AppPurchase = [[AppDelegate instance] AppPurchase];
    if(nil == AppPurchase) return;
    NSString *price = ProductPriceById(AppPurchase);
    if(price == nil) price = [[NSUserDefaults standardUserDefaults] stringForKey:@"defaultPrice"];
    label.text = [NSString stringWithFormat:label.text, price];
    [button setTitle:[NSString stringWithFormat:button.titleLabel.text, price] forState:UIControlStateNormal];
    self.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    [button addTarget:[AppDelegate instance] action:@selector(inAppPurchase:) forControlEvents:UIControlEventTouchUpInside];
    [restoreButton addTarget:[AppDelegate instance] action:@selector(inAppRestore:) forControlEvents:UIControlEventTouchUpInside];

}

@end

//
//  ITAdViewController.m
//  it2
//
//  Created by Vasiliy Makarov on 17.04.13.
//
//

#import "ITAdViewController.h"
#import "AppDelegate.h"

@interface ITAdViewController () {
    BOOL adsShown;
    GADBannerView *_banner;
}

@end

@implementation ITAdViewController

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
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)initAdBanner
{
#ifndef NOADS
    if(AdMob) {
        // make a banner in the bottom of view
        if (self.view.frame.size.width >= 468) {
            _banner = [[GADBannerView alloc]
                       initWithFrame:CGRectMake((self.view.frame.size.width-GAD_SIZE_468x60.width)*.5f, self.view.frame.size.height,
                                                GAD_SIZE_468x60.width,
                                                GAD_SIZE_468x60.height)];
        } else if(self.view.frame.size.width >= 320) {
            _banner = [[GADBannerView alloc]
                       initWithFrame:CGRectMake((self.view.frame.size.width-GAD_SIZE_320x50.width)*.5f, self.view.frame.size.height,
                                                GAD_SIZE_320x50.width,
                                                GAD_SIZE_320x50.height)];
        } else {
            return;
        }
        [_banner setAutoresizingMask:UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin];
        // Назначение идентификатора объявлению. Указывается идентификатор издателя AdMob.
        _banner.adUnitID = [AppDelegate instance].adMobId;
        _banner.delegate = self;
        
        // Укажите, какой UIViewController необходимо восстановить после перехода
        // пользователя по объявлению и добавить в иерархию представлений.
        _banner.rootViewController = [AppDelegate instance].window.rootViewController;
        [self.view addSubview:_banner];
        
        // Инициирование общего запроса на загрузку вместе с объявлением.
        GADRequest *request = [GADRequest request];
        [_banner loadRequest:request];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(hideBanner:) name:nHIDE_ADS object:nil];
    }
#endif
}

#pragma mark GADBannerViewDelegate

-(void)adViewDidReceiveAd:(GADBannerView *)view
{
    if(!adsShown) {
        [UIView beginAnimations:@"BannerSlide" context:nil];
        CGPoint bc = view.center;
        bc.y -= view.frame.size.height;
        view.center = bc;
        CGRect r = self.mainView.frame;
        r.size.height -= view.frame.size.height;
        self.mainView.frame = r;
        [UIView commitAnimations];
        adsShown = YES;
    }
}

-(void)hideBanner:(NSNotification*)notification
{
    if(adsShown) {
        [UIView animateWithDuration:1.f animations:^(void) {
            CGPoint bc = _banner.center;
            bc.y += _banner.frame.size.height;
            _banner.center = bc;
            CGRect r = self.mainView.frame;
            r.size.height += _banner.frame.size.height;
            self.mainView.frame = r;
        } completion:^(BOOL finished) {
            [_banner removeFromSuperview];
            _banner = nil;
        }];
        adsShown = NO;
    }
}
@end

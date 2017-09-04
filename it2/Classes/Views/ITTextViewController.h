//
//  ITTextViewController.h
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 16.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITAdViewController.h"

@interface ITTextViewController : ITAdViewController <UIWebViewDelegate, GADBannerViewDelegate> {
    NSTimer *timer;
    BOOL canRecordProgress;
    BOOL textLoaded;
}

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (strong, nonatomic) UIBarButtonItem* returnButton;
@end

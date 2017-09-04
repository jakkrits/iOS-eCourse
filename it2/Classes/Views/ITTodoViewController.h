//
//  ITQuizViewController.h
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 19.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITTodoView.h"
#import "ITAdViewController.h"

@interface ITTodoViewController : ITAdViewController <UIScrollViewDelegate, ITTodoViewDelegate, GADBannerViewDelegate> {
    int score, currentItemNum;
    NSArray* todoContent;
}

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UIScrollView *scroll;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (strong, nonatomic) UIBarButtonItem* returnButton;
@property (strong, nonatomic) IBOutlet UIPageControl* pageControl;

-(void)loadTodoFromFile:(NSString*)fileName;
-(void)loadTodoFromUrl:(NSString*)fileUrl;
-(IBAction)pageChanged:(id)sender;
@end

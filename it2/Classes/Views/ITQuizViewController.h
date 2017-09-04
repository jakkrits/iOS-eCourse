//
//  ITQuizViewController.h
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 19.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ITQuizView.h"
#import "ITAdViewController.h"

@interface ITQuizViewController : ITAdViewController <UIScrollViewDelegate, ITQuizViewDelegate, GADBannerViewDelegate> {
    ITQuizView *currentQuiz, *nextQuiz;
    int score, currentQuestion;
    NSMutableArray* quizContent;
}

@property (strong, nonatomic) id detailItem;
@property (weak, nonatomic) IBOutlet UIScrollView *scroll;
@property (strong, nonatomic) IBOutlet UINavigationItem *navigationItem;
@property (strong, nonatomic) UIBarButtonItem* returnButton;

-(void)loadQuizFromFile:(NSString*)fileName;
-(void)loadQuizFromUrl:(NSString*)fileUrl;
@end

//
//  ITQuizView.h
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 19.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ITQuizView;

@protocol ITQuizViewDelegate <NSObject>

-(void)quizView:(ITQuizView*)quiz withResult:(BOOL)res;

@end

@interface ITQuizView : UIView {
    UITextView *text;
    UIImageView *image;
    UIWebView *html;
    UIButton *b1, *b2, *b3, *b4;
}
@property (nonatomic, assign) int showAnswer;
@property (nonatomic, strong) NSDictionary* quiz;
@property (nonatomic, weak) id delegate;

- (id)initWithFrame:(CGRect)frame andContent:(NSDictionary*)content;

@end

//
//  ITQuizView.m
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 19.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ITQuizView.h"
#import "UIButton+Glossy.h"
#import "GradientButton.h"
#import "AppDelegate.h"

@implementation ITQuizView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _showAnswer = 1;
        [self loadQuiz:nil];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andContent:(NSDictionary*)content
{
    self = [super initWithFrame:frame];
    if(self) {
        _showAnswer = 1;
        [self loadQuiz:content];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        _showAnswer = 1;
        [self loadQuiz:nil];
    }
    return self;
}

-(void)setQuiz:(NSDictionary *)quiz
{
    _quiz = quiz;
    [self loadQuiz:_quiz];
}

-(void)loadQuiz:(NSDictionary*)dict
{
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    NSString *q = [dict valueForKey:@"question"];
    NSString *a = [dict valueForKey:@"answer"];
    NSString *a1 = [dict valueForKey:@"a1"];
    NSString *a2 = [dict valueForKey:@"a2"];
    NSString *a3 = [dict valueForKey:@"a3"];
    if(dict == nil) {
        q = @"В каком году было восстание Спартака?";
        a = @"Не помню";
        a1 = @"Не знаю";
        a2 = @"Не скажу";
        a3 = @"В прошлом году";
    }
    int qsize = 140;
    if(IsIPad) qsize = 190;
    NSURL *url = [NSURL URLWithString:q];
    if(nil != url &&
       (nil != [url host] ||
        [url.pathExtension isEqualToString:@"html"] ||
        [url.pathExtension isEqualToString:@"htm"])) {
        // question is a html page
           html = [[UIWebView alloc] initWithFrame:CGRectMake(10, 0, self.frame.size.width-20, qsize + 15)];
           if(nil != [url host]) [html loadRequest:[NSURLRequest requestWithURL:url]];
           else {
               [html loadRequest:[NSURLRequest requestWithURL:[[NSBundle mainBundle] URLForResource:q withExtension:nil subdirectory:@"data/Quiz"]]];
           }
           html.layer.cornerRadius = 5;
           html.layer.borderColor = [[UIColor grayColor] CGColor];
           html.layer.borderWidth = 1;
           html.layer.shadowRadius = 3;
           html.layer.shadowColor = [[UIColor blackColor] CGColor];
           html.layer.shadowOpacity = 0.5;
           html.layer.shadowOffset = CGSizeMake(3, 3);
           html.clipsToBounds = NO;
           html.layer.masksToBounds = NO;
           [self addSubview:html];
    } else {
        NSString *file = [[NSBundle mainBundle] pathForResource:q ofType:nil inDirectory:@"data/Quiz"];
        if( nil != file) {
            // question is a file (may be image)
            image = [[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:file]];
            image.contentMode = UIViewContentModeScaleAspectFit;
            image.frame = CGRectMake(20, 5, self.frame.size.width-40, qsize);
            image.layer.cornerRadius = 5;
            image.layer.borderColor = [[UIColor grayColor] CGColor];
            image.layer.borderWidth = 1;
            image.layer.shadowRadius = 3;
            image.layer.shadowColor = [[UIColor blackColor] CGColor];
            image.layer.shadowOpacity = 0.5;
            image.layer.shadowOffset = CGSizeMake(3, 3);
            image.clipsToBounds = NO;
            image.layer.masksToBounds = NO;
            [self addSubview:image];
        } else {
            // question is a regular text
            text = [[UITextView alloc] initWithFrame:CGRectMake(20, 5, self.frame.size.width-40, qsize)];
            text.autoresizingMask = UIViewAutoresizingFlexibleWidth;
            text.editable = NO;
            text.font = [UIFont systemFontOfSize:16];
            [text setText:q];
            text.layer.cornerRadius = 5;
            text.layer.borderColor = [[UIColor grayColor] CGColor];
            text.layer.borderWidth = 1;
            text.layer.shadowRadius = 3;
            text.layer.shadowColor = [[UIColor blackColor] CGColor];
            text.layer.shadowOpacity = 0.5;
            text.layer.shadowOffset = CGSizeMake(3, 3);
            text.clipsToBounds = NO;
            text.layer.masksToBounds = NO;
            [self addSubview:text];
        }
    }
    
    BOOL places[4];
    for(int i =0; i < 4; i++) places[i] = NO;
    int max = 3;
    if(a1 == nil) {
        places[max] = YES;
        max --;
    }
    if(a2 == nil) {
        places[max] = YES;
        max --;
    }
    if(a3 == nil) {
        places[max] = YES;
        max --;
    }
    b1 = [self makeButton:a places:places];
    b1.tag = 1;
    if(a1 != nil) b2 = [self makeButton:a1 places:places];
    if(a2 != nil) b3 = [self makeButton:a2 places:places];
    if(a3 != nil) b4 = [self makeButton:a3 places:places];
}

-(GradientButton*)makeButton:(NSString*)buttonText places:(BOOL*)places
{
    UIColor *bc = [UIColor colorWithRed:0.85 green:0.8 blue:0.8 alpha:1.0];
    GradientButton *b = [GradientButton buttonWithType:UIButtonTypeRoundedRect];
    b.backgroundColor = bc;
    int pindex = random()%4;
    while (places[pindex]) {
        pindex ++;
        if(pindex >= 4) pindex = 0;
    }
    places[pindex] = YES;
    if(IsIPad) {
        pindex = 220 + 50 * pindex;
    } else {
        pindex = 170 + 50 * pindex;
    }
    b.frame = CGRectMake(30, pindex, self.frame.size.width-60, 40);
    b.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [b setTitle:buttonText forState:UIControlStateNormal];
    b.titleLabel.numberOfLines = 0;
    [b setTitleColor:[AppDelegate instance].colorSwitcher.tintColor forState:UIControlStateNormal];
    [b addTarget:self action:@selector(handleButton:) forControlEvents:UIControlEventTouchDown];
    [self addSubview:b];
    return b;
}

-(void)handleButton:(UIButton*)sender
{
    if(sender.tag == 1) {
        [_delegate quizView:self withResult:YES];
    } else {
        [_delegate quizView:self withResult:NO];
    }
}

@end

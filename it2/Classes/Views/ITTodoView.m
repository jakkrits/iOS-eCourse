//
//  ITQuizView.m
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 19.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "ITTodoView.h"
#import "GradientButton.h"
#import "AppDelegate.h"

@implementation ITTodoView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        [self loadTodo:nil];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame andContent:(NSString*)content
{
    self = [super initWithFrame:frame];
    if(self) {
        [self loadTodo:content];
    }
    return self;
}

-(id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self loadTodo:nil];
    }
    return self;
}

-(void)setTodo:(NSString *)todo
{
    _todo = todo;
    [self loadTodo:_todo];
}

-(void)setState:(int)state
{
    _state = state;
    b1.selected = b1.tag == state;
    b2.selected = b2.tag == state;
    b3.selected = b3.tag == state;
    b4.selected = b4.tag == state;
}

-(void)loadTodo:(NSString*)content
{
    for (UIView *v in self.subviews) {
        [v removeFromSuperview];
    }
    NSString *q = content;
    NSString *a0 = NSLocalizedString(@"New task", @"task action");
    NSString *a1 = NSLocalizedString(@"Task started", @"task action");
    NSString *a2 = NSLocalizedString(@"Task completed", @"task action");
    NSString *a3 = NSLocalizedString(@"I have trouble", @"task action");
    if(content == nil) {
        q = @"Составить план действий";
    }
    if (IsIPad) {
        text = [[UITextView alloc] initWithFrame:CGRectMake(30, 5, self.frame.size.width-60, 100)];
    } else {
        text = [[UITextView alloc] initWithFrame:CGRectMake(10, 5, self.frame.size.width-20, 120)];
    }
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
    
    b1 = [self makeButton:a0 place:1];
    b2 = [self makeButton:a1 place:2];
    b3 = [self makeButton:a2 place:3];
    b4 = [self makeButton:a3 place:4];
    
    [self setBackgroundColor:[UIColor clearColor]];
}

-(UIButton*)makeButton:(NSString*)buttonText place:(int)place
{
    UIButton *b = [UIButton buttonWithType:UIButtonTypeCustom];
    if(IsIPad) {
        int y = 80 + 60 * place;
        b.frame = CGRectMake(self.frame.size.width/2-78, y, 156, 49);
    } else {
        int row = (place-1) % 2, pos = (place-1) / 2;
        int y = 180 + 70 * row, x = 2 + pos * 162;
        b.frame = CGRectMake(x, y, 156, 49);
    }
    b.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [b setTitle:buttonText forState:UIControlStateNormal];
    b.titleLabel.numberOfLines = 0;
    [b setTitleColor:[AppDelegate instance].colorSwitcher.tintColor forState:UIControlStateNormal];
    [b addTarget:self action:@selector(handleButton:) forControlEvents:UIControlEventTouchDown];
    b.tag = place;
    switch (place) {
        case 1:
            [b setBackgroundImage:[UIImage imageNamed:@"ipad-button-grey"] forState:UIControlStateNormal];
            [b setBackgroundImage:[UIImage imageNamed:@"ipad-button-grey-pressed"] forState:UIControlStateSelected];
            break;
        case 2:
            [b setBackgroundImage:[UIImage imageNamed:@"ipad-button-blue"] forState:UIControlStateNormal];
            [b setBackgroundImage:[UIImage imageNamed:@"ipad-button-blue-pressed"] forState:UIControlStateSelected];
            break;
        case 3:
            [b setBackgroundImage:[UIImage imageNamed:@"ipad-button-green"] forState:UIControlStateNormal];
            [b setBackgroundImage:[UIImage imageNamed:@"ipad-button-green-pressed"] forState:UIControlStateSelected];
            break;
        case 4:
            [b setBackgroundImage:[UIImage imageNamed:@"ipad-button-red"] forState:UIControlStateNormal];
            [b setBackgroundImage:[UIImage imageNamed:@"ipad-button-red-pressed"] forState:UIControlStateSelected];
            break;
            
        default:
            break;
    }
    [b setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    [self addSubview:b];
    return b;
}

-(void)handleButton:(UIButton*)sender
{
    if(sender.selected) {
        // nothing to do
    } else {
        b1.selected = NO;
        b2.selected = NO;
        b3.selected = NO;
        b4.selected = NO;
        sender.selected = YES;
        _state = sender.tag;
        [_delegate todoView:self withResult:sender.tag];
    }
}

@end

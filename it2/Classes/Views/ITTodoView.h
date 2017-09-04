//
//  ITQuizView.h
//  InfoTemplate
//
//  Created by Vasiliy Makarov on 19.02.13.
//  Copyright (c) 2013 Vasiliy Makarov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ITTodoView;

@protocol ITTodoViewDelegate <NSObject>

enum {TODO_WAIT=0, TODO_PROCESS, TODO_COMPLETE, TODO_TROUBLE};

-(void)todoView:(ITTodoView*)todo withResult:(int)res;

@end

@interface ITTodoView : UIView {
    UITextView *text;
    UIButton *b1, *b2, *b3, *b4;
}
@property (nonatomic, strong) NSString* todo;
@property (nonatomic, weak) id delegate;
@property (nonatomic, assign) int state;

- (id)initWithFrame:(CGRect)frame andContent:(NSString*)content;

@end

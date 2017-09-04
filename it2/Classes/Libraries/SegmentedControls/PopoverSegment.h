//
//  PopoverSegment.h
//  it2
//

#import <UIKit/UIKit.h>
#import "CustomSegmentedControl.h"

@protocol PopoverSegmentDelegate;

@interface PopoverSegment : UIView <CustomSegmentedControlDelegate>

@property (nonatomic, strong)   NSArray             *titles;
@property (nonatomic, assign) id<PopoverSegmentDelegate>     delegate;

@end

@protocol PopoverSegmentDelegate

- (void)selectedSegmentAtIndex:(NSInteger)index;

@end
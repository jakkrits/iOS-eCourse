//
//  iPhoneControlsController.h
//  it2
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>

@interface iPhoneControlsController : UIViewController

@property (nonatomic, strong) IBOutlet UISlider* progress;
@property (nonatomic, strong) IBOutlet UISlider* volume;
@property (nonatomic, strong) IBOutlet UIButton* playPause;
@property (nonatomic, strong) IBOutlet UIButton* playSpeed;
@property (nonatomic, strong) IBOutlet UIImageView* image;
@property (nonatomic, strong) IBOutlet UILabel* label1;
@property (nonatomic, strong) IBOutlet UILabel* label2;
@property (nonatomic, strong) IBOutlet UIImageView* volumeDown;
@property (nonatomic, strong) IBOutlet UIImageView* volumeUp;
@property (nonatomic, strong) IBOutlet UILabel* audioTitle;
@property (nonatomic, strong) IBOutlet UILabel* audioSubtitle;
@property (nonatomic, strong) AVAudioPlayer *audio;
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) NSManagedObject *audioObject;
@property (nonatomic, strong) NSString *audioTitleText;
@property (nonatomic, strong) NSString *audioSubtitleText;

-(IBAction)progressChanged:(UISlider*)slider;
-(IBAction)volumeChanged:(UISlider*)slider;
-(IBAction)stepBack:(id)sender;
-(IBAction)stepForward:(id)sender;
-(IBAction)playOrPause:(id)sender;
-(IBAction)changeSpeed:(id)sender;

-(CALayer *)createShadowWithFrame:(CGRect)frame;

@end

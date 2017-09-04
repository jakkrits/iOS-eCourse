//
//  SoundViewController.h
//  it2
//
//  Created by Vasiliy Makarov on 18.03.13.
//
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreData/CoreData.h>

@interface SoundViewController : UIViewController

@property (nonatomic, strong) IBOutlet UILabel* timeLabel1;
@property (nonatomic, strong) IBOutlet UILabel* timeLabel2;
@property (nonatomic, strong) IBOutlet UISlider* progressSlider;
@property (nonatomic, strong) IBOutlet UIButton* pauseButton;
@property (nonatomic, strong) IBOutlet UIButton* speedButton;
@property (nonatomic, strong) IBOutlet UIButton* scrollButton1;
@property (nonatomic, strong) IBOutlet UIButton* scrollButton2;
@property (nonatomic, strong) NSManagedObject* content;
@property (nonatomic, strong) AVAudioPlayer* audioPlayer;
@property (nonatomic, strong) AVPlayer *aPlayer;

@end

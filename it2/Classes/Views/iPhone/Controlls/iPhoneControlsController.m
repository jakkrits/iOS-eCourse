//
//  iPhoneControlsController.m
//  it2
//

#import "iPhoneControlsController.h"
#import "STSegmentedControl.h"
#import "RCSwitchOnOff.h"
#import "PopoverDemoController.h"
#import "CustomPopoverBackgroundView.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"

@interface iPhoneControlsController () {
    CGFloat speed;
    NSTimer *myTimer;
}

@end

@implementation iPhoneControlsController

@synthesize audioObject, audio, player;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

-(void)setAudioTitleText:(NSString *)audioTitleText
{
    _audioTitleText = audioTitleText;
    _audioTitle.text = audioTitleText;
}

-(void)setAudioSubtitleText:(NSString *)audioSubtitleText
{
    _audioSubtitleText = audioSubtitleText;
    _audioSubtitle.text = audioSubtitleText;
}

#pragma mark - View lifecycle

-(void)setAudio:(AVAudioPlayer *)_audio
{
    self->audio = _audio;
    self->speed = _audio.rate;
    [self updateTimer:nil];

}

-(void)setPlayer:(AVPlayer *)_player
{
    self->player = _player;
    self->speed = _player.rate;
    [self updateTimer:nil];
}

-(void)setAudioObject:(NSManagedObject *)_audioObject
{
    self->audioObject = _audioObject;
    [self updateTimer:nil];
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    
    UIColor* bgColor = [UIColor colorWithPatternImage:[UIImage tallImageNamed:@"ipad-BG-pattern.png"]];
    [self.view setBackgroundColor:bgColor];
    
    self.volumeDown.layer.shadowColor = [UIColor blackColor].CGColor;
    self.volumeDown.layer.shadowOpacity = 0.5f;
    self.volumeDown.layer.shadowOffset = CGSizeMake(0, 1);

    self.volumeUp.layer.shadowColor = [UIColor blackColor].CGColor;
    self.volumeUp.layer.shadowOpacity = 0.5f;
    self.volumeUp.layer.shadowOffset = CGSizeMake(0, 1);
    
    [self.image setImage:[UIImage imageNamed:@"data/Icon-72.png"]];
    
    [super viewDidLoad];

    [[AppDelegate instance] prepareIPhoneViewController:self leftButtons:NO];
    if(nil != _audioTitleText) _audioTitle.text = _audioTitleText;
    if(nil != _audioSubtitleText) _audioSubtitle.text = _audioSubtitleText;
}

-(void)viewDidAppear:(BOOL)animated
{
    myTimer = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSRunLoopCommonModes];
    [self updateTimer:myTimer];

    if(speed == 1.f) {
        [self.playSpeed setImage:[UIImage imageNamed:@"speed_normal"] forState:UIControlStateNormal];
    } else if(speed == 2.f) {
        [self.playSpeed setImage:[UIImage imageNamed:@"speed_double"] forState:UIControlStateNormal];
    } else {
        [self.playSpeed setImage:[UIImage imageNamed:@"speed_half"] forState:UIControlStateNormal];
    }
}

-(void)viewDidDisappear:(BOOL)animated
{
    [myTimer invalidate];
    myTimer = nil;
}

-(IBAction)progressChanged:(UISlider*)slider
{
    if(self.audio) [self.audio setCurrentTime:slider.value * self.audio.duration];
    else if(self.player) {
        float len = [[audioObject valueForKey:@"length"] floatValue];
        CMTime t = CMTimeMakeWithSeconds(slider.value*len, 1);
        [self.player seekToTime:t];
    }
}

-(IBAction)volumeChanged:(UISlider*)slider
{
    if(self.audio) [self.audio setVolume:slider.value];
    else if(self.player) {
        AVMutableAudioMix *mix = [self.player.currentItem.audioMix mutableCopy];
        if(nil == mix) mix = [AVMutableAudioMix audioMix];
        AVMutableAudioMixInputParameters *params = [[mix.inputParameters objectAtIndex:0] mutableCopy];
        if(nil == params) {
            params = [AVMutableAudioMixInputParameters audioMixInputParameters];
            //FIXME: - HEERE
            //params.trackID = [[self.player.currentItem.tracks objectAtIndex:0] trackID];
        }
        [params setVolume:slider.value atTime:kCMTimeZero];
        mix.inputParameters = [NSArray arrayWithObject:params];
        self.player.currentItem.audioMix = mix;
    }
}

-(IBAction)stepBack:(id)sender
{
    if(self.audio) {
        double pos = self.audio.currentTime - 15;
        if(pos < 0) pos = 0;
        [self.audio setCurrentTime:pos];
    } else if(self.player) {
        double pos = CMTimeGetSeconds(self.player.currentTime) - 15;
        if(pos < 0) pos = 0;
        [self.player seekToTime:CMTimeMakeWithSeconds(pos, 1)];
    }
    [self updateTimer:nil];
}

-(IBAction)stepForward:(id)sender
{
    if(self.audio) {
        double pos = self.audio.currentTime + 15;
        if(pos > self.audio.duration) pos = self.audio.duration;
        [self.audio setCurrentTime:pos];
    } else if(self.player) {
        double pos = CMTimeGetSeconds(self.player.currentTime) + 15;
        float len = [[audioObject valueForKey:@"length"] floatValue];
        if(pos > len) pos = len;
        [self.player seekToTime:CMTimeMakeWithSeconds(pos, 1)];
    }
    [self updateTimer:nil];
}

-(IBAction)playOrPause:(id)sender
{
    if([self.playPause isSelected]) {
        if(self.audio) [self.audio play];
        else if(self.player) [self.player play];
        [self.playPause setSelected:NO];
    } else {
        if(self.audio) [self.audio pause];
        else if(self.player) [self.player pause];
        [self.playPause setSelected:YES];
    }
}

-(IBAction)changeSpeed:(id)sender
{
    if(speed == 1.f) {
        speed = 2.f;
        [self.playSpeed setImage:[UIImage imageNamed:@"speed_double"] forState:UIControlStateNormal];
    } else if(speed == 2.f) {
        speed = 0.5f;
        [self.playSpeed setImage:[UIImage imageNamed:@"speed_half"] forState:UIControlStateNormal];
    } else {
        speed = 1.f;
        [self.playSpeed setImage:[UIImage imageNamed:@"speed_normal"] forState:UIControlStateNormal];
    }
    if(self.audio) [self.audio setRate:speed];
    else if(self.player) [self.player setRate:speed];
}

-(CALayer *)createShadowWithFrame:(CGRect)frame
{
    CAGradientLayer *gradient = [CAGradientLayer layer];
    gradient.frame = frame;
    
    
    UIColor* lightColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
    UIColor* darkColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    
    gradient.colors = [NSArray arrayWithObjects:(id)darkColor.CGColor, (id)lightColor.CGColor, nil];
    
    return gradient;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

#pragma mark -

-(void) updateTimer:(NSTimer*)timer
{
    float position;
    float length;
    float volume;

    if(self.audio) {
        position = self.audio.currentTime;
        length = self.audio.duration;
        volume = self.audio.volume;
    } else if(self.player) {
        position = CMTimeGetSeconds(self.player.currentTime);
        length = [[audioObject valueForKey:@"length"] floatValue];
        AVAudioMixInputParameters *params = [self.player.currentItem.audioMix.inputParameters objectAtIndex:0];
        if(![params getVolumeRampForTime:self.player.currentTime startVolume:&volume endVolume:nil timeRange:nil])
            volume = 1.f;
    } else return;
    float pos2 = length - position;
    [self.progress setValue:position/length];
    int h1, m1, s1;
    h1 = (int)(position / 3600);
    m1 = (int)(position / 60) % 60;
    s1 = (int)(position) % 60;
    int h2, m2, s2;
    h2 = (int)(pos2 / 3600);
    m2 = (int)(pos2 / 60) % 60;
    s2 = (int)(pos2) % 60;
    [self.label1 setText:[NSString stringWithFormat:@"%02d:%02d:%02d", h1, m1, s1]];
    [self.label2 setText:[NSString stringWithFormat:@"-%02d:%02d:%02d", h2, m2, s2]];
    float length2 = [[self.audioObject valueForKey:@"length"] floatValue];
    if(length2 == 0.f) [self.audioObject setValue:[NSNumber numberWithFloat:length] forKey:@"length"];
    
    [self.volume setValue:volume];
}

@end

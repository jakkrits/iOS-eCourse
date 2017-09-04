//
//  SoundViewController.m
//  it2
//
//  Created by Vasiliy Makarov on 18.03.13.
//
//

#import "SoundViewController.h"
#import "AppDelegate.h"

@interface SoundViewController () {
    CGFloat speed;
    NSTimer *myTimer;
}

@end

@implementation SoundViewController

@synthesize timeLabel1, timeLabel2, progressSlider, pauseButton, speedButton, content = _content, audioPlayer = _audioPlayer, scrollButton1, scrollButton2, aPlayer = _aPlayer;

-(void)viewDidLoad
{
}

-(void)viewWillAppear:(BOOL)animated
{
    myTimer = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSRunLoopCommonModes];
    [self updateControls];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [myTimer invalidate];
    myTimer = nil;
}

-(void)setContent:(NSManagedObject *)content
{
    _content = content;
    speed = [[_content valueForKey:@"rate"] floatValue];
}

-(void)setAudioPlayer:(AVAudioPlayer *)audioPlayer
{
    _audioPlayer = audioPlayer;
    [self updateControls];
}

-(void)setAPlayer:(AVPlayer *)aPlayer
{
    _aPlayer = aPlayer;
    [self updateControls];
}

-(void)updateControls
{
    if(_audioPlayer || _aPlayer) {
        [progressSlider setEnabled:YES];
        [pauseButton setEnabled:YES];
        [speedButton setEnabled:YES];
        scrollButton1.enabled = YES;
        scrollButton2.enabled = YES;
        float length = -1.f;
        float pos = -1.f;
        BOOL playing = NO;
        if(_audioPlayer) {
            speed = _audioPlayer.rate;
            length = _audioPlayer.duration;
            pos = _audioPlayer.currentTime;
            playing = _audioPlayer.isPlaying;
        } else {
            speed = _aPlayer.rate;
            pos = CMTimeGetSeconds(_aPlayer.currentTime);
            playing = _aPlayer.rate > 0.f;
            if(_aPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay)
                length = CMTimeGetSeconds(_aPlayer.currentItem.asset.duration);
        }
        [progressSlider setValue:pos/length animated:YES];
        if(playing) {
            [pauseButton setSelected:NO];
        } else {
            [pauseButton setSelected:YES];
        }
        if(speed == 1.f) {
            [speedButton setImage:[UIImage imageNamed:@"speed_normal"] forState:UIControlStateNormal];
        } else if(speed > 1.f) {
            [speedButton setImage:[UIImage imageNamed:@"speed_double"] forState:UIControlStateNormal];
        } else {
            [speedButton setImage:[UIImage imageNamed:@"speed_half"] forState:UIControlStateNormal];
        }
    } else {
        progressSlider.enabled = NO;
        pauseButton.enabled = NO;
        speedButton.enabled = NO;
        scrollButton1.enabled = NO;
        scrollButton2.enabled = NO;
        
    }
    [self updateTimer:nil];
}

-(IBAction)goBackward:(id)sender
{
    if(_audioPlayer != nil) {
        double pos = _audioPlayer.currentTime - 15;
        if(pos < 0) pos = 0;
        [_audioPlayer setCurrentTime:pos];
    } else if(_aPlayer != nil) {
        double pos = CMTimeGetSeconds(_aPlayer.currentTime) - 15;
        if(pos < 0) pos = 0;
        [_aPlayer seekToTime:CMTimeMakeWithSeconds(pos, 1)];
    }
    [self updateTimer:nil];
}

-(IBAction)goForward:(id)sender
{
    if(_audioPlayer != nil) {
        double pos = _audioPlayer.currentTime + 15;
        if(pos > _audioPlayer.duration) pos = _audioPlayer.duration;
        [_audioPlayer setCurrentTime:pos];
    } else if(_aPlayer != nil) {
        double pos = CMTimeGetSeconds(_aPlayer.currentTime) + 15;
        if(pos < 0) pos = 0;
        [_aPlayer seekToTime:CMTimeMakeWithSeconds(pos, 1)];
    }
    [self updateTimer:nil];
}

-(IBAction)playPause:(id)sender
{
    if([pauseButton isSelected]) {
        if(_audioPlayer != nil) [_audioPlayer play];
        else if(_aPlayer != nil) [_aPlayer play];
        [pauseButton setSelected:NO];
    } else {
        if(_audioPlayer != nil) [_audioPlayer pause];
        else if(_aPlayer != nil) [_aPlayer pause];
        [pauseButton setSelected:YES];
    }
}

-(IBAction)selectSpeed:(id)sender
{
    if(_audioPlayer == nil && _aPlayer == nil) return;
    if(speed == 1.f) {
        speed = 2.f;
        [speedButton setImage:[UIImage imageNamed:@"speed_double"] forState:UIControlStateNormal];
    } else if(speed > 1.f) {
        speed = 0.5f;
        [speedButton setImage:[UIImage imageNamed:@"speed_half"] forState:UIControlStateNormal];
    } else {
        speed = 1.f;
        [speedButton setImage:[UIImage imageNamed:@"speed_normal"] forState:UIControlStateNormal];
    }
    if(_audioPlayer != nil) [_audioPlayer setRate:speed];
    else if(_aPlayer != nil) [_aPlayer setRate:speed];
    [_content setValue:[NSNumber numberWithFloat:speed] forKey:@"rate"];
}

-(IBAction)setPosition:(id)sender
{
    if(_audioPlayer != nil) {
        [_audioPlayer setCurrentTime:progressSlider.value * _audioPlayer.duration];
    } else if(_aPlayer != nil) {
        if(_aPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            double len = CMTimeGetSeconds(_aPlayer.currentItem.asset.duration);
            [_aPlayer seekToTime:CMTimeMakeWithSeconds(progressSlider.value*len, 1)];
        }
    }
}

#pragma mark -

-(void) updateTimer:(NSTimer*)timer
{
    if(_audioPlayer == nil && _aPlayer == nil) {
        [timeLabel1 setText:@"00:00:00"];
        [timeLabel2 setText:@"-00:00:00"];
        return;
    }
    float position = -1.f;
    float length = -1.f;
    if(_audioPlayer != nil) {
        position = _audioPlayer.currentTime;
        length = _audioPlayer.duration;
    } else if(_aPlayer) {
        position = CMTimeGetSeconds(_aPlayer.currentTime);
        if(_aPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay)
            length = CMTimeGetSeconds(_aPlayer.currentItem.asset.duration);
    }
    float pos2 = length - position;
    [progressSlider setValue:position/length];
    int h1, m1, s1;
    int h2, m2, s2;
    h1 = (int)(position / 3600);
    m1 = (int)(position / 60) % 60;
    s1 = (int)(position) % 60;
    h2 = (int)(pos2 / 3600);
    m2 = (int)(pos2 / 60) % 60;
    s2 = (int)(pos2) % 60;
    [timeLabel1 setText:[NSString stringWithFormat:@"%02d:%02d:%02d", h1, m1, s1]];
    [timeLabel2 setText:[NSString stringWithFormat:@"-%02d:%02d:%02d", h2, m2, s2]];
    if(length > 0.f) [_content setValue:[NSNumber numberWithFloat:length] forKey:@"length"];
    static int saveCounter = 0;
    saveCounter ++;
    if(saveCounter >= 10) {
        saveCounter = 0;
        if(position >= 0.f) [AppDelegate setProgress:position forContent:_content];
    }
}


@end

//
//  iPhoneDetailControllerViewController.m
//  it2
//
//  Created by Vasiliy Makarov on 16.04.13.
//
//

#import "iPhoneDetailController.h"
#import "AppDelegate.h"
#import "MasterCell.h"
#import "iPhoneControlsController.h"

AVPlayer *_aPlayer = nil;
AVAudioPlayer *_audioPlayer = nil;

@interface iPhoneDetailController () {
    BOOL interruptedOnPlayback;
    NSManagedObject *audioContent;
    NSTimer *myTimer;
}

@end

@implementation iPhoneDetailController {
    NSString *cellTitle;
    NSString *cellSubtitle;
}

@synthesize contents;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    self.table.dataSource = self;
    self.table.delegate = self;
    [[AppDelegate instance] prepareIPhoneViewController:self leftButtons:NO];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(progressDidChange:) name:nPROGRESS_CHANGED object:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
    if(nil != _audioPlayer) _audioPlayer.delegate = self;
    myTimer = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(updateTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSRunLoopCommonModes];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [myTimer invalidate];
    myTimer = nil;
    _audioPlayer.delegate = nil;
}

-(AVAudioPlayer*)audioPlayer
{
    return _audioPlayer;
}

-(AVPlayer*)aPlayer
{
    return _aPlayer;
}

-(void)stopAudio
{
    [_audioPlayer stop];
    [_aPlayer pause];
    _audioPlayer = nil;
    _aPlayer = nil;
}

-(void)continueAudio
{
    if(_audioPlayer) [_audioPlayer play];
    else if(_aPlayer) [_aPlayer play];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

-(void)processChapter:(NSManagedObject*)chapter
{
    self.navigationItem.title = [chapter valueForKey:@"title"];
    self.contents = [[chapter valueForKey:@"contents"] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2){
        int key1 = [[obj1 valueForKey:@"key"] intValue];
        int key2 = [[obj2 valueForKey:@"key"] intValue];
        if(key1 < key2) return NSOrderedAscending;
        if(key1 > key2) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    [self.table reloadData];
}

-(void)videoPlaybackDidFinish:(NSNotification*)notification
{
    [_movieController dismissMoviePlayerViewControllerAnimated];
    NSTimeInterval pr = _movieController.moviePlayer.currentPlaybackTime;
    [AppDelegate setProgress:pr forContent:[AppDelegate instance].curContent];
    self.movieController = nil;
}

-(void)setVideoPosition:(NSTimer*)timer
{
    [_movieController.moviePlayer setCurrentPlaybackTime:[timer.userInfo floatValue]];
    float length = [[[AppDelegate instance].curContent valueForKey:@"length"] floatValue];
    NSNumber *nl = [NSNumber numberWithFloat:[_movieController.moviePlayer duration]];
    if(length == 0.f) [[AppDelegate instance].curContent setValue:nl forKey:@"length"];
}

#pragma mark - AVAudioPlayerDelegate

- (void) audioPlayerBeginInterruption: (AVAudioPlayer *) player {
    if ([player isPlaying]) {
        interruptedOnPlayback = YES;
    }
}

- (void) audioPlayerEndInterruption: (AVAudioPlayer *) player {
    if (interruptedOnPlayback) {
        [player prepareToPlay];
        [player play];
        interruptedOnPlayback = NO;
    }
}

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    if(flag) {
        [AppDelegate setProgress:[[audioContent valueForKey:@"length"] floatValue] forContent:audioContent];
    }
    _audioPlayer = nil;
    audioContent = nil;
}

#pragma mark - UITableViewDataSource

-(UITableViewCell*) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContentCell";
    
    MasterCell *cell = (MasterCell *)[_table dequeueReusableCellWithIdentifier:CellIdentifier];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(self.contents == nil) return 0;
    return [self.contents count];
}

#pragma mark - UITableViewDelegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSManagedObject *object = [contents objectAtIndex:[indexPath indexAtPosition:1]];
    [AppDelegate instance].curContent = object;
    int type = [[object valueForKey:@"type"] intValue];
    double position = [[object valueForKey:@"progress"] doubleValue];
    switch (type) {
        case 0:
            // video
        {
            [self stopAudio];
            NSString *file = [object valueForKey:@"file"];
            if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Video"];
            if(nil != file) {
                // local video file
                _movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL fileURLWithPath:file]];
            } else {
                // remote video file
                _movieController = [[MPMoviePlayerViewController alloc] initWithContentURL:[NSURL URLWithString:[object valueForKey:@"file"]]];
            }
            [self presentMoviePlayerViewControllerAnimated:_movieController];
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoPlaybackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:_movieController.moviePlayer];
            if(![_movieController.moviePlayer isPreparedToPlay])
                [_movieController.moviePlayer prepareToPlay];
            {
                NSTimer *setVideoPosition = [NSTimer timerWithTimeInterval:1.f target:self selector:@selector(setVideoPosition:) userInfo:[NSNumber numberWithFloat:position] repeats:NO];
                [[NSRunLoop currentRunLoop] addTimer:setVideoPosition forMode:NSRunLoopCommonModes];
            }
        }
            break;
        case 1:
            // audio
        {
            if(audioContent == object) {
                // already playing this file
                [self continueAudio];
            } else {
                [self stopAudio];
                audioContent = object;
                CGFloat speed = [[object valueForKey:@"rate"] floatValue];
                NSString *file = [object valueForKey:@"file"];
                if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                    file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Audio"];
                if(nil != file) {
                    // local audio file
                    NSError *err;
                    _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL fileURLWithPath:file] error:&err];
                    if(err != nil) NSLog(@"%@", err);
                    [_audioPlayer setEnableRate:YES];
                    [_audioPlayer setDelegate:self];
                    [_audioPlayer prepareToPlay];
                    [_audioPlayer play];
                    [_audioPlayer setCurrentTime:position];
                    [_audioPlayer setRate:speed];
                } else {
                    // remote audio file
                    _aPlayer = [AVPlayer playerWithURL:[NSURL URLWithString:[object valueForKey:@"file"]]];
                    [_aPlayer play];
                    [_aPlayer seekToTime:CMTimeMakeWithSeconds(position, 1)];
                    [_aPlayer setRate:speed];
                }
            }
            MasterCell *cell = (MasterCell*)[tableView cellForRowAtIndexPath:indexPath];
            cellTitle = cell.titleLabel.text;
            cellSubtitle = cell .textLabel.text;
            [self performSegueWithIdentifier:@"ControlsSegue" sender:self];
        }
            break;
        case 2:
        {
            // text
            ITTextViewController * _textViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TextViewController"];
            _textViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            _textViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            _textViewController.detailItem = object;
            [self presentViewController:_textViewController animated:YES completion:^(void){}];
            break;
        }
        case 3:
            // quiz
        {
            ITQuizViewController *_quizViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"QuizViewController"];
            NSString *file = [object valueForKey:@"file"];
            if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Quiz"];
            if(nil != file) {
                [_quizViewController loadQuizFromFile:file];
            } else {
                [_quizViewController loadQuizFromUrl:[object valueForKey:@"file"]];
            }
            _quizViewController.detailItem = object;
            _quizViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            _quizViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:_quizViewController animated:YES completion:^(void){}];
        }
            break;
        case 4:
            // todo
        {
            ITTodoViewController * _todoViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"TodoViewController"];
            _todoViewController.detailItem = object;
            NSString *file = [object valueForKey:@"file"];
            if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Todo"];
            if(nil != file) {
                [_todoViewController loadTodoFromFile:file];
            } else {
                [_todoViewController loadTodoFromUrl:[object valueForKey:@"file"]];
            }
            _todoViewController.modalPresentationStyle = UIModalPresentationFormSheet;
            _todoViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
            [self presentViewController:_todoViewController animated:YES completion:^(void){}];
        }
            break;
    }
}

-(void)configureCell:(MasterCell*)cell atIndexPath:(NSIndexPath*)indexPath
{
    if(cell.tag == 0) {
        cell.roundProgress.fontSize = 20;
        cell.roundProgress.tintColor = [UIColor colorWithRed:0 green:1.0 blue:0 alpha:0.5];
        cell.tag = 1;
    }
    int lastIndex = [self tableView:self.table numberOfRowsInSection:indexPath.section] - 1;
    if(cell.tag == 1 && indexPath.row == lastIndex) {
        CALayer* shadow = [self createShadowWithFrame:CGRectMake(0, cell.frame.size.height, 320, 5)];
        shadow.name = @"shadow";
        [cell.layer addSublayer:shadow];
        cell.tag = 2;
    } else if(cell.tag == 2 && indexPath.row != lastIndex) {
        CALayer *sh = nil;
        for (CALayer *l in cell.layer.sublayers) {
            if([l.name isEqualToString:@"shadow"]) {
                sh = l;
                break;
            }
        }
        [sh removeFromSuperlayer];
        cell.tag = 1;
    }
    NSManagedObject *content = [self.contents objectAtIndex:[indexPath indexAtPosition:1]];
    NSString *file = [content valueForKey:@"file"];
    NSInteger type = [[content valueForKey:@"type"] intValue];
    switch (type) {
        case 0:
            // video
            cell.titleLabel.text = NSLocalizedString(@"Video", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Watch the video of this lesson. Obviously, watching the video is the easiest way to learn.", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"video.png"]];

            if([AppDelegate instance].allowSaveVideoToCameraRoll) {
                if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
                    file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Video"];
                if(nil != file) {
                    // local video file
                    UIButton *sv = [UIButton buttonWithType:UIButtonTypeCustom];
                    sv.frame = CGRectMake(205, 7, 30, 25);
                    [sv setImage:[UIImage imageNamed:@"share-button.png"] forState:UIControlStateNormal];
                    [cell addSubview:sv];
                    [sv addTarget:self action:@selector(saveVideoTrack:) forControlEvents:UIControlEventTouchDown];
                    sv.tag = [indexPath indexAtPosition:1];
                }
            }
            break;
        case 1:
            // audio
            cell.titleLabel.text = NSLocalizedString(@"Audio", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Listen to this lesson. Use this option when you're doing something else.", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"headphones.png"]];
            break;
        case 2:
            // text
            cell.titleLabel.text = NSLocalizedString(@"Text", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Read the lesson. It helps you to study it thoughtfully.", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"paper.png"]];
            break;
        case 3:
            // quiz
            cell.titleLabel.text = NSLocalizedString(@"Quiz", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Test yourself. Do you remember all the terms from this lesson?", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"penpaper.png"]];
            break;
        case 4:
            // todo
            cell.titleLabel.text = NSLocalizedString(@"ToDo", @"content type");
            cell.textLabel.text = NSLocalizedString(@"Checklist for this lesson. What exactly should you do for getting the result.", @"content type description");
            [cell.avatarImageView setImage:[UIImage imageNamed:@"checklist.png"]];
            break;
        default:
            break;
    }
    NSString *customTitle = [content valueForKey:@"title"];
    if(customTitle != nil && [customTitle length] > 0) cell.titleLabel.text = customTitle;
    NSString *customSubtitle = [content valueForKey:@"subtitle"];
    if(customSubtitle != nil && [customSubtitle length] > 0) cell.textLabel.text = customSubtitle;
    float record = [[content valueForKey:@"record"] floatValue];
    [cell.roundProgress setProgress:record];
}

#pragma mark -

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"ControlsSegue"]) {
        iPhoneControlsController *cc = segue.destinationViewController;
        cc.audio = self.audioPlayer;
        cc.player = self.aPlayer;
        cc.audioObject = audioContent;
        cc.audioTitleText = cellTitle;
        cc.audioSubtitleText = cellSubtitle;
        cc.navigationItem.title = self.navigationItem.title;
    }
}

-(void) updateTimer:(NSTimer*)timer
{
    float position = -1.f;
    float length = -1.f;
    float rate = -1.f;
    if(_audioPlayer != nil && audioContent != nil) {
        position = _audioPlayer.currentTime;
        length = _audioPlayer.duration;
        rate = _audioPlayer.rate;
    }
    if(_aPlayer != nil && audioContent != nil) {
        AVPlayerItem *playerItem = [_aPlayer currentItem];
        if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
            length = CMTimeGetSeconds([[playerItem asset] duration]);
        }
        position = CMTimeGetSeconds(_aPlayer.currentTime);
        rate = _aPlayer.rate;
    }
    if(length > 0.f) [audioContent setValue:[NSNumber numberWithFloat:length] forKey:@"length"];
    if(rate > 0.f) [audioContent setValue:[NSNumber numberWithFloat:rate] forKey:@"rate"];
    if(position >= 0.f) [AppDelegate setProgress:position forContent:audioContent];
}

-(void)progressDidChange:(NSNotification*)notification
{
    NSManagedObject *content = notification.object;
    NSInteger ind = [contents indexOfObject:content];
    if(ind != NSNotFound) {
        NSIndexPath *index = [[NSIndexPath indexPathWithIndex:0] indexPathByAddingIndex:ind];
        MasterCell *c = (MasterCell*)[self.table cellForRowAtIndexPath:index];
        float rec = [[content valueForKey:@"record"] floatValue];
        c.roundProgress.progress = rec;
    }
}

-(void)saveVideoTrack:(UIButton*)sender
{
    NSManagedObject *content = [self.contents objectAtIndex:sender.tag];
    NSString *file = [content valueForKey:@"file"];
    NSInteger type = [[content valueForKey:@"type"] intValue];
    if(type == 0) {
        // video
        if(![[NSFileManager defaultManager] isReadableFileAtPath:file])
            file = [[NSBundle mainBundle] pathForResource:file ofType:nil inDirectory:@"data/Video"];
        if(nil != file) {
            // local video file
            if(UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(file)) {
                UISaveVideoAtPathToSavedPhotosAlbum(file, self, @selector(videoTrackSavedToCameraRoll:withError:userData:), (__bridge void *)(sender));
            } else {
                NSLog(@"Video file not compatible: %@", file);
            }
        }
    }
}

-(void)videoTrackSavedToCameraRoll:(NSString*)file withError:(NSError*)error userData:(void*)data
{
    UIButton *bt = (__bridge UIButton*)data;
    NSManagedObject *content = [self.contents objectAtIndex:bt.tag];
    NSString *customTitle = [content valueForKey:@"title"];
    if(nil == customTitle || customTitle.length <= 0) customTitle = NSLocalizedString(@"Video file", @"video file title");
    NSString *msg = NSLocalizedString(@"was saved to camera roll", @"file saved message");
    UIAlertView *av = [[UIAlertView alloc] initWithTitle:customTitle message:msg delegate:nil cancelButtonTitle:NSLocalizedString(@"Ok", @"button") otherButtonTitles: nil];
    [av show];
}

@end

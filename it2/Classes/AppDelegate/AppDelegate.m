//
//  AppDelegate.m
//  it2
//

#import "AppDelegate.h"
#import "MasterViewController.h"
#import "DetailThemeiPadController.h"
#import "MicroTransactions.h"
#import "ITHelpViewController.h"
#import "ITCertificateViewController.h"
#import "ITAboutViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "BlockAlertView.h"
#import "ASINetworkQueue.h"
#import "ASIHTTPRequest.h"
#import "ASIWebPageRequest.h"
#import <Parse/Parse.h>

BOOL AdMob = YES;
BOOL progressUnlock = NO;
BOOL allowAnonymous = YES;
BOOL loginAtStartUp = NO;

@interface AppDelegate () {
    PFLogInViewController *logInViewController;
    PFSignUpViewController *signUpViewController;
    NSMutableDictionary *remoteContent;
    ASINetworkQueue *queue;
    int dlCompleted;
    int dlFailed;
}

@end

@implementation AppDelegate

@synthesize window = _window;
@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize curChapter = _curChapter, curContent = _curContent;

void uncaughtExceptionHandler(NSException *exception) {
    NSLog(@"Exception: %@", exception);
}

+ (AppDelegate *)instance
{
    return (AppDelegate*)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    srandomdev();
    remoteContent = [NSMutableDictionary dictionary];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"infoproduct" ofType:@"plist" inDirectory:@"data"];
    NSData *plistData = [NSData dataWithContentsOfFile:path];
    NSError *error;
    NSPropertyListFormat format;
    infoproduct = [NSPropertyListSerialization propertyListWithData:plistData options:NSPropertyListImmutable format:&format error:&error ];
    if (!infoproduct) {
        NSLog(@"Failed to read infoproduct description. Error: %@", error);
    }
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud registerDefaults:[NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"defaults" ofType:@"plist" inDirectory:@"data"]]];
    
    self.colorSwitcher = [[ColorSwitcher alloc] initWithScheme:@"orange"];

    AdMob = [ud boolForKey:@"AdMob"];
    progressUnlock = [ud boolForKey:@"progressUnlock"];
    allowAnonymous = [ud boolForKey:@"allowAnonymous"];
    loginAtStartUp = [ud boolForKey:@"loginAtStartUp"];

    NSString *pAppId = [self parseAppId];
    NSString *pClientKey = [self parseClientKey];
    if(pAppId != nil && pClientKey != nil) {
        [Parse setApplicationId:pAppId clientKey:pClientKey];
        [PFUser enableAutomaticUser];
    } else {
        UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
        NSArray *vcs = tabBarController.viewControllers;
        [tabBarController setViewControllers:@[vcs[0], vcs[2]] animated:NO];
    }
    
    UIUserInterfaceIdiom idiom = [[UIDevice currentDevice] userInterfaceIdiom];
    if (idiom == UIUserInterfaceIdiomPad) 
    {
        [self customizeiPadTheme];
        
        [self iPadInit];
    }
    else 
    {
        [self customizeiPhoneTheme];
        
        [self configureiPhoneTabBar];
    }

    float mt = [[NSUserDefaults standardUserDefaults] floatForKey:@"moreAppsTimer"];
    if(mt == 0) mt = [self defaultMoreAppsTimer];
    if(mt > 0) {
        moreAppsTimer = [NSTimer timerWithTimeInterval:mt target:self selector:@selector(moreApps:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:moreAppsTimer forMode:NSRunLoopCommonModes];
    }
    [self loadItems];

    // Clear application badge when app launches
	application.applicationIconBadgeNumber = 0;
    [application registerForRemoteNotificationTypes:UIRemoteNotificationTypeAlert | UIRemoteNotificationTypeBadge | UIRemoteNotificationTypeSound];

    if(self.AppPurchase) {
        InitStore(@[self.AppPurchase], NO);
        [PFPurchase addObserverForProduct:self.AppPurchase block:^(SKPaymentTransaction* transaction){
            [self purchaseComplete];
        }];
    }
    [self performSelector:@selector(firstStart:) withObject:nil afterDelay:1.f];
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    UInt32 doSetProperty = 1;
    AudioSessionSetProperty (kAudioSessionProperty_OverrideCategoryMixWithOthers, sizeof(doSetProperty), &doSetProperty);
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    
    return YES;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)devToken
{
#if !TARGET_IPHONE_SIMULATOR
    
    // Tell Parse about the device token.
    [PFPush storeDeviceToken:devToken];
    // Subscribe to the global broadcast channel.
    //[PFPush subscribeToChannelInBackground:@""];
    [[PFInstallation currentInstallation] addUniqueObject:@"" forKey:@"channels"];
    [[PFInstallation currentInstallation] saveEventually];
#endif
}

-(void)firstStart:(id)sender
{
    // check user login
    if (loginAtStartUp && self.parseAppId && self.parseClientKey && [PFAnonymousUtils isLinkedWithUser:[PFUser currentUser]]) {
        [[AppDelegate instance] userLogIn];
    } else {
        NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
        if([ud boolForKey:@"showAboutAtFirstStart"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:nFIRST_START object:nil];
        } else if([ud boolForKey:@"showHelpAtStart"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:nSHOW_HELP object:nil];
        }
    }
}

-(void)setCurChapter:(NSManagedObject *)curChapter
{
    _curChapter = curChapter;
    [[NSNotificationCenter defaultCenter] postNotificationName:nCHAPTER_CHANGED object:curChapter];
}

-(void)setCurContent:(NSManagedObject *)curContent
{
    _curContent = curContent;
    [[NSNotificationCenter defaultCenter] postNotificationName:nCONTENT_CHANGED object:curContent];
}

-(void)customizeiPhoneTheme
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
    UIImage *navBarImage = nil;
    if(NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        navBarImage = [[UIImage tallImageNamed:@"menubar.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 15, 5, 15)];

        UIImage *barButton = [[UIImage tallImageNamed:@"menubar-button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 4, 0, 4)];
        
        [[UIBarButtonItem appearance] setBackgroundImage:barButton forState:UIControlStateNormal
                                              barMetrics:UIBarMetricsDefault];
        
        UIImage *backButton = [[UIImage tallImageNamed:@"back.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 4)];
        
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButton forState:UIControlStateNormal
                                                        barMetrics:UIBarMetricsDefault];
    } else {
        navBarImage = [[UIImage tallImageNamed:@"menubar-ios7.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(5, 15, 5, 15)];
        self.window.tintColor = [UIColor whiteColor];

        [[UINavigationBar appearance] setTitleTextAttributes:
         [NSDictionary dictionaryWithObjectsAndKeys:
          [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0],
          UITextAttributeTextColor,
          [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8],
          UITextAttributeTextShadowColor,
          [NSValue valueWithUIOffset:UIOffsetMake(0, -1)],
          UITextAttributeTextShadowOffset,
          nil]];
    }
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault];
    // Omit the conditional if minimum OS is iOS 6 or above
    if ([UINavigationBar instancesRespondToSelector:@selector(setShadowImage:)]) {
        [[UINavigationBar appearance] setShadowImage:[UIImage tallImageNamed:@"menubar-shadow.png"]];
    }
    
    
    UIImage *minImage = [UIImage tallImageNamed:@"ipad-slider-fill"];
    UIImage *maxImage = [UIImage tallImageNamed:@"ipad-slider-track.png"];
    UIImage *thumbImage = [UIImage tallImageNamed:@"ipad-slider-handle.png"];
    
    [[UISlider appearance] setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [[UISlider appearance] setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateHighlighted];
    
    UIImage* tabBarBackground = [UIImage tallImageNamed:@"tabbar.png"];
    [[UITabBar appearance] setBackgroundImage:tabBarBackground];
    
    
    [[UITabBar appearance] setSelectionIndicatorImage:[UIImage tallImageNamed:@"tabbar-active.png"]];

}

-(void)customizeiPadTheme
{
    UIImage *navBarImage = nil;
    if(NSFoundationVersionNumber <= NSFoundationVersionNumber_iOS_6_1) {
        navBarImage = [UIImage tallImageNamed:@"ipad-menubar-right.png"];
        
        UIImage *backButton = [[UIImage tallImageNamed:@"back.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 14, 0, 4)];
        [[UIBarButtonItem appearance] setBackButtonBackgroundImage:backButton forState:UIControlStateNormal
                                                        barMetrics:UIBarMetricsDefault];
        
        UIImage *barItemImage = [[UIImage tallImageNamed:@"ipad-menubar-button.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 5, 0, 5)];
        [[UIBarButtonItem appearance] setBackgroundImage:barItemImage forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];

        UIImage* tabBarBackground = [UIImage tallImageNamed:@"tabbar.png"];
        [[UITabBar appearance] setBackgroundImage:tabBarBackground];
        
        [[UITabBar appearance] setSelectionIndicatorImage:[UIImage tallImageNamed:@"tabbar-active.png"]];
    } else {
        self.window.tintColor = [UIColor whiteColor];
        navBarImage = [UIImage tallImageNamed:@"ipad-menubar-right-ios7.png"];

        [[UITabBar appearance] setBackgroundImage:[UIImage tallImageNamed:@"tabbar-ios7.png"]];
        [[UITabBar appearance] setSelectionIndicatorImage:[UIImage tallImageNamed:@"tabbar-active-ios7.png"]];
    }
    
    [[UINavigationBar appearance] setBackgroundImage:navBarImage forBarMetrics:UIBarMetricsDefault]; 
    [[UINavigationBar appearance] setTitleTextAttributes:
     [NSDictionary dictionaryWithObjectsAndKeys:
      [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0], 
      UITextAttributeTextColor, 
      [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8], 
      UITextAttributeTextShadowColor, 
      [NSValue valueWithUIOffset:UIOffsetMake(0, -1)], 
      UITextAttributeTextShadowOffset, 
      nil]];

    UIImage *minImage = [UIImage tallImageNamed:@"ipad-slider-fill"];
    UIImage *maxImage = [UIImage tallImageNamed:@"ipad-slider-track.png"];
    UIImage *thumbImage = [UIImage tallImageNamed:@"ipad-slider-handle.png"];
    
    [[UISlider appearance] setMaximumTrackImage:maxImage forState:UIControlStateNormal];
    [[UISlider appearance] setMinimumTrackImage:minImage forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateNormal];
    [[UISlider appearance] setThumbImage:thumbImage forState:UIControlStateHighlighted];
    
}


-(void)iPadInit
{
    UITabBarController *tabBarController = (UITabBarController *)self.window.rootViewController;
    UISplitViewController *splitViewController = (UISplitViewController *)[tabBarController.viewControllers objectAtIndex:0];
    
    splitViewController.delegate = [splitViewController.viewControllers lastObject];
    
    DetailThemeiPadController *detail = [DetailThemeiPadController instance];
    
    UINavigationController* nav = [splitViewController.viewControllers objectAtIndex:0];
    
    MasterViewController* master = [nav.viewControllers objectAtIndex:0];
    
    master.delegate = detail;
    splitViewController.delegate = detail;
    
}


-(void)configureiPhoneTabBar
{
}

-(void)configureTabBarItemWithImageName:(NSString*)imageName andText:(NSString *)itemText forViewController:(UIViewController *)viewController
{
    UIImage* icon1 = [UIImage tallImageNamed:imageName];
    UITabBarItem *item1 = [[UITabBarItem alloc] initWithTitle:itemText image:icon1 tag:0];
    [item1 setFinishedSelectedImage:icon1 withFinishedUnselectedImage:icon1];
    
    [viewController setTabBarItem:item1];
}

							
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
    [self saveContext];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
    [self saveContext];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
    [self saveContext];
}

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

-(NSDictionary*)content
{
    return [infoproduct valueForKey:@"Content"];
}

-(NSString*)title
{
    return [infoproduct valueForKey:@"Title"];
}

-(NSString*)subtitle
{
    return [infoproduct valueForKey:@"Subtitle"];
}

-(float)defaultMoreAppsTimer
{
    return [[infoproduct valueForKey:@"MoreAppsTimer"] floatValue];
}

-(NSString*)moreAppsURL
{
    return [infoproduct valueForKey:@"MoreAppsUrl"];
}

-(NSString*)parseAppId
{
    return [infoproduct valueForKey:@"ParseAppId"];
}

-(NSString*)parseClientKey
{
    return [infoproduct valueForKey:@"ParseClientKey"];
}

-(NSString*)appSalesKey
{
    return [infoproduct valueForKey:@"AppSalesKey"];
}

-(NSString*)flurryKey
{
    return [infoproduct valueForKey:@"FlurryKey"];
}

-(NSString*)adMobId
{
    return [infoproduct valueForKey:@"AdMobId"];
}

-(NSString*)certificate
{
    return [infoproduct valueForKey:@"Certificate"];
}

-(NSString*)AppPurchase
{
    return [infoproduct valueForKey:@"AppPurchase"];
}

-(BOOL)allowSaveVideoToCameraRoll
{
    return [[infoproduct valueForKey:@"SaveVideoToCameraRoll"] boolValue];
}

#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"InfoTemplate" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"InfoTemplate.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil];
        _persistentStoreCoordinator = nil;
        return [self persistentStoreCoordinator];
        //abort();
    }
    
    return _persistentStoreCoordinator;
}

-(NSManagedObject*)chapterById:(NSString*)chapterId
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chapter" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"key=%@", chapterId];
    [fetchRequest setPredicate:predicate];
    
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor];
    [fetchRequest setSortDescriptors:sortDescriptors];

    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"AppDelegate"];
    aFetchedResultsController.delegate = nil;
    
    NSError *error = nil;
    if (![aFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        return nil;
    }
    for (id obj in aFetchedResultsController.fetchedObjects) {
        // return first object
        return obj;
    }
    return nil;
}

-(NSManagedObject*)getFirstChapter
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chapter" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"AppDelegate"];
    aFetchedResultsController.delegate = nil;
    
	NSError *error = nil;
	if (![aFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    for(id obj in aFetchedResultsController.fetchedObjects) {
        return obj;
    }
    return nil;
}

-(void)loadItems
{
    const BOOL purchased = [[[NSUserDefaults standardUserDefaults] valueForKey:@"PurchaseComplete"] boolValue];
    BOOL hasDownloadableContent = NO;
    NSManagedObjectContext *context = [self managedObjectContext];
    int chapters = 0;
    NSDictionary *content = [self content];
    for (NSString* key in [content allKeys]) {
        NSDictionary *obj = [content valueForKey:key];
        NSManagedObject *newChapter = [self chapterById:key];
        BOOL newOne = NO;
        if(newChapter == nil) {
            newChapter = [NSEntityDescription insertNewObjectForEntityForName:@"Chapter" inManagedObjectContext:context];
            [newChapter setValue:key forKey:@"key"];
            float pr =  [obj valueForKey:@"progress"] != nil ? [[obj valueForKey:@"progress"] floatValue] : -1.f;
            [newChapter setValue:[NSNumber numberWithFloat:pr] forKey:@"progress"];
            newOne = YES;
        } else {
            float opr = [[newChapter valueForKey:@"progress"] floatValue];
            float npr =  [obj valueForKey:@"progress"] != nil ? [[obj valueForKey:@"progress"] floatValue] : -1.f;
            if(opr < 0.f && npr >= 0.f) {
                [newChapter setValue:[NSNumber numberWithFloat:npr] forKey:@"progress"];
            } else if(opr >= 0.f && npr < 0.f && !purchased && !progressUnlock) {
                [newChapter setValue:[NSNumber numberWithFloat:npr] forKey:@"progress"];
            }
        }
        [newChapter setValue:[obj valueForKey:@"order"] forKey:@"order"];
        [newChapter setValue:[obj valueForKey:@"title"] forKey:@"title"];
        [newChapter setValue:[obj valueForKey:@"name"] forKey:@"name"];
        if([key hasPrefix:@"chapter"]) [newChapter setValue:@"A" forKey:@"section"];
        else if([key hasPrefix:@"bonus"]) [newChapter setValue:@"B" forKey:@"section"];
        else [newChapter setValue:@"Z" forKey:@"section"];
        NSMutableArray *oldContent = [[newChapter valueForKey:@"contents"] mutableCopy];
        for(NSString *key2 in [obj allKeys]) {
            if([[obj valueForKey:key2] isKindOfClass:[NSDictionary class]]) {
                NSDictionary *content = (NSDictionary*)[obj valueForKey:key2];
                NSManagedObject *newContent = nil;
                int contKey = [[content valueForKey:@"key"] intValue];
                for (NSManagedObject *o in oldContent) {
                    if([[o valueForKey:@"key"] intValue] == contKey) {
                        newContent = o;
                        [oldContent removeObject:o];
                        break;
                    }
                }
                NSString *file = [content valueForKey:@"file"];
                if(nil == newContent) {
                    newContent = [NSEntityDescription insertNewObjectForEntityForName:@"Content" inManagedObjectContext:context];
                    [newContent setValue:[NSNumber numberWithInt:contKey] forKey:@"key"];
                    [newContent setValue:file forKey:@"file"];
                    [newContent setValue:[content valueForKey:@"type"] forKey:@"type"];
                    [newContent setValue:[content valueForKey:@"picture"] forKey:@"picture"];
                    [newContent setValue:[NSNumber numberWithFloat:1.f] forKey:@"rate"];
                    [newContent setValue:[content valueForKey:@"length"] forKey:@"length"];
                    [newContent setValue:[NSNumber numberWithFloat:0.f] forKey:@"progress"];
                    [newContent setValue:[NSNumber numberWithFloat:0] forKey:@"record"];
                    [newContent setValue:newChapter forKey:@"chapter"];
                }
                NSString *contTitle = [content valueForKey:@"title"];
                NSString *contSubtitle = [content valueForKey:@"subtitle"];
                [newContent setValue:contTitle forKey:@"title"];
                [newContent setValue:contSubtitle forKey:@"subtitle"];
                NSURL *url = [NSURL URLWithString:[newContent valueForKey:@"file"]];
                if(url.scheme != nil && [url.scheme length] > 0) {
                    hasDownloadableContent = YES;
                    NSMutableArray *contentList = [remoteContent valueForKey:file];
                    if(nil == contentList) contentList = [NSMutableArray array];
                    [contentList addObject:newContent];
                    [remoteContent setValue:contentList forKey:[url absoluteString]];
                }
            }
        }
        for (NSManagedObject *o in oldContent) {
            // remove old stuff
            [context deleteObject:o];
        }
        chapters ++;
    }
    _curChapter = [self getFirstChapter];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    [[NSUserDefaults standardUserDefaults] setBool:hasDownloadableContent forKey:@"downloadable"];
}


#pragma mark - 

- (void)saveContext
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSTimeInterval ti = [[moreAppsTimer fireDate] timeIntervalSinceDate:[NSDate date]];
    if(ti < 0 || moreAppsTimer == nil) ti = -1;
    [ud setFloat:ti forKey:@"moreAppsTimer"];
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

-(BOOL)unlockNextChapter
{
    if(!progressUnlock) return NO;
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chapter" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"section" cacheName:@"Master"];
    aFetchedResultsController.delegate = nil;
    
	NSError *error = nil;
	if (![aFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    for (id obj in aFetchedResultsController.fetchedObjects) {
        float pr = [[obj valueForKey:@"progress"] floatValue];
        if(pr < 0.f) {
            [obj setValue:[NSNumber numberWithFloat:0.f] forKey:@"progress"];
            return YES;
        }
    }
    return NO;
}

-(BOOL)unlockAllChapters
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chapter" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"section" cacheName:@"Master"];
    aFetchedResultsController.delegate = nil;
    
	NSError *error = nil;
	if (![aFetchedResultsController performFetch:&error]) {
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        return NO;
	}
    for (id obj in aFetchedResultsController.fetchedObjects) {
        float pr = [[obj valueForKey:@"progress"] floatValue];
        if(pr < 0.f) {
            [obj setValue:[NSNumber numberWithFloat:0.f] forKey:@"progress"];
        }
    }
    return YES;
}

-(void)moreApps:(NSTimer*)timer
{
    UIAlertView *av =[[UIAlertView alloc] initWithTitle:nil message:@"Хотите посмотреть другие новые приложения от Infoizdat?" delegate:self cancelButtonTitle:@"Напомните позже" otherButtonTitles:@"Да, давайте", @"Нет, спасибо", nil];
    [av show];
}

-(void)alertView:(UIAlertView*)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // more apps
    switch (buttonIndex) {
        case 0:
        default:
            // later
            moreAppsTimer = [NSTimer timerWithTimeInterval:[self defaultMoreAppsTimer] target:self selector:@selector(moreApps:) userInfo:nil repeats:NO];
            [[NSRunLoop currentRunLoop] addTimer:moreAppsTimer forMode:NSRunLoopCommonModes];
            break;
        case 1:
            // ok
        {
            NSString *url = [self moreAppsURL];
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
        }
            break;
        case 2:
            // cancel
            break;
    }
}

#pragma mark Static methods

+(float)chapterProgress:(id)object
{
    float progress = [[object valueForKey:@"progress"] floatValue];
    for (NSManagedObject *mo in [object valueForKey:@"contents"]) {
        float pr = [[mo valueForKey:@"record"] floatValue];
        if(pr > 0.f && pr > progress) progress = pr;
    }
    return progress;
}

+(void)setProgress:(CGFloat)progress forContent:(NSManagedObject *)content
{
    CGFloat rec = [[content valueForKey:@"record"] floatValue];
    CGFloat pr = progress / [[content valueForKey:@"length"] floatValue];
    if(rec < pr) {
        [content setValue:[NSNumber numberWithFloat:pr] forKey:@"record"];
    }
    BOOL checkOverall = NO;
    if(pr >= 0.99) {
        progress = 0;
        checkOverall = YES;
    }
    [content setValue:[NSNumber numberWithFloat:progress] forKey:@"progress"];
    [[AppDelegate instance].managedObjectContext save:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:nPROGRESS_CHANGED object:content];
    if(pr >= 0.99)
        [[NSNotificationCenter defaultCenter] postNotificationName:nCHAPTER_FINISHED object:[content valueForKey:@"chapter"]];
    
    [AppDelegate storeProgress:MAX(rec, pr) forContent:content];
    if(checkOverall) [[AppDelegate instance] checkOverallProgress];
}

+(void)storeProgress:(CGFloat)progress forContent:(NSManagedObject*)content
{
    int contentType = [[content valueForKey:@"type"] intValue];
    // only quiz and todo
    if(contentType == 3 || contentType == 4) {
        NSString *chapterName = [[content valueForKey:@"chapter"] valueForKey:@"title"];
        NSString *ctype = nil;
        switch (contentType) {
            case 3:
            default:
                ctype = @"Quiz";
                break;
            case 4:
                ctype = @"Todo";
                break;
        }
        PFObject *result = nil;
        PFQuery *query = [PFQuery queryWithClassName:@"result"];
        [query whereKey:@"user" equalTo:[PFUser currentUser]];
        [query whereKey:@"chapter" equalTo:chapterName];
        [query whereKey:@"contentType" equalTo:ctype];
        NSArray *results = [query findObjects];
        if([results count] > 0) {
            result = [results objectAtIndex:0];
        } else {
            result = [PFObject objectWithClassName:@"result"];
            [result setValue:chapterName forKey:@"chapter"];
            [result setValue:[PFUser currentUser] forKey:@"user"];
            [result setValue:ctype forKey:@"contentType"];
        }
        [result setValue:[NSNumber numberWithInt:100.f*progress] forKey:@"progress"];
        [result save];
    }
}

-(void)checkOverallProgress
{
    NSLog(@"check overall progress");
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Chapter" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor1 = [[NSSortDescriptor alloc] initWithKey:@"section" ascending:YES];
    NSSortDescriptor *sortDescriptor2 = [[NSSortDescriptor alloc] initWithKey:@"order" ascending:YES];
    NSArray *sortDescriptors = @[sortDescriptor1, sortDescriptor2];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:@"section" cacheName:@"Master"];
    aFetchedResultsController.delegate = nil;
    
	NSError *error = nil;
	if (![aFetchedResultsController performFetch:&error]) {
        // Replace this implementation with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    for (id obj in aFetchedResultsController.fetchedObjects) {
        for (id cont in [obj valueForKey:@"contents"]) {
            int type = [[cont valueForKey:@"type"] intValue];
            if(type != 3 || type != 4) continue;
            float rec = [[cont valueForKey:@"record"] floatValue];
            if(rec < 0.99f) {
                NSLog(@"content progress: %f, chapter '%@', type %d", rec, [obj valueForKey:@"title"], type);
                return;
            }
        }
    }
    // all chapters complete
    [self makeCertificate];
}

#pragma mark Purchasing

-(void)objectPurchased:(NSNotification*)notification
{
    NSString *_id = notification.object;
    if([_id isEqualToString:self.AppPurchase]) {
        [self purchaseComplete];
    } else {
        NSLog(@"Unknown object have been purchased: %@", _id);
    }
}

-(void)purchaseComplete
{
    // unlock full course
    [self unlockAllChapters];
    AdMob = NO;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setBool:NO forKey:@"AdMob"];
    [[NSNotificationCenter defaultCenter] postNotificationName:nCHAPTER_FINISHED object:nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:nHIDE_ADS object:nil];
    [self setCurChapter:_curChapter];
    [[NSNotificationCenter defaultCenter] postNotificationName:nPURCHASE_COMPLETED object:nil];
    [ud setBool:YES forKey:@"PurchaseComplete"];
}

-(IBAction)inAppPurchase:(id)sender
{
    if(self.AppPurchase != nil) {
        [PFPurchase buyProduct:self.AppPurchase block:^(NSError *error){
            if(error) {
                NSLog(@"purchasing error: %@", error);
            } else {
                [BlockAlertView alertWithTitle:NSLocalizedString(@"Course unlocked", @"purchasing complete title") message:NSLocalizedString(@"Operation complete successfully", @"purchasing complete message") ];
            }
        }];
    }
}

-(IBAction)inAppRestore:(id)sender
{
    [PFPurchase restore];
}

-(UIBarButtonItem*)createBarButtonWithImageName:(NSString *)imageName andSelector:(SEL)selector
{
    UIImage* buttonImage = [UIImage tallImageNamed:imageName];
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button setAdjustsImageWhenHighlighted:YES];
    [button setShowsTouchWhenHighlighted:YES];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return barButton;
}

-(UIBarButtonItem*)createBarButtonWithImageName:(NSString *)imageName selectedImage:(NSString*)selectedImageName andSelector:(SEL)selector
{
    UIImage* buttonImage = [UIImage tallImageNamed:imageName];
    UIImage* selectedImage = [UIImage tallImageNamed:selectedImageName];
    
    UIButton* button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
    [button setImage:buttonImage forState:UIControlStateNormal];
    [button setImage:selectedImage forState:UIControlStateSelected];
    [button setAdjustsImageWhenHighlighted:YES];
    [button setShowsTouchWhenHighlighted:YES];
    [button addTarget:self action:selector forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem* barButton = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    return barButton;
}

-(void)prepareIPhoneViewController:(UIViewController *)vc leftButtons:(BOOL)left
{
    UIBarButtonItem *helpButton = [self createBarButtonWithImageName:@"help.png" andSelector:@selector(showIPhoneInfoScreen:)];
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"downloadable"]) {
        UIBarButtonItem *downloadButton = [self createBarButtonWithImageName:@"download.png" selectedImage:@"download-white.png" andSelector:@selector(startDownloadingCourse:)];
        vc.navigationItem.rightBarButtonItems = @[helpButton, downloadButton];
    } else {
        vc.navigationItem.rightBarButtonItems = @[helpButton];
    }
    
    if(left) {
        UIBarButtonItem *aboutButton = [self createBarButtonWithImageName:@"infoizdat.png" andSelector:@selector(showIPhoneAboutScreen:)];
        if(self.certificate != nil) {
            UIBarButtonItem *certificateButton = [self createBarButtonWithImageName:@"certificate" andSelector:@selector(showCertificate)];
            vc.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:aboutButton, certificateButton, nil];
        } else {
            vc.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:aboutButton, nil];
        }
    }
}

-(void)showIPhoneInfoScreen:(id)sender
{
    // info screen for iphone 
    ITHelpViewController * helpViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"HelpViewController"];
    helpViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    helpViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self.window.rootViewController presentViewController:helpViewController animated:YES completion:^(void){}];
}

-(void)showIPhoneAboutScreen:(id)sender
{
    // info screen for iphone
    ITAboutViewController * aboutViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"AboutViewController"];
    aboutViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    aboutViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self.window.rootViewController presentViewController:aboutViewController animated:YES completion:^(void){}];
}

-(void)userLogIn
{
    // Create the log in view controller
    logInViewController = [[PFLogInViewController alloc] init];
    [logInViewController setDelegate:self]; // Set ourselves as the delegate
    
    // Create the sign up view controller
    signUpViewController = [[PFSignUpViewController alloc] init];
    [signUpViewController setDelegate:self]; // Set ourselves as the delegate
    NSString *certificate = [self certificate];
    if(certificate != nil && [certificate length] > 0) {
        // we need a real name of user
        signUpViewController.fields = PFSignUpFieldsDefault | PFSignUpFieldsAdditional;
        signUpViewController.signUpView.additionalField.placeholder = NSLocalizedString(@"Full name", @"signup window");
    } else {
        // only standard fields
        signUpViewController.fields = PFSignUpFieldsDefault;
    }
    UIImageView *logo = (UIImageView*)signUpViewController.signUpView.logo;
    [logo setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"logo" ofType:@"png" inDirectory:@"data"]]];
    CGRect r = logo.frame;
    r.origin.x = 0;
    r.size.width = signUpViewController.signUpView.frame.size.width;
    logo.frame = r;
    [logo setContentMode:UIViewContentModeCenter];
    
    // Assign our sign up controller to be displayed from the login controller
    [logInViewController setSignUpController:signUpViewController];
    [logInViewController setFacebookPermissions:[NSArray arrayWithObjects:@"friends_about_me", nil]];
    if(allowAnonymous) {
        [logInViewController setFields: PFLogInFieldsUsernameAndPassword | PFLogInFieldsLogInButton | PFLogInFieldsSignUpButton | PFLogInFieldsPasswordForgotten | PFLogInFieldsDismissButton];
    } else {
        [logInViewController setFields: PFLogInFieldsUsernameAndPassword | PFLogInFieldsLogInButton | PFLogInFieldsSignUpButton | PFLogInFieldsPasswordForgotten];
    }
    UIImageView *logo2 = (UIImageView*)logInViewController.logInView.logo;
    [logo2 setImage:[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"logo" ofType:@"png" inDirectory:@"data"]]];
    r = logo2.frame;
    r.origin.x = 0;
    r.size.width = signUpViewController.signUpView.frame.size.width;
    logo2.frame = r;
    [logo2 setContentMode:UIViewContentModeCenter];
    
    // Present the log in view controller
    [self.window.rootViewController presentViewController:logInViewController animated:YES completion:NULL];
}

-(void)userLogOut
{
    [PFUser logOut];
}

#pragma mark - PFLogInViewControllerDelegate

-(BOOL)logInViewController:(PFLogInViewController *)logInController shouldBeginLogInWithUsername:(NSString *)username password:(NSString *)password
{
    // Check if both fields are completed
    if (username && password && username.length != 0 && password.length != 0) {
        return YES; // Begin login process
    }
    
    [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", @"login error title")
                                message:NSLocalizedString(@"Make sure you fill out all of the information!", @"login error body")
                               delegate:nil
                      cancelButtonTitle:NSLocalizedString(@"Ok", @"login error button")
                      otherButtonTitles:nil] show];
    return NO; // Interrupt login process
}

// Sent to the delegate when a PFUser is logged in.
- (void)logInViewController:(PFLogInViewController *)logInController didLogInUser:(PFUser *)user {
    [logInController dismissViewControllerAnimated:YES completion:^(void){
        [self firstStart:nil];
    }];
}

// Sent to the delegate when the log in attempt fails.
- (void)logInViewController:(PFLogInViewController *)logInController didFailToLogInWithError:(NSError *)error
{
    NSLog(@"Failed to log in: %@", error);
}

// Sent to the delegate when the log in screen is dismissed.
- (void)logInViewControllerDidCancelLogIn:(PFLogInViewController *)logInController
{
    if(allowAnonymous) {
        [logInController dismissViewControllerAnimated:YES completion:^(void){
            [self firstStart:nil];
        }];
    }
}

#pragma mark - PFSignUpViewControllerDelegate

// Sent to the delegate to determine whether the sign up request should be submitted to the server.
- (BOOL)signUpViewController:(PFSignUpViewController *)signUpController shouldBeginSignUp:(NSDictionary *)info {
    BOOL informationComplete = YES;
    
    // loop through all of the submitted data
    for (id key in info) {
        NSString *field = [info objectForKey:key];
        if (!field || field.length == 0) { // check completion
            informationComplete = NO;
            break;
        }
    }
    
    // Display an alert if a field wasn't completed
    if (!informationComplete) {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Missing Information", @"login error title")
                                    message:NSLocalizedString(@"Make sure you fill out all of the information!", @"login error body")
                                   delegate:nil
                          cancelButtonTitle:NSLocalizedString(@"Ok", @"login error button")
                          otherButtonTitles:nil] show];
    }
    
    return informationComplete;
}

// Sent to the delegate when a PFUser is signed up.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didSignUpUser:(PFUser *)user
{
    [user setValue:signUpViewController.signUpView.additionalField.text forKey:@"fullname"];
    [user save];
    // Dismiss the PFSignUpViewController
    [signUpController dismissViewControllerAnimated:YES completion:^(void){
        [logInViewController dismissViewControllerAnimated:YES completion:^(void){
            [self firstStart:nil];
        }];
    }];
}

// Sent to the delegate when the sign up attempt fails.
- (void)signUpViewController:(PFSignUpViewController *)signUpController didFailToSignUpWithError:(NSError *)error
{
    NSLog(@"Failed to sign up: %@", error);
}

// Sent to the delegate when the sign up screen is dismissed.
- (void)signUpViewControllerDidCancelSignUp:(PFSignUpViewController *)signUpController
{
    [signUpController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark -

-(void)makeCertificate
{
    NSString *certFile = self.certificate;
    // is there any certificate?
    if(certFile == nil || [certFile length] <= 0) return;
    if([[PFUser currentUser] valueForKey:@"certificate"] != nil) return;
    [self performSelectorInBackground:@selector(makeCertificateInternal) withObject:nil];
}

-(void)makeCertificateInternal
{
    NSString *text = [[PFUser currentUser] valueForKey:@"fullname"];
    UIImage *image = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:self.certificate ofType:nil inDirectory:@"data"]];
    // point at image center
    CGPoint point = CGPointMake(image.size.width*0.5f, image.size.height*0.5f);
    UIFont *font = [UIFont boldSystemFontOfSize:36];
    // set text to image center
    CGSize ts = [text sizeWithFont:font];
    point.x -= ts.width*0.5f;
    point.y -= ts.height*0.5f;
    UIGraphicsBeginImageContext(image.size);
    [image drawInRect:CGRectMake(0,0,image.size.width,image.size.height)];
    CGRect rect = CGRectMake(point.x, point.y, image.size.width, image.size.height);
    [[UIColor blackColor] set];
    [text drawInRect:CGRectIntegral(rect) withFont:font];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSData *imageData = UIImagePNGRepresentation(newImage);
    PFFile *imageFile = [PFFile fileWithName:@"certificate.png" data:imageData];
    [imageFile save];
    
    [[PFUser currentUser] setObject:imageFile forKey:@"certificate"];
    [[PFUser currentUser] save];
    
    [self showCertificate];
}

-(void)showCertificate
{
    id certificate = [[PFUser currentUser] valueForKey:@"certificate"];
    if(certificate == nil) return;
    // certificate screen for iphone
    ITCertificateViewController * certificateViewController = [self.window.rootViewController.storyboard instantiateViewControllerWithIdentifier:@"CertificateViewController"];
    certificateViewController.modalPresentationStyle = UIModalPresentationFormSheet;
    certificateViewController.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
    [self.window.rootViewController presentViewController:certificateViewController animated:YES completion:^(void){}];
}

-(void)startDownloadingCourse:(id)sender
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"downloadable"]) return;
    BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"Start downloading", @"download confirmation") message:NSLocalizedString(@"Do you want to download all course content?", @"download confirmation")];
    
    [alert setDestructiveButtonWithTitle:NSLocalizedString(@"Cancel", @"cancel downloading") block:nil];
    [alert addButtonWithTitle:NSLocalizedString(@"OK", @"") block:^{
        [self downloadAllContent];
    }];
    [alert show];
}

-(void)downloadAllContent
{
    NSLog(@"download all content");
    NSLog(@"going to download %d remote files", [remoteContent count]);
    for (NSString *url in [remoteContent allKeys]) {
        NSLog(@"> %@ used in %d contents", url, [[remoteContent valueForKey:url] count]);
    }
    if(nil == queue) {
        queue = [ASINetworkQueue queue];
        [queue setRequestDidFinishSelector:@selector(downloadComplete:)];
        [queue setRequestDidFailSelector:@selector(downloadFailed:)];
        [queue setQueueDidFinishSelector:@selector(allDownloadCompleted:)];
        [queue setDelegate:self];
    }
    dlCompleted = 0;
    dlFailed = 0;
    for (NSString *u in [remoteContent allKeys]) {
        ASIHTTPRequest *request;
        NSURL *url = [NSURL URLWithString:u];
        if([[[url pathExtension] lowercaseString] hasPrefix:@"htm"]) {
            request = [ASIWebPageRequest requestWithURL:url];
            [(ASIWebPageRequest*)request setUrlReplacementMode:ASIReplaceExternalResourcesWithLocalURLs];
        } else {
            request = [ASIHTTPRequest requestWithURL:url];
        }
        NSString *tempDir = [NSString stringWithFormat:@"content-%@", [[NSProcessInfo processInfo] globallyUniqueString]];
        NSString *path = [[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:tempDir];
        [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
        [request setDownloadDestinationPath:[path stringByAppendingPathComponent:[url lastPathComponent]]];
        [request setUserInfo:@{@"contents": [remoteContent valueForKey:u]}];
        [queue addOperation:request];
        dlCompleted --;
    }
    [queue go];
}

-(void)downloadComplete:(ASIHTTPRequest*)request
{
    NSString *path = [request downloadDestinationPath];
    NSLog(@"completed: %@", [request url]);
    NSLog(@"file: %@", path);
    NSURL *url = [NSURL fileURLWithPath:path];
    NSError *err = nil;
    if(![url setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:&err]) {
        NSLog(@"Exclude %@ from backup. Error: %@", path, err);
    } else {
        NSLog(@"Exclude %@ from backup successfully", path);
    }
    NSArray *contents = [[request userInfo] valueForKey:@"contents"];
    for (NSManagedObject *o in contents) {
        [o setValue:path forKey:@"file"];
    }
    dlCompleted ++;
}

-(void)downloadFailed:(ASIHTTPRequest*)request
{
    NSLog(@"failed: %@", [request url]);
    dlFailed ++;
}

-(void)allDownloadCompleted:(ASINetworkQueue*)queue
{
    if(!dlFailed && dlCompleted >= 0) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"downloadable"];
        BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"Download complete", @"download complete message") message:NSLocalizedString(@"All files were downloaded successfully", @"download complete message")];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"") block:^{
            NSLog(@"ok");
        }];
        [alert show];
    } else {
        int files = MAX(dlFailed, -dlCompleted);
        NSString *message = [NSString stringWithFormat:@"%d %@", files, NSLocalizedString(@"files weren't downloaded", @"download error")];
        BlockAlertView *alert = [BlockAlertView alertWithTitle:NSLocalizedString(@"Error", @"download error") message:message];
        [alert addButtonWithTitle:NSLocalizedString(@"OK", @"") block:^{
            NSLog(@"ok");
        }];
        [alert show];
    }
}

@end

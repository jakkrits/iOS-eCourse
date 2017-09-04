//
//  AppDelegate.h
//  it2
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "ColorSwitcher.h"
#import <Parse/Parse.h>

#define nCHAPTER_CHANGED @"nCHAPTER_CHANGED"
#define nCONTENT_CHANGED @"nCONTENT_CHANGED"
#define nPROGRESS_CHANGED @"nPROGRESS_CHANGED"
#define nCHAPTER_FINISHED @"nCHAPTER_FINISHED"
#define nFIRST_START @"nFIRST_START"
#define nSHOW_HELP @"nSHOW_HELP"
#define nHIDE_ADS @"nHIDE_ADS"
#define nPURCHASE_COMPLETED @"nPURCHASE_COMPLETED"

#define IsIPad (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)

// enable AdMob banners
extern BOOL AdMob;

// should we unlock next chapter after completing the previous one?
extern BOOL progressUnlock;

// should we force user to log in?
extern BOOL loginAtStartUp;

void uncaughtExceptionHandler(NSException *exception);

@interface AppDelegate : UIResponder <UIApplicationDelegate, PFUserAuthenticationDelegate> {
    NSDictionary *infoproduct;
    NSTimer *moreAppsTimer;
}

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) ColorSwitcher *colorSwitcher;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (nonatomic, weak) NSManagedObject* curChapter;
@property (nonatomic, weak) NSManagedObject* curContent;

+ (AppDelegate*)instance;
-(void)customizeiPadTheme;
-(void)customizeiPhoneTheme;
-(void)iPadInit;
-(void)configureiPhoneTabBar;
-(void)configureTabBarItemWithImageName:(NSString*)imageName andText:(NSString *)itemText forViewController:(UIViewController *)viewController;

-(void)saveContext;
-(NSURL *)applicationDocumentsDirectory;
-(NSDictionary*)content;
-(NSString*)title;
-(NSString*)subtitle;
-(float)defaultMoreAppsTimer;
-(NSString*)moreAppsURL;
-(NSString*)parseAppId;
-(NSString*)parseClientKey;
-(NSString*)adMobId;
-(NSString*)certificate;
-(NSString*)AppPurchase;
-(BOOL)unlockNextChapter;
-(BOOL)allowSaveVideoToCameraRoll;

+(float)chapterProgress:(id)object;
+(void)setProgress:(CGFloat)progress forContent:(NSManagedObject*)content;
+(void)storeProgress:(CGFloat)progress forContent:(NSManagedObject*)content;
-(void)checkOverallProgress;

-(IBAction) inAppPurchase:(id)sender;
-(IBAction) inAppRestore:(id)sender;

-(void) prepareIPhoneViewController:(UIViewController*)vc leftButtons:(BOOL)left;
-(IBAction)showIPhoneInfoScreen:(id)sender;
-(IBAction)showIPhoneAboutScreen:(id)sender;
-(void)userLogIn;
-(void)userLogOut;
-(void)makeCertificate;
-(void)showCertificate;

-(void)downloadAllContent;

@end

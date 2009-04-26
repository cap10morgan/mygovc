//
//  myGovAppDelegate.h
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MGTwitterEngine.h"

@class CommunityDataManager;
@class BillsDataManager;
@class CongressDataManager;
@class SpendingDataManager;

@interface myGovAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, MGTwitterEngineDelegate> 
{
    UIWindow *m_window;
    UITabBarController *m_tabBarController;

@private
	NSOperationQueue *m_operationQueue;
	NSMutableDictionary *m_urlHandler;
	
	id m_twitterNotifyTarget; // sends a "twitterOpFinished:(BOOL)successfully" messsage 
}

@property (nonatomic, retain) IBOutlet UIWindow *m_window;
@property (nonatomic, retain) IBOutlet UITabBarController *m_tabBarController;

@property (nonatomic, retain) NSOperationQueue *m_operationQueue;

+ (myGovAppDelegate *)sharedAppDelegate;
+ (NSString *)sharedAppCacheDir;

+ (CommunityDataManager *)sharedCommunityData;
+ (BillsDataManager *)sharedBillsData;
+ (void)replaceSharedBillsData:(BillsDataManager *)newData;
+ (CongressDataManager *)sharedCongressData;
+ (SpendingDataManager *)sharedSpendingData;

+ (MGTwitterEngine *)sharedTwitterEngine;

- (UIView *)topView;
- (UIViewController *)topViewController;

- (void)setTwitterNotifyTarget:(id)target;

@end

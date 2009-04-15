//
//  myGovAppDelegate.h
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BillsDataManager;
@class CongressDataManager;
@class SpendingDataManager;

@interface myGovAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> 
{
    UIWindow *m_window;
    UITabBarController *m_tabBarController;

@private
	NSOperationQueue *m_operationQueue;
	NSMutableDictionary *m_urlHandler;
}

@property (nonatomic, retain) IBOutlet UIWindow *m_window;
@property (nonatomic, retain) IBOutlet UITabBarController *m_tabBarController;

@property (nonatomic, retain) NSOperationQueue *m_operationQueue;

+ (myGovAppDelegate *)sharedAppDelegate;
+ (NSString *)sharedAppCacheDir;

+ (BillsDataManager *)sharedBillsData;
+ (CongressDataManager *)sharedCongressData;
+ (SpendingDataManager *)sharedSpendingData;

@end

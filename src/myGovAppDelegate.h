/*
 File: myGovAppDelegate.h
 Project: myGovernment
 Org: iPhoneFLOSS
 
 Copyright (C) 2009 Jeremy C. Andrus <jeremyandrus@iphonefloss.com>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 $Id: $
 */

#import <UIKit/UIKit.h>
#import "MGTwitterEngine.h"
#import "myGovCompileOptions.h"

@class MyGovUserData;
@class CommunityDataManager;
@class BillsDataManager;
@class CongressDataManager;
@class SpendingDataManager;

@interface myGovAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, MGTwitterEngineDelegate> 
{
	IBOutlet UIWindow *m_window;
	IBOutlet UITabBarController *m_tabBarController;
	IBOutlet UITabBar *m_tabBar;
	
@private
	NSOperationQueue *m_operationQueue;
	NSMutableDictionary *m_urlHandler;

	id m_twitterNotifyTarget; // sends a "twitterOpFinished:(BOOL)successfully" messsage 
}

@property (retain) UIWindow *m_window;
@property (retain) UITabBarController *m_tabBarController;
@property (retain) UITabBar *m_tabBar;

@property (retain) NSOperationQueue *m_operationQueue;

+ (myGovAppDelegate *)sharedAppDelegate;
+ (NSString *)sharedAppCacheDir;
+ (UIViewController *)rootViewController;
+ (NSString *)md5hash:(NSString *)str;

+ (BOOL)canMakePhoneCalls;

+ (CGFloat)OSVersion;

+ (BOOL)networkIsAvailable:(BOOL)andWillBeBusy;
+ (void)networkNoLongerInUse;

+ (BOOL)isDeviceInPortrait;

+ (MyGovUserData *)sharedUserData;

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

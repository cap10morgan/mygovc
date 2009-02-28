//
//  myGovAppDelegate.h
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface myGovAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate> 
{
    UIWindow *m_window;
    UITabBarController *m_tabBarController;
}

@property (nonatomic, retain) IBOutlet UIWindow *m_window;
@property (nonatomic, retain) IBOutlet UITabBarController *m_tabBarController;

@end

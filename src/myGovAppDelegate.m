//
//  myGovAppDelegate.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "myGovAppDelegate.h"


@implementation myGovAppDelegate

@synthesize m_window;
@synthesize m_tabBarController;


- (void)applicationDidFinishLaunching:(UIApplication *)application 
{    
    // Add the tab bar controller's current view as a subview of the window
    [m_window addSubview:m_tabBarController.view];
}


/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController 
{
}
*/

/*
// Optional UITabBarControllerDelegate method
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed 
{
}
*/


- (void)dealloc 
{
    [m_tabBarController release];
    [m_window release];
    [super dealloc];
}

@end


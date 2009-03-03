//
//  myGovAppDelegate.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "myGovAppDelegate.h"


@implementation myGovAppDelegate

static myGovAppDelegate *s_myGovApp = NULL;

@synthesize m_window;
@synthesize m_tabBarController;
@synthesize m_operationQueue;


// Initialize the singleton instance if needed and return
+ (myGovAppDelegate *)sharedAppDelegate
{
	if ( !s_myGovApp )
		s_myGovApp = [[myGovAppDelegate alloc] init];
	
	return s_myGovApp;
}


- (id)init 
{
	if ( !s_myGovApp )
	{
		s_myGovApp = [super init];
	}
	
	m_operationQueue = [[NSOperationQueue alloc] init];
	
	return s_myGovApp;
}


- (void)dealloc 
{
	// shut any running operation down nicely
	// (they don't have much time though...)
	[m_operationQueue cancelAllOperations];
	
    [m_tabBarController release];
    [m_window release];
	
	[m_operationQueue release];
	
    [super dealloc];
}


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


@end


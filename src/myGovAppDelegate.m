//
//  myGovAppDelegate.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "myGovAppDelegate.h"
#import "BillsDataManager.h"
#import "CongressDataManager.h"
#import "SpendingDataManager.h"

#import <objc/runtime.h>

@implementation myGovAppDelegate

static myGovAppDelegate *s_myGovApp = NULL;
static BillsDataManager *s_myBillsData = NULL;
static CongressDataManager *s_myCongressData = NULL;
static SpendingDataManager *s_mySpendingData = NULL;


@synthesize m_window;
@synthesize m_tabBarController;
@synthesize m_operationQueue;


// Initialize the singleton instance if needed and return
+ (myGovAppDelegate *)sharedAppDelegate
{
	if ( !s_myGovApp ) s_myGovApp = [[myGovAppDelegate alloc] init];
	return s_myGovApp;
}

+ (NSString *)sharedAppCacheDir
{
	NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *path = [cachePaths objectAtIndex:0];
	if ( path )
	{
		return [path stringByAppendingPathComponent:@"myGovernment"];
	}
	else
	{
		return path;
	}
}


+ (BillsDataManager *)sharedBillsData
{
	if ( !s_myBillsData ) s_myBillsData = [[BillsDataManager alloc] init];
	return s_myBillsData;
}


+ (CongressDataManager *)sharedCongressData
{
	if ( !s_myCongressData ) s_myCongressData = [[CongressDataManager alloc] initWithNotifyTarget:nil andSelector:nil];
	return s_myCongressData;
}


+ (SpendingDataManager *)sharedSpendingData
{
	if ( !s_mySpendingData ) s_mySpendingData = [[SpendingDataManager alloc] init];
	return s_mySpendingData;
}


- (id)init 
{
	if ( !s_myGovApp )
	{
		s_myGovApp = [super init];
	}
	
	// this needs to be initialized before the congress data!
	m_operationQueue = [[NSOperationQueue alloc] init];
	
	m_urlHandler = [[NSMutableDictionary alloc] initWithCapacity:8];
	
	if ( !s_myCongressData )
	{
		NSLog( @"Initializing Congress Data..." );
		s_myCongressData = [[CongressDataManager alloc] initWithNotifyTarget:nil andSelector:nil];
	}
	
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
	[s_myCongressData release];
	
	[m_urlHandler release];
	
    [super dealloc];
}


- (void)applicationDidFinishLaunching:(UIApplication *)application 
{    
	// run through all of the view controllers managed by the tab bar
	// and setup our dictionary of view controllers which can handle URLs
	NSArray *tabViews = m_tabBarController.viewControllers;
	NSEnumerator *tabsEnum = [tabViews objectEnumerator];
	id tab;
	while ( tab = [tabsEnum nextObject] )
	{
		if ( [tab respondsToSelector:@selector(topViewController)] )
		{
			UINavigationController *navCtrl = (UINavigationController *)tab;
			if ( [navCtrl.topViewController respondsToSelector:@selector(areaName)] )
			{
				[m_urlHandler setValue:tab forKey:[navCtrl.topViewController performSelector:@selector(areaName)]];
			}
		}
		else if ( [tab respondsToSelector:@selector(areaName)] )
		{
			[m_urlHandler setValue:tab forKey:[tab performSelector:@selector(areaName)]];
		}
		
	}
	
    // Add the tab bar controller's current view as a subview of the window
    [m_window addSubview:m_tabBarController.view];
	
	NSString *appURLStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"mygov_last_url"];
	if ( nil != appURLStr )
	{
		// make sure it's absolute!
		if ( NSOrderedSame != [appURLStr compare:@"mygov://" options:NSCaseInsensitiveSearch range:(NSRange){0,8}] )
		{
			appURLStr = [NSString stringWithFormat:@"mygov://%@",appURLStr];
		}
		appURLStr = [appURLStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		NSURL *appURL = [NSURL URLWithString:appURLStr];
		[self application:application handleOpenURL:appURL];
	}
}


- (void)applicationWillTerminate:(UIApplication *)application
{
	NSString *appURL = nil;
	NSString *area = nil;
	NSString *areaParms = nil;
	
	id currentView = m_tabBarController.selectedViewController;
	if ( [currentView respondsToSelector:@selector(viewControllers)] )
	{
		NSArray *views = [currentView performSelector:@selector(viewControllers)];
		if ( [views count] > 0 )
		{
			// the root will be the first view controller in the array
			// (that's the one we want)
			currentView = [views objectAtIndex:0]; 
		}
	}
	
	if ( [currentView respondsToSelector:@selector(areaName)] )
	{
		area = [currentView performSelector:@selector(areaName)];
	}
	if ( [currentView respondsToSelector:@selector(getURLStateParms)] )
	{
		areaParms = [currentView performSelector:@selector(getURLStateParms)];
	}
	
	if ( nil != area )
	{
		// save the state!
		appURL = [NSString stringWithFormat:@"mygov://%@/%@",area,(nil != areaParms ? areaParms : @"")];
		appURL = [appURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		[[NSUserDefaults standardUserDefaults] setObject:appURL forKey:@"mygov_last_url"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
}


// 
// Handle URLs with the following format:
// 
//		mygov://area/parameters_for_area
// 
- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	if ( !url ) return NO;
	
	BOOL handled = NO;
	NSString *urlStr = [url absoluteString];
	NSArray *urlArray = [urlStr componentsSeparatedByString:@"/"];
	NSString *area = nil;
	NSString *areaParms = nil;
	
	if ( [urlArray count] > 2 )
	{
		area = [urlArray objectAtIndex:2];
		if ( [urlArray count] > 3 && [[urlArray objectAtIndex:3] length] > 0 )
		{
			// get any parameters
			NSRange areaRange = [urlStr rangeOfString:area];
			NSInteger parmIdx = areaRange.location + areaRange.length + 1;
			areaParms = [urlStr substringFromIndex:parmIdx];
		}
	}
	
	UIViewController *areaView = (UIViewController *)[m_urlHandler objectForKey:area];
	if ( nil != areaView )
	{
		handled = YES;
		m_tabBarController.selectedViewController = areaView;
		if ( [areaView respondsToSelector:@selector(topViewController)] )
		{
			NSArray *views = [areaView performSelector:@selector(viewControllers)];
			if ( [views count] > 0 )
			{
				// the root will be the first view controller in the array
				// (that's the one we want)
				areaView = [views objectAtIndex:0]; 
			}
		}
		
		if ( [areaView respondsToSelector:@selector(handleURLParms:)] )
		{
			[areaView performSelector:@selector(handleURLParms:) withObject:areaParms];
		}
	}
	
	return handled;
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


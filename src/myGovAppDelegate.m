//
//  myGovAppDelegate.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "myGovAppDelegate.h"
#import "CommunityDataManager.h"
#import "BillsDataManager.h"
#import "CongressDataManager.h"
#import "SpendingDataManager.h"
#import "MGTwitterEngine.h"
#import "MyGovUserData.h"
#import <objc/runtime.h>

@implementation myGovAppDelegate

static myGovAppDelegate *s_myGovApp = NULL;

static MyGovUserData *s_myGovUserData = NULL;
static CommunityDataManager *s_myCommunityData = NULL;
static BillsDataManager *s_myBillsData = NULL;
static CongressDataManager *s_myCongressData = NULL;
static SpendingDataManager *s_mySpendingData = NULL;
static MGTwitterEngine *s_myTwitterEngine = NULL;

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


+ (MyGovUserData *)sharedUserData
{
	if ( !s_myGovUserData ) s_myGovUserData = [[MyGovUserData alloc] init];
	return s_myGovUserData;
}


+ (CommunityDataManager *)sharedCommunityData
{
	if ( !s_myCommunityData ) s_myCommunityData = [[CommunityDataManager alloc] init];
	return s_myCommunityData;
}


+ (BillsDataManager *)sharedBillsData
{
	if ( !s_myBillsData ) s_myBillsData = [[BillsDataManager alloc] init];
	return s_myBillsData;
}


+ (void)replaceSharedBillsData:(BillsDataManager *)newData
{
	[s_myBillsData release];
	s_myBillsData = [newData retain];
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


+ (MGTwitterEngine *)sharedTwitterEngine
{
	if ( !s_myTwitterEngine ) s_myTwitterEngine = [[MGTwitterEngine alloc] initWithDelegate:[myGovAppDelegate sharedAppDelegate]];
	return s_myTwitterEngine;
}


- (UIView *)topView
{
	return (UIView *)m_tabBarController.view;
}


- (UIViewController *)topViewController
{
	return (UIViewController *)m_tabBarController;
}


- (void)setTwitterNotifyTarget:(id)target
{
	[m_twitterNotifyTarget release];
	m_twitterNotifyTarget = [target retain];
}


- (id)init 
{
	if ( self = [super init] )
	{
		if ( !s_myGovApp )
		{
			s_myGovApp = self;
		}
		
		// this needs to be initialized before the congress data!
		m_operationQueue = [[NSOperationQueue alloc] init];
		[m_operationQueue setMaxConcurrentOperationCount:10];
		
		m_urlHandler = [[NSMutableDictionary alloc] initWithCapacity:8];
		
		if ( !s_myCongressData )
		{
			//NSLog( @"Initializing Congress Data..." );
			s_myCongressData = [[CongressDataManager alloc] initWithNotifyTarget:nil andSelector:nil];
		}
	}
	return self;
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
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// 
	// Start loading the congress and bill data
	// 
	if ( [[myGovAppDelegate sharedCongressData] isDataAvailable] )
	{
		NSLog( @"Congress data loaded: wow that was fast!" );
	}
	
	// start the bill data download (waits for congress data)
	[[myGovAppDelegate sharedBillsData] loadData];
	
	// purge old community data
	[[myGovAppDelegate sharedCommunityData] purgeOldItemsFromCache:YES];
	
	
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
	
	// 
	// wait for the congress data to load..
	while ( ![[myGovAppDelegate sharedCongressData] isDataAvailable] )
	{
		[NSThread sleepForTimeInterval:0.1f];
		if ( ![[myGovAppDelegate sharedCongressData] isAnyDataCached] )
		{
			// if we're downloading data, it could be a while so
			// we should probably indicate some progress and let the user 
			// interact with our UI a little ;-)
			break;
		}
	}
	
	//
	// Go back to the last application page viewed
	// 
	NSString *appURLStr = [[NSUserDefaults standardUserDefaults] objectForKey:@"mygov_last_url"];
	if ( nil != appURLStr )
	{
		// make sure it's absolute!
		if ( NSOrderedSame != [appURLStr compare:@"mygov://" options:NSCaseInsensitiveSearch range:(NSRange){0,8}] )
		{
			appURLStr = [NSString stringWithFormat:@"mygov://%@",appURLStr];
		}
		appURLStr = [appURLStr stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding];
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
		appURL = [appURL stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding];
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
	
	if ( [area isEqualToString:@"app"] )
	{
		// no area to view
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


#pragma mark MGTwitterEngineDelegate methods


- (void)requestSucceeded:(NSString *)connectionIdentifier
{
    //NSLog(@"myGov:MGTwitter: Request succeeded for connectionIdentifier = %@", connectionIdentifier);
	if ( nil != m_twitterNotifyTarget && [m_twitterNotifyTarget respondsToSelector:@selector(twitterOpFinished:)] )
	{
		NSString *yes = @"YES";
		[m_twitterNotifyTarget performSelector:@selector(twitterOpFinished:) withObject:yes];
	}
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error
{
    NSLog(@"myGov:MGTwitter: Request failed for connectionIdentifier = %@, error = %@ (%@)", 
          connectionIdentifier, 
          [error localizedDescription], 
          [error userInfo]);
	if ( nil != m_twitterNotifyTarget && [m_twitterNotifyTarget respondsToSelector:@selector(twitterOpFinished:)] )
	{
		NSString *no = [NSString stringWithFormat:@"NO %@",[error localizedDescription]];
		[m_twitterNotifyTarget performSelector:@selector(twitterOpFinished:) withObject:no];
	}
}


- (void)statusesReceived:(NSArray *)statuses forRequest:(NSString *)connectionIdentifier
{
	//NSLog(@"myGov:MGTwitter: Got statuses for %@:\r%@", connectionIdentifier, statuses);
}


- (void)directMessagesReceived:(NSArray *)messages forRequest:(NSString *)connectionIdentifier
{
	//NSLog(@"myGov:MGTwitter: Got direct messages for %@:\r%@", connectionIdentifier, messages);
}


- (void)userInfoReceived:(NSArray *)userInfo forRequest:(NSString *)connectionIdentifier
{
	//NSLog(@"myGov:MGTwitter: Got user info for %@:\r%@", connectionIdentifier, userInfo);
}


- (void)miscInfoReceived:(NSArray *)miscInfo forRequest:(NSString *)connectionIdentifier
{
	//NSLog(@"myGov:MGTwitter: Got misc info for %@:\r%@", connectionIdentifier, miscInfo);
}

- (void)searchResultsReceived:(NSArray *)searchResults forRequest:(NSString *)connectionIdentifier
{
	//NSLog(@"myGov:MGTwitter: Got search results for %@:\r%@", connectionIdentifier, searchResults);
}


- (void)imageReceived:(UIImage *)image forRequest:(NSString *)connectionIdentifier
{
	//NSLog(@"myGov:MGTwitter: Got an image for %@: %@", connectionIdentifier, image);
}

- (void)connectionFinished
{
	//NSLog(@"myGov:MGTwitter: Connection finished.");
}


@end


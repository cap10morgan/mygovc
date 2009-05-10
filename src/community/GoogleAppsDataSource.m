//
//  GoogleAppsDataSource.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import "myGovAppDelegate.h"

#import "GoogleAppsDataSource.h"
#import "DataProviders.h"
#import "MyGovUserData.h"

@implementation GoogleAppsDataSource

static NSString *kGAE_UsernameCookie = @"GAUSR";
//static NSString *kGAE_LSIDCookie = @"LSID";


- (id)init
{
	if ( self = [super init] )
	{
		m_loginURL = nil;
	}
	return self;
}


- (NSURL *)externalLoginURL
{
	if ( nil == m_loginURL )
	{
		[self downloadItemsOfType:eCommunity_Chatter notOlderThan:[NSDate distantFuture] withDelegate:nil];
	}
	
	return m_loginURL;
}


- (BOOL)validateUsername:(NSString *)username 
			 andPassword:(NSString *)password
			withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// grab the stash of global cookies
	NSHTTPCookieStorage *cookiePile = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	// grab the GAE cookie set
	NSArray *gaeCookies = [cookiePile cookiesForURL:[NSURL URLWithString:@"www.google.com"]];
	
	// look through the GAE cookies for "GAUSR" and "LSID"
	NSEnumerator *cEnum = [gaeCookies objectEnumerator];
	NSHTTPCookie *cookie;
	while ( cookie = [cEnum nextObject] )
	{
		if ( [[cookie name] isEqualToString:kGAE_UsernameCookie] )
		{
			if ( [[cookie value] isEqualToString:username] )
			{
				// we have a GAUSR cookie whose content matches the username
				// passed in - we're valid!
				return TRUE;
			}
			else
			{
				// we have a GAUSR cookie, but not from the username
				// passed into the app - delete this cookie and
				// attempt to log the user into the GAE
				[cookiePile deleteCookie:cookie];
				
				// XXX - bring up the GAE website!
			}
		}
	}
	
	return FALSE;
}


- (BOOL)addNewUser:(MyGovUser *)newUser
	  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// This doesn't happen with the GAE implementation
	return FALSE;
}


- (BOOL)downloadItemsOfType:(CommunityItemType)type 
			   notOlderThan:(NSDate *)startDate 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	NSString *gaeURLBase = [DataProviders GAE_DownloadURLFor:type];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	NSString *urlAddStr = [NSString stringWithFormat:@"?not_older_than=%@",[dateFormatter stringFromDate:startDate]];
	NSURL *gaeURL = [NSURL URLWithString:[gaeURLBase stringByAppendingString:urlAddStr]];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:gaeURL];
	[theRequest setHTTPMethod:@"GET"];
	[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
	
	NSURLResponse *theResponse = nil;
	NSError *err = nil;
	NSData *retVal = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&err];
	
	[theRequest release];
	
	if ( nil == retVal ) return FALSE;
	
	NSString *errString = nil;
	NSPropertyListFormat plistFmt;
	NSDictionary *plistDict = [NSPropertyListSerialization propertyListFromData:retVal 
															   mutabilityOption:NSPropertyListImmutable 
																		 format:&plistFmt 
															   errorDescription:&errString];
	
	if ( [plistDict count] < 1 )
	{
		return FALSE;
	}
	
	// get the Login URL
	NSDictionary *google_urls = [plistDict objectForKey:[DataProviders GAE_GoogleURLsDictKey]];
	if ( nil == google_urls ) return FALSE;
	
	m_loginURL = [NSURL URLWithString:[google_urls objectForKey:[DataProviders GAE_GoogleLoginURLDictKey]]];
	
	// 
	// Now run through all the items!
	// 
	NSDictionary *itemsDict = [plistDict objectForKey:[DataProviders GAE_ItemsDictKey]];
	if ( nil == itemsDict ) return FALSE;
	
	// store all known userIDs (usernames)
	NSMutableDictionary *idDict = [[NSMutableDictionary alloc] init];
	
	// run through each array item, create a CommunityItem object
	// and let our delegate know about it!
	NSEnumerator *plEnum = [itemsDict objectEnumerator];
	NSDictionary *objDict;
	while ( objDict = [plEnum nextObject] )
	{
		CommunityItem *item = [[[CommunityItem alloc] initFromPlistDictionary:objDict] autorelease];
		if ( nil != item )
		{
			item.m_type = type;
			[delegateOrNil communityDataSource:self newCommunityItemArrived:item];
		}
		
		// XXX - grab item comments!
		
		// collect all unique usernames 
		NSNumber *dummyArg = [NSNumber numberWithInt:1];
		[idDict setValue:dummyArg forKey:item.m_creator];
	}
	
	// run through the idDict and make sure
	// our on-device usercache is up-to-date
	NSEnumerator *idEnum = [idDict keyEnumerator];
	NSString *username;
	while ( username = [idEnum nextObject] )
	{
		if ( ![[myGovAppDelegate sharedUserData] usernameExistsInCache:username] )
		{
			// XXX - query for more info!
			
			// create a new MyGovUser object and pass it up to our delegate
			MyGovUser *user = [[MyGovUser alloc] init];
			user.m_username = username;
			
			[delegateOrNil communityDataSource:self userDataArrived:user];
		}
	}
	
	return TRUE;
}


- (BOOL)updateItemOfType:(CommunityItemType)type 
			  withItemID:(NSInteger)itemID 
			 andDelegate:(id<CommunityDataSourceDelegate>)delegatOrNil
{
	// XXX - this needs to be filled in!
	return FALSE;
}


- (BOOL)submitCommunityItem:(CommunityItem *)item 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// XXX - this needs to be filled in!
	return FALSE;
}


- (BOOL)submitCommunityComment:(CommunityComment *)comment 
				  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// XXX - this needs to be filled in!
	return FALSE;
}


- (BOOL)searchForItemsWithType:(CommunityItemType)type 
			  usingQueryString:(NSString *)query 
				  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	return FALSE;
}


- (BOOL)searchForItemsWithType:(CommunityItemType)type 
						nearBy:(CLLocation *)location 
				  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	return FALSE;
}

@end

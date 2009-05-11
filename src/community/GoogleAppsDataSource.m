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

@interface GoogleAppsDataSource (private)
	- (BOOL)doUserAuthFor:(NSString *)username 
			 withPassword:(NSString *)password;
	- (NSURLRequest *)shapeLoginURL:(NSString *)url;
@end



@implementation GoogleAppsDataSource

static NSString *kGAE_AuthCookie = @"ACSID";
//static NSString *kGAE_LSIDCookie = @"LSID";


- (id)init
{
	if ( self = [super init] )
	{
		m_loginURLRequest = nil;
		
		// 
		// Delete any AUTH cookie for mygov:
		// 
		//   This is a HACK!!
		// 
		NSHTTPCookieStorage *cookiePile = [NSHTTPCookieStorage sharedHTTPCookieStorage];
		NSArray *mygovCookies = [cookiePile cookiesForURL:[NSURL URLWithString:@"http://mygov-mobile.appspot.com"]];
		NSEnumerator *cEnum = [mygovCookies objectEnumerator];
		NSHTTPCookie *cookie;
		while ( cookie = [cEnum nextObject] )
		{
			NSString *cookieName = [cookie name];
			if ( [cookieName isEqualToString:kGAE_AuthCookie] )
			{
				[cookiePile deleteCookie:cookie];
			}
		}
	}
	return self;
}


- (NSURLRequest *)externalLoginURLRequest
{
	if ( nil == m_loginURLRequest )
	{
		[self downloadItemsOfType:eCommunity_Chatter notOlderThan:[NSDate distantFuture] withDelegate:nil];
	}
	
	return m_loginURLRequest;
}


- (BOOL)validateUsername:(NSString *)username 
			 andPassword:(NSString *)password
			withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	if ( nil == username )
	{
		username = [[NSUserDefaults standardUserDefaults] objectForKey:@"gae_username"];
	}
	if ( nil == password )
	{
		password = [[NSUserDefaults standardUserDefaults] objectForKey:@"gae_password"];
	}
	
	// grab the stash of global cookies
	NSHTTPCookieStorage *cookiePile = [NSHTTPCookieStorage sharedHTTPCookieStorage];
	
	// grab the GAE cookie set
	NSArray *mygovCookies = [cookiePile cookiesForURL:[NSURL URLWithString:@"http://mygov-mobile.appspot.com"]];
	
	// look through the GAE cookies for "GAUSR" and "LSID"
	NSEnumerator *cEnum = [mygovCookies objectEnumerator];
	NSHTTPCookie *cookie;
	while ( cookie = [cEnum nextObject] )
	{
		NSString *cookieName = [cookie name];
		if ( [cookieName isEqualToString:kGAE_AuthCookie] )
		{
			if ( [cookie isSessionOnly] ) break;
			NSDate *cookieExpires = [cookie expiresDate];
			if ( NSOrderedDescending == [cookieExpires compare:[NSDate date]] )
			{
				// we have a valid session cookie - let's call us logged in :-)
				if ( nil != username )
				{
					// NOTE: this isn't necessarily true, but should be OK for our purposes
					//       becuase I manually remove the cookie when the app starts... 
					//       a bit of HACK, but it works for now...
					[delegateOrNil communityDataSource:self userAuthenticated:username];
				}
				return TRUE;
			}
		}
	}
	
	// no cookies: try regular user auth!
	if ( nil != username && nil != password )
	{
		BOOL success = [self doUserAuthFor:username withPassword:password];
		if ( success )
		{
			if ( nil != username )
			{
				[delegateOrNil communityDataSource:self userAuthenticated:username];
			}
			
		}
		return success;
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
	NSString *urlAddStr = [NSString stringWithFormat:@"?continue_url=mygov://auth/&not_older_than=%@",[dateFormatter stringFromDate:startDate]];
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
	
	// get the Login URL (for what it's worth...)
	NSDictionary *google_urls = [plistDict objectForKey:[DataProviders GAE_GoogleURLsDictKey]];
	if ( nil == google_urls ) return FALSE;
	
	NSString *loginURLStr = [google_urls objectForKey:[DataProviders GAE_GoogleLoginURLDictKey]];
	// make sure it's the login URL, not the logout URL!
	NSString *loginURLTitle = [google_urls objectForKey:[DataProviders GAE_GoogleURLTitleDictKey]];
	if ( [loginURLTitle isEqualToString:[DataProviders GAE_GoogleLoginURLTitle]] )
	{
		m_loginURLRequest = [self shapeLoginURL:loginURLStr];
	}
	
	 
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
	// create an NSURLRequest object from the community item
	// to perform a POST-style HTTP request
	NSURL *gaeURL = [NSURL URLWithString:[DataProviders GAE_CommunityItemPOSTURLFor:item.m_type]];
	
	NSString *itemStr = [DataProviders postStringFromDictionary:[item writeItemToPlistDictionary]];
	NSData *itemAsPostData = [NSData dataWithBytes:[itemStr UTF8String] length:[itemStr length]];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:gaeURL];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody:itemAsPostData];
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
	
	NSURLResponse *theResponse = nil;
	NSError *err = nil;
	NSData *retVal = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&err];
	NSString *response = [[[NSString alloc] initWithData:retVal encoding:NSMacOSRomanStringEncoding] autorelease];
	
	[theRequest release];
	
	// check string response to indicate success / failure
	return TRUE; //[self validResponse:response];
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


#pragma mark GoogleAppsDataSource Private


- (BOOL)doUserAuthFor:(NSString *)username 
		 withPassword:(NSString *)password
{
	// 
	// Code originally taken from:
	// http://stackoverflow.com/questions/471898/google-app-engine-with-clientlogin-interface-for-objective-c
	// 
	
	//create request
	NSString* content = [NSString stringWithFormat:@"accountType=HOSTED_OR_GOOGLE&Email=%@&Passwd=%@&service=ah&source=mygov-mobile", username, password];
	NSURL* authUrl = [NSURL URLWithString:@"https://www.google.com/accounts/ClientLogin"];
	NSMutableURLRequest* authRequest = [[[NSMutableURLRequest alloc] initWithURL:authUrl] autorelease];
	[authRequest setHTTPMethod:@"POST"];
	[authRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-type"];
	[authRequest setHTTPBody:[content dataUsingEncoding:NSASCIIStringEncoding]];
	
	NSHTTPURLResponse* authResponse;
	NSError* authError;
	NSData * authData = [NSURLConnection sendSynchronousRequest:authRequest returningResponse:&authResponse error:&authError];      
	
	NSString *authResponseBody = [[[NSString alloc] initWithData:authData encoding:NSASCIIStringEncoding] autorelease];
	
	//loop through response body which is key=value pairs, seperated by \n. The code below is not optimal and certainly error prone. 
	NSArray *lines = [authResponseBody componentsSeparatedByString:@"\n"];
	NSMutableDictionary* token = [NSMutableDictionary dictionary];
	for ( NSString *s in lines ) 
	{
		NSArray* kvpair = [s componentsSeparatedByString:@"="];
		if ( [kvpair count] > 1 )
		{
			[token setObject:[kvpair objectAtIndex:1] forKey:[kvpair objectAtIndex:0]];
		}
	}
	
	//if google returned an error in the body [google returns Error=Bad Authentication in the body. which is weird, not sure if they use status codes]
	if ( [token objectForKey:@"Error"] ) 
	{
        //handle error
		return FALSE;
	}
	
	/*
	 The next step is to get your app running on google app engine to give 
	 you the ASCID cookie. I'm not sure why there is this extra step, it 
	 seems to be an issue on google's end and probably why GAE is not 
	 currently in their listed obj-c google data api library. My tests show
	 I have to request the cookie in order sync with GAE. Also, notice I 
	 don't do anything with the cookie. It seems just by requesting it and 
	 getting cookied, future requests will automatically contain the cookie.
	 I'm not sure if this is an iphone thing bc my app is an iphone app but 
	 I don't fully understand what is happening with this cookie. 
	 NOTE: the use of "myapp.appspot.com".
	 
	 It's a Cocoa thing... "The URL loading system automatically sends any 
	 stored cookies appropriate for an NSURLRequest unless the request 
	 specifies not to send cookies. Likewise, cookies returned in an 
	 NSURLResponse are accepted in accordance with the current cookie 
	 acceptance policy." – Brian Hammond
	 */
	NSURL* cookieUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://mygov-mobile.appspot.com/_ah/login?continue=http://mygov-mobile.appspot.com/&auth=%@", [token objectForKey:@"Auth"]]];
    NSLog( [cookieUrl description] );
    NSHTTPURLResponse* cookieResponse;
    NSError* cookieError;
    NSMutableURLRequest *cookieRequest = [[[NSMutableURLRequest alloc] initWithURL:cookieUrl] autorelease];
	
    [cookieRequest setHTTPMethod:@"GET"];
	
    NSData* cookieData = [NSURLConnection sendSynchronousRequest:cookieRequest returningResponse:&cookieResponse error:&cookieError];
	if ( nil == cookieData ) return FALSE;
	
	return TRUE;
}


- (NSURLRequest *)shapeLoginURL:(NSString *)url
{
	if ( nil == url ) return nil;
	
	NSArray *urlHalfs = [url componentsSeparatedByString:@"?"];
	if ( [urlHalfs count] < 1 ) return nil;
	if ( [urlHalfs count] < 2 ) 
	{
		// no "POST" data - just return
		return [[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
	}
	
	NSString *urlBase = [urlHalfs objectAtIndex:0]; (void)urlBase;
	
	NSString *postStr = [urlHalfs objectAtIndex:1];
	NSData *postData = [NSData dataWithBytes:[postStr UTF8String] length:[postStr length]]; (void)postData;
	
	/*
	NSMutableURLRequest *theRequest = [[[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlBase]] autorelease];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody:postData];
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
	*/
	
	NSURLRequest *theRequest = [[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
	return theRequest;
}


@end

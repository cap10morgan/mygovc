/*
 File: GoogleAppsDataSource.m
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

#import "myGovAppDelegate.h"

#import "CommunityDataManager.h"
#import "DataProviders.h"
#import "GoogleAppsDataSource.h"
#import "MyGovUserData.h"

@interface TempUserHolder : NSObject
{
	MyGovUser *m_user;
	id m_delegateOrNil;
}
@property (nonatomic,retain) MyGovUser *m_user;
@property (nonatomic,retain) id m_delegateOrNil;
@end

@implementation TempUserHolder
@synthesize m_user, m_delegateOrNil;
- (id) init
{
	if ( self = [super init] )
	{
		m_user = nil;
		m_delegateOrNil = nil;
	}
	return self;
}
@end


@interface GoogleAppsDataSource (private)
	- (BOOL)doUserAuthFor:(NSString *)username 
			 withPassword:(NSString *)password;

	- (void)gatherUserInfo:(NSDictionary *)usernameDict 
			andUseDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil;

	- (NSURLRequest *)shapeLoginURL:(NSString *)url;
	
	- (BOOL)validResponse:(NSString *)response;
	
	- (void)downloadGravatar:(TempUserHolder *)user;
@end



@implementation GoogleAppsDataSource

static NSString *kGAE_AuthCookie = @"ACSID";
//static NSString *kGAE_LSIDCookie = @"LSID";


- (id)init
{
	if ( self = [super init] )
	{
		m_loginURLRequest = nil;
		
		m_gravatarDownloadQueue = [[NSOperationQueue alloc] init];
		[m_gravatarDownloadQueue setMaxConcurrentOperationCount:3];
		
		m_gravatarDownloads = [[NSMutableDictionary alloc] initWithCapacity:30];
		
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
	if ( ![myGovAppDelegate networkIsAvailable:YES] )
	{
		NSLog(@"No network to validate username!");
		return FALSE;
	}
	
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
				[myGovAppDelegate networkNoLongerInUse];
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
		[myGovAppDelegate networkNoLongerInUse];
		return success;
	}
	
	[myGovAppDelegate networkNoLongerInUse];
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
	if ( ![myGovAppDelegate networkIsAvailable:YES] )
	{
		return FALSE;
	}
	
	NSString *gaeURLBase = [DataProviders GAE_DownloadURLFor:type];
	
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
	//[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setDateFormat:@"yyyy-MM-dd"];
	//[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	NSString *urlAddStr = [NSString stringWithFormat:@"?not_older_than=%@",[dateFormatter stringFromDate:startDate]];
	NSURL *gaeURL = [NSURL URLWithString:[gaeURLBase stringByAppendingString:urlAddStr]];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:gaeURL];
	[theRequest setHTTPMethod:@"GET"];
	[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
	
	NSURLResponse *theResponse = nil;
	NSError *err = nil;
	NSData *retVal = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&err];
	
	[theRequest release];
	[myGovAppDelegate networkNoLongerInUse];
	
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
	
	[self gatherUserInfo:idDict andUseDelegate:delegateOrNil];
	[idDict release];
	
	return TRUE;
}


- (BOOL)updateItemOfType:(CommunityItemType)type 
			  withItemID:(NSString *)itemID 
			 andDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// I grab a deep copy of this to prevent threading issues,
	// and to make sure my "new items" bading work properly :-)
	CommunityItem *item = [[[myGovAppDelegate sharedCommunityData] itemWithId:itemID] copy];
	
	if ( nil == item ) return FALSE;
	
	if ( ![myGovAppDelegate networkIsAvailable:YES] )
	{
		return FALSE;
	}
	
	NSString *gaeURLStr = [DataProviders GAE_CommunityItemCommentsURLFor:item];
	NSURL *gaeURL = [NSURL URLWithString:gaeURLStr];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:gaeURL];
	[theRequest setHTTPMethod:@"GET"];
	[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
	
	NSURLResponse *theResponse = nil;
	NSError *err = nil;
	NSData *retVal = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&err];
	
	[theRequest release];
	[myGovAppDelegate networkNoLongerInUse];
	
	if ( nil == retVal ) return FALSE;
	
	NSString *errString = nil;
	NSPropertyListFormat plistFmt;
	NSDictionary *plistDict = [NSPropertyListSerialization propertyListFromData:retVal 
															   mutabilityOption:NSPropertyListImmutable 
																		 format:&plistFmt 
															   errorDescription:&errString];
	
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
		CommunityComment *comment = [[[CommunityComment alloc] initWithPlistDict:objDict] autorelease];
		if ( nil != comment )
		{
			if ( [item.m_id isEqualToString:comment.m_id] )
			{
				// this item is really a comment, and should _not_
				// show up in the main community screen...
				[delegateOrNil communityDataSource:self removeCommunityItem:item];
				return TRUE;
			}
			else
			{
				comment.m_communityItemID = item.m_id;
				[item addComment:comment];
			}
			
			// collect all unique usernames 
			NSNumber *dummyArg = [NSNumber numberWithInt:1];
			[idDict setValue:dummyArg forKey:comment.m_creator];
		}
	}
	
	[self gatherUserInfo:idDict andUseDelegate:delegateOrNil];
	[idDict release];
	
	[delegateOrNil communityDataSource:self newCommunityItemArrived:item];
	
	[item release];
	
	return TRUE;
}


- (BOOL)submitCommunityItem:(CommunityItem *)item 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	if ( ![myGovAppDelegate networkIsAvailable:YES] )
	{
		NSLog(@"No network for community item submission!");
		return FALSE;
	}
	
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
	[myGovAppDelegate networkNoLongerInUse];
	
	if ( nil == response || ([response length] <= 0) || (nil != err) )
	{
		if ( nil != err )
		{
			NSLog(@"Community Item submission error: [%@:%d:%@]", [err domain], [err code], [err localizedDescription]);
		}
		return FALSE;
	}
	
	return [self validResponse:response];
}


- (BOOL)submitCommunityComment:(CommunityComment *)comment 
				  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	if ( ![myGovAppDelegate networkIsAvailable:YES] )
	{
		NSLog(@"No network for community comment submission!");
		return FALSE;
	}
	
	// create an NSURLRequest object from the community item
	// to perform a POST-style HTTP request
	NSURL *gaeURL = [NSURL URLWithString:[DataProviders GAE_CommunityReplyPOSTURLFor:comment.m_communityItemID]];
	
	NSString *itemStr = [DataProviders postStringFromDictionary:[comment writeToPlistDict]];
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
	[myGovAppDelegate networkNoLongerInUse];
	
	// check string response to indicate success / failure
	if ( nil == response || ([response length] <= 0) || (nil != err) )
	{
		if ( nil != err )
		{
			NSLog(@"Community Comment submission error: [%@:%d:%@]", [err domain], [err code], [err localizedDescription]);
		}
		return FALSE;
	}
	
	return [self validResponse:response];
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
	if ( ![myGovAppDelegate networkIsAvailable:YES] )
	{
		NSLog(@"No network for community item submission!");
		return FALSE;
	}
	
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
		NSLog(@"Received 'Error' from GAE: login failure!");
		[myGovAppDelegate networkNoLongerInUse];
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
	NSData *cookieData = nil;
	int attempts = 0;
	while ( nil == cookieData )
	{
		if ( ++attempts > 2 )
		{
			NSLog(@"Could not receive cookie from GAE for Auth: login failure!");
			[myGovAppDelegate networkNoLongerInUse];
			return FALSE;
		}
		
		NSURL* cookieUrl = [NSURL URLWithString:[NSString stringWithFormat:@"https://mygov-mobile.appspot.com/_ah/login?continue=http://mygov-mobile.appspot.com/&auth=%@", [token objectForKey:@"Auth"]]];
		//NSLog( [cookieUrl description] );
		NSHTTPURLResponse* cookieResponse;
		NSError* cookieError;
		NSMutableURLRequest *cookieRequest = [[[NSMutableURLRequest alloc] initWithURL:cookieUrl] autorelease];
		
		[cookieRequest setHTTPMethod:@"GET"];
		
		cookieData = [NSURLConnection sendSynchronousRequest:cookieRequest returningResponse:&cookieResponse error:&cookieError];
	}
	
	[myGovAppDelegate networkNoLongerInUse];
	return TRUE;
}


- (void)gatherUserInfo:(NSDictionary *)usernameDict 
		andUseDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	if ( nil == usernameDict ) return;
	
	// run through the idDict and make sure
	// our on-device usercache is up-to-date
	NSEnumerator *idEnum = [usernameDict keyEnumerator];
	NSString *username;
	while ( username = [idEnum nextObject] )
	{
		MyGovUser *user = [[MyGovUser alloc] init];
		user.m_username = username;
		
		if ( ![[myGovAppDelegate sharedUserData] usernameExistsInCache:username] )
		{
			// add some initial data into the cache
			[delegateOrNil communityDataSource:self userDataArrived:user];
		}
		
		// XXX - if (no avatar | avatar old): try to get a Gravatar!
		
		// XXX - query for more info?!
		
		// start a download if we've never seen the username
		// this time around...
		if ( nil == [m_gravatarDownloads objectForKey:username] )
		{
			// NOTE: we never actual de-reference the returned object
			// because it may be an invalid pointer. We just use it
			// as an indicator :-)
			TempUserHolder *tmpUser = [[[TempUserHolder alloc] init] autorelease];
			tmpUser.m_user = user;
			tmpUser.m_delegateOrNil = delegateOrNil;
			
			// kick off a download operation
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																				selector:@selector(downloadGravatar:) object:tmpUser];
			[m_gravatarDownloads setObject:theOp forKey:username];
			[m_gravatarDownloadQueue addOperation:theOp];
			
			[theOp release];
		}
		
		// release our reference to the user object
		[user release];
	}
	
	return;
}


- (NSURLRequest *)shapeLoginURL:(NSString *)url
{
	if ( nil == url ) return nil;
	
	NSArray *urlHalfs = [url componentsSeparatedByString:@"?"];
	if ( [urlHalfs count] < 1 ) return nil;
	if ( [urlHalfs count] < 2 ) 
	{
		// no "POST" data - just return
		NSURLRequest *theRequest = [[[NSURLRequest alloc] initWithURL:[NSURL URLWithString:url]] autorelease];
		return theRequest;
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


- (BOOL)validResponse:(NSString *)response
{
	NSRange errRange = [response rangeOfString:@"Error:"];
	if ( errRange.location != NSNotFound && errRange.length != 0 )
	{
		// I found the Error: string, make sure by looking for 
		// 'Traceback' which is sent when a python error occurs
		errRange = [response rangeOfString:@"Traceback"];
		if ( errRange.location != NSNotFound && errRange.length != 0 )
		{
			NSLog(@"Network response error: GAE error!");
			return FALSE;
		}
	}
	
	return TRUE;
}


- (void)downloadGravatar:(TempUserHolder *)tmpUser
{
	// Run as a thread
	
	if ( nil == tmpUser.m_user.m_username ) return;
	
	if ( ![myGovAppDelegate networkIsAvailable:YES] )
	{
		return;
	}
	
	// get the user email address
	NSString *emailAddr;
	NSRange atSymbolRange = [tmpUser.m_user.m_username rangeOfString:@"@"];
	if ( NSNotFound != atSymbolRange.location )
	{
		// some gmail accounts use other email addresses: use it :-)
		emailAddr = [[[NSString alloc] initWithString:[tmpUser.m_user.m_username lowercaseString]] autorelease];
	}
	else 
	{
		// add '@gmail.com' to the email
		emailAddr = [[[NSString alloc] initWithFormat:@"%@@gmail.com",[tmpUser.m_user.m_username lowercaseString]] autorelease];
	}
	
	// get an MD5 hash of the email
	NSString *md5hash = [[myGovAppDelegate md5hash:emailAddr] lowercaseString];
	
	// Grab a 100x100 image
	
	// 100x100 URL:
	//NSString *urlStr = [NSString stringWithFormat:@"http://www.gravatar.com/avatar/%@.jpg?s=100&d=http%%3A%%2F%%2Fwww.iphonefloss.com%%2Fsites%%2Fdefault%%2Ffiles%%2Fsystem_avatar.png",md5hash];
	static int fmt = 0;
	NSString *urlFmt;
	switch ( fmt )
	{
		case 0:
			urlFmt = @"http://www.gravatar.com/avatar/%@.jpg?s=100&d=identicon";
			break;
		case 1:
			urlFmt = @"http://www.gravatar.com/avatar/%@.jpg?s=100&d=wavatar";
			break;
		case 2:
			urlFmt = @"http://www.gravatar.com/avatar/%@.jpg?s=100&d=monsterid";
			break;
	}
	NSString *urlStr = [NSString stringWithFormat:urlFmt,md5hash];
	NSURL *url = [NSURL URLWithString:urlStr];
	
	// it's as easy as this:
	MyGovUser *user = [[[MyGovUser alloc] init] autorelease];
	NSData *imgData = [NSData dataWithContentsOfURL:url];
	UIImage *img = [[[UIImage alloc] initWithData:imgData] autorelease];
	
	[myGovAppDelegate networkNoLongerInUse];
	
	user.m_avatar = img;
	user.m_username = tmpUser.m_user.m_username;
	
	[tmpUser.m_delegateOrNil communityDataSource:self userDataArrived:user];
}


@end

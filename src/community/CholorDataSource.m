//
//  CholorDataSource.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <CoreLocation/CoreLocation.h>

#import "myGovAppDelegate.h"
#import "CholorDataSource.h"
#import "DataProviders.h"
#import "MyGovUserData.h"

@interface CholorDataSource (private)
	- (BOOL)validResponse:(NSString *)postResponse;
/*
	- (void)performUIDLookup:(NSInteger)uid 
				withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil;
 */
@end


@implementation CholorDataSource

+ (NSString *)postStringFromDictionary:(NSDictionary *)dict
{
	NSMutableString *postStr = [[[NSMutableString alloc] init] autorelease];
	
	NSEnumerator *keyEnum = [dict keyEnumerator];
	NSString *key;
	while ( key = [keyEnum nextObject] )
	{
		id obj = [dict objectForKey:key];
		NSString *valStr = nil;
		
		// NSString objects
		if ( [obj isKindOfClass:[NSString class]] )
		{
			valStr = (NSString *)obj;
		}
		// NSNumber objects
		else if ( [obj isKindOfClass:[NSNumber class]] )
		{
			valStr = [obj stringValue];
		}
		else if ( [obj isKindOfClass:[NSArray class]] )
		{
			// compile the array string
			if ( [obj count] > 0 )
			{
				NSMutableString *arrayStr = [[[NSMutableString alloc] init] autorelease];
				NSString *arrayAmp = @"";
				NSEnumerator *arrayEnum = [obj objectEnumerator];
				id arrayObj;
				while ( arrayObj = [arrayEnum nextObject] )
				{
					if ( [arrayObj isKindOfClass:[NSNumber class]] )
					{
						[arrayStr appendFormat:@"%@%@[]=%@",arrayAmp, key, [arrayObj stringValue]];
						arrayAmp = @"&"; // empty the first time through - set to ampersand when we need it!
					}
					else if ( [arrayObj isKindOfClass:[NSString class]] )
					{
						NSString *str = [arrayObj stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
						[arrayStr appendFormat:@"%@%@[]=%@", arrayAmp, key, str];
						arrayAmp = @"&"; // empty the first time through - set to ampersand when we need it!
					}
					//  - ignore this element: no nested arrays/dictionaries
				}
				
				if ( [arrayStr length] > 0 )
				{
					// XXX - do I need to [retain] this?!
					valStr = arrayStr;
					key = @""; // mash!
				}
			}
		}
		else
		{
			// no NSDictionary support!
			NSLog( @"Ignoring unsupported PList object '%@' in dictionary...", key );
		}
		
		if ( nil != valStr )
		{
			NSString *amp = @"";
			if ( 0 != [postStr length] )
			{
				amp = @"&";
			}
			if ( [key length] > 0 )
			{
				valStr = [valStr stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
				[postStr appendFormat:@"%@%@=%@", amp, key, valStr];
			}
			else
			{
				// just use the 'valStr' for arrays :-)
				[postStr appendString:valStr];
			}
		}
	}
	
	return postStr; //[postStr stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding];
}


- (id)init
{
	if ( self = [super init] )
	{
		m_isBusy = NO;
		m_username = nil;
		m_password = nil;
		m_authenticated_uid = -1;
	}
	return self;
}


- (void)dealloc
{
	[super dealloc];
}


- (NSURL *)externalLoginURL
{
	return nil;
}


- (BOOL)validateUsername:(NSString *)username 
			 andPassword:(NSString *)password
			withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	if ( ([m_username isEqualToString:username]) &&
		 ([m_password isEqualToString:password]) && 
		 (m_authenticated_uid > 0)
		)
	{
		// cached values (we're doing session management, baby!)
		// ...
		// (wow, this is the _hugest_ hack ever)
		// 
		return TRUE;
	}
	else
	{
		// do the user auth via Cholor...
		NSURL *cholorURL = [NSURL URLWithString:[DataProviders Cholor_UserAuthURL]];
		
		NSString *postStr = [NSString stringWithFormat:@"username=%@&password=%@",username,password];
		NSData *postData = [NSData dataWithBytes:[postStr UTF8String] length:[postStr length]];
		
		NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:cholorURL];
		[theRequest setHTTPMethod:@"POST"];
		[theRequest setHTTPBody:postData];
		[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
		[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
		
		NSURLResponse *theResponse = nil;
		NSError *err = nil;
		NSData *retVal = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&err];
		NSString *response = [[[NSString alloc] initWithData:retVal encoding:NSMacOSRomanStringEncoding] autorelease];
		
		if ( [response isEqualToString:[DataProviders Cholor_UserAuthFailedStr]] )
		{
			return FALSE;
		}
		
		NSInteger uid = [response integerValue];
		if ( uid <= 0 )
		{
			return FALSE;
		}
		
		m_authenticated_uid = uid;
		m_username = [[username retain] autorelease];
		m_password = [[password retain] autorelease];
		
		[delegateOrNil communityDataSource:self userAuthenticated:m_username];
		
		return TRUE;
	}
}


- (BOOL)addNewUser:(MyGovUser *)newUser
	  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// oh, that was successful alright!
	// do the user auth via Cholor...
	NSURL *cholorURL = [NSURL URLWithString:[DataProviders Cholor_UserAddURL]];
	
	NSString *postStr = [NSString stringWithFormat:@"username=%@&password=%@&email=%@",
									newUser.m_username, 
									newUser.m_password, 
									newUser.m_email ];
	NSData *postData = [NSData dataWithBytes:[postStr UTF8String] length:[postStr length]];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:cholorURL];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody:postData];
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
	
	NSURLResponse *theResponse = nil;
	NSError *err = nil;
	NSData *retVal = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&err];
	NSString *response = [[[NSString alloc] initWithData:retVal encoding:NSMacOSRomanStringEncoding] autorelease];
	
	if ( [response isEqualToString:[DataProviders Cholor_CommunityItemPOSTSucess]] )
	{
		// tell the delegate about it :-)
		[delegateOrNil communityDataSource:self userDataArrived:newUser];
		return TRUE;
	}
	
	return FALSE;
}


- (BOOL)downloadItemsOfType:(CommunityItemType)type 
			   notOlderThan:(NSDate *)startDate 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	NSURL *cholorURL = [NSURL URLWithString:[DataProviders Cholor_DownloadURLFor:type]];
	
	NSString *postStr = [NSString stringWithFormat:@"date=%0d",(NSInteger)[startDate timeIntervalSinceReferenceDate]];
	NSData *postData = [NSData dataWithBytes:[postStr UTF8String] length:[postStr length]];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:cholorURL];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody:postData];
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
	
	NSURLResponse *theResponse = nil;
	NSError *err = nil;
	NSData *retVal = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&err];
	
	[theRequest release];
	
	if ( nil == retVal ) return FALSE;
	
	NSString *errString = nil;
	NSPropertyListFormat plistFmt;
	NSArray *plistArray = [NSPropertyListSerialization propertyListFromData:retVal 
														   mutabilityOption:NSPropertyListImmutable 
																	 format:&plistFmt 
														   errorDescription:&errString];
	
	if ( [plistArray count] < 1 )
	{
		return FALSE;
	}
	
	NSMutableDictionary *uidDict = [[NSMutableDictionary alloc] init];
	
	// run through each array item, create a CommunityItem object
	// and let our delegate know about it!
	NSEnumerator *plEnum = [plistArray objectEnumerator];
	NSDictionary *objDict;
	while ( objDict = [plEnum nextObject] )
	{
		CommunityItem *item = [[[CommunityItem alloc] initFromPlistDictionary:objDict] autorelease];
		if ( nil != item )
		{
			[delegateOrNil communityDataSource:self newCommunityItemArrived:item];
		}
		
		NSNumber *dummyArg = [NSNumber numberWithInt:1];
		
		// 
		// collect all the unique user IDs so we can query for them later
		// 
		[uidDict setValue:dummyArg forKey:[NSString stringWithFormat:@"%d",item.m_creator]];
		NSEnumerator *commentEnum = [[item comments] objectEnumerator];
		CommunityComment *comment;
		while ( comment = [commentEnum nextObject] )
		{
			[uidDict setValue:dummyArg forKey:[NSString stringWithFormat:@"%d",comment.m_creator]];
		}
	}
	
	// 
	// now run through all the unique User IDs we received and query for
	// user info from cholor.com 
	// 
	
	NSEnumerator *uidEnum = [uidDict keyEnumerator];
	NSString *username;
	while ( username = [uidEnum nextObject] )
	{
		if ( ![[myGovAppDelegate sharedUserData] usernameExistsInCache:username] )
		{
			//[self performUIDLookup:uid withDelegate:delegateOrNil];
		}
	}
	
	return TRUE;
}


- (BOOL)submitCommunityItem:(CommunityItem *)item 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// create an NSURLRequest object from the community item
	// to perform a POST-style HTTP request
	NSURL *cholorURL = [NSURL URLWithString:[DataProviders Cholor_CommunityItemPOSTURL]];
	
	NSString *itemStr = [CholorDataSource postStringFromDictionary:[item writeItemToPlistDictionary]];
	NSData *itemAsPostData = [NSData dataWithBytes:[itemStr UTF8String] length:[itemStr length]];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:cholorURL];
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
	return [self validResponse:response];
}


- (BOOL)submitCommunityComment:(CommunityComment *)comment 
				  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// create an NSURLRequest object from the community comment
	// to perform a POST-style HTTP request
	NSURL *cholorURL = [NSURL URLWithString:[DataProviders Cholor_CommunityCommentPOSTURL]];
	
	NSString *itemStr = [CholorDataSource postStringFromDictionary:[comment writeToPlistDict]];
	NSData *itemAsPostData = [NSData dataWithBytes:[itemStr UTF8String] length:[itemStr length]];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:cholorURL];
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
	return [self validResponse:response];
}


- (BOOL)updateItemOfType:(CommunityItemType)type 
			  withItemID:(NSInteger)itemID 
			 andDelegate:(id<CommunityDataSourceDelegate>)delegatOrNil
{
	NSURL *cholorURL = [NSURL URLWithString:[DataProviders Cholor_DownloadURLFor:type]];
	
	NSString *postStr = [NSString stringWithFormat:@"date=%0d&id=%d",0,itemID];
	NSData *postData = [NSData dataWithBytes:[postStr UTF8String] length:[postStr length]];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:cholorURL];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody:postData];
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
	
	NSURLResponse *theResponse = nil;
	NSError *err = nil;
	NSData *retVal = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&err];
	
	[theRequest release];
	
	if ( nil == retVal ) return FALSE;
	
	NSString *errString = nil;
	NSPropertyListFormat plistFmt;
	NSArray *plistArray = [NSPropertyListSerialization propertyListFromData:retVal 
														   mutabilityOption:NSPropertyListImmutable 
																	 format:&plistFmt 
														   errorDescription:&errString];
	
	if ( [plistArray count] < 1 )
	{
		return FALSE;
	}
	
	if ( [plistArray count] > 1 )
	{
		NSLog( @"More than 1 item was downloaded for update (this is a server issue)" );
	}
	
	// just grab the first (and hopefully only) item
	CommunityItem *item = [[CommunityItem alloc] initFromPlistDictionary:[plistArray objectAtIndex:0]];
	if ( nil != item )
	{
		[delegatOrNil communityDataSource:self newCommunityItemArrived:item];
		[item release];
	}
	
	return TRUE;
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


#pragma mark CholorDataSource Private


- (BOOL)validResponse:(NSString *)postResponse
{
	// 
	// by looking for the success response in a more loose way
	// I can be more tolerent of server-side errors which produce 
	// warning output
	// 
	
	NSRange range = [postResponse rangeOfString:[DataProviders Cholor_CommunityItemPOSTSucess]];
	
	// we found the string if the length is greater than 0
	if ( range.length > 0 ) return TRUE;
	
	return FALSE;
}

/*
- (void)performUIDLookup:(NSInteger)uid 
			withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	NSURL *cholorURL = [NSURL URLWithString:[DataProviders Cholor_UserLookupURL]];
	
	NSString *postStr = [NSString stringWithFormat:@"id=%0d",uid];
	NSData *postData = [NSData dataWithBytes:[postStr UTF8String] length:[postStr length]];
	
	NSMutableURLRequest *theRequest = [[NSMutableURLRequest alloc] initWithURL:cholorURL];
	[theRequest setHTTPMethod:@"POST"];
	[theRequest setHTTPBody:postData];
	[theRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
	[theRequest setTimeoutInterval:10.0f]; // 10 second timeout
	
	NSURLResponse *theResponse = nil;
	NSError *err = nil;
	NSData *retVal = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:&theResponse error:&err];
	NSString *response = [[[NSString alloc] initWithData:retVal encoding:NSMacOSRomanStringEncoding] autorelease];
	
	[theRequest release];
	
	if ( ([response length] > 3) && ![[response substringWithRange:(NSRange){0,3}] isEqualToString:@"<br"] )
	{
		// create a new MyGovUser object and pass it up to our delegate
		MyGovUser *user = [[MyGovUser alloc] init];
		user.m_username = response;
		user.m_id = uid;
		
		[delegateOrNil communityDataSource:self userDataArrived:user];
	}
}
*/

@end

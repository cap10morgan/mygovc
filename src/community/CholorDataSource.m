//
//  CholorDataSource.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <CoreLocation/CoreLocation.h>
#import "CholorDataSource.h"
#import "DataProviders.h"

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
			NSLog( @"Ignoring unsupported PList object '%@' of type '%@' in dictionary...", key, [obj className] );
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
	}
	return self;
}


- (void)dealloc
{
	[super dealloc];
}


- (BOOL)validateUsername:(NSString *)username 
			 andPassword:(NSString *)password
{
	// all users are valid :-)
	return TRUE;
}


- (BOOL)addNewUser:(MyGovUser *)newUser
	  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// oh, that was successful alright!
	return TRUE;
}


- (BOOL)downloadItemsOfType:(CommunityItemType)type 
			   notOlderThan:(NSDate *)startDate 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	return FALSE;
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
	
	// check string response to indicate success / failure
	if ( ![response isEqualToString:[DataProviders Cholor_CommunityItemPOSTSucess]] )
	{
		return FALSE;
	}
	
	return TRUE;
}


- (BOOL)submitCommunityComment:(CommunityComment *)comment 
				  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
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

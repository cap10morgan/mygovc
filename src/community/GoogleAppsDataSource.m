//
//  GoogleAppsDataSource.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "GoogleAppsDataSource.h"


@implementation GoogleAppsDataSource

- (id)init
{
	if ( self = [super init] )
	{
		// XXX - custom initialization
	}
	return self;
}


- (BOOL)validateUsername:(NSString *)username 
			 andPassword:(NSString *)password
{
	// XXX - this needs to be filled in!
	return FALSE;
}


- (BOOL)addNewUser:(MyGovUser *)newUser
	  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	// XXX - this needs to be filled in!
	return FALSE;
}


- (BOOL)downloadItemsOfType:(CommunityItemType)type 
			   notOlderThan:(NSDate *)startDate 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
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

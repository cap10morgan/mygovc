//
//  JeremyaStaticDataSource.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "JeremyaStaticDataSource.h"


@implementation JeremyaStaticDataSource

// XXX - I will fill this in with some static data for testing...

- (BOOL)validateUsername:(NSString *)username 
			 andPassword:(NSString *)password
{
	return FALSE;
}


- (BOOL)addNewUser:(MyGovUser *)newUser
	  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	return FALSE;
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

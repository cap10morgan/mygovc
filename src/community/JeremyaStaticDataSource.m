//
//  JeremyaStaticDataSource.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <CoreLocation/CoreLocation.h>
#import "JeremyaStaticDataSource.h"


@implementation JeremyaStaticDataSource

// XXX - I will fill this in with some static data for testing...

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
	// create two artificial community items: 1 feedback, 1 event
	
	[NSThread sleepForTimeInterval:2.0f];
	
	// feedback item
	if ( eCommunity_Chatter == type )
	{
		CommunityItem *ci = [[CommunityItem alloc] init];
		ci.m_id = @"abcdefg";
		ci.m_date = [NSDate date];
		ci.m_type = eCommunity_Chatter;
		ci.m_title = @"He Twittered That?!";
		ci.m_summary = @"On Tuesday Rep. Pete Hoekstra leaked national security information...";
		ci.m_text = @"On Tuesday Rep. Pete Hoekstra leaked national security information via Twitter. He let the entire world know where he was and what he was doing in Iraq - when the mission was supposed to be secret!";
		ci.m_creator = 0; // system user...
		ci.m_mygovURL = [NSURL URLWithString:@"mygov://congress/H000676"];
		ci.m_mygovURLTitle = @"Rep. Pete Hoekstra";
		ci.m_webURL = [NSURL URLWithString:@"http://thinkprogress.org/2009/02/07/hoekstra-twitters-iraq/"];
		ci.m_webURLTitle = @"Hoekstra Leaks Information...";
		ci.m_image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"hoekstra.png"]];
		
		for ( int ii = 0; ii < 4; ++ii )
		{
			CommunityComment *cc = [[CommunityComment alloc] init];
			cc.m_id = [NSString stringWithFormat:@"cmt%0d",ii];
			cc.m_creator = 0;
			cc.m_title = [NSString stringWithFormat:@"Test comment %0d",ii];
			cc.m_text = @"This is the comment text right here. The place where someone would write some witty, sacastic or biting remark about the item :-)";
			cc.m_communityItemID = @"abcdefg";
			[ci addComment:cc];
		}
		
		[delegateOrNil communityDataSource:self newCommunityItemArrived:ci];
		[ci release];
		
		[NSThread sleepForTimeInterval:2.0f];
	}
	
	// event item
	if ( eCommunity_Event == type )
	{
		CommunityItem *ci = [[CommunityItem alloc] init];
		ci.m_id = @"gfedcba";
		ci.m_date = [NSDate date];
		ci.m_type = eCommunity_Event;
		ci.m_title = @"Jeremy's Healthcare Mixer";
		ci.m_summary = @"A community info session on healthcare";
		ci.m_text = @"A community info session on healthcare";
		ci.m_creator = 0; // system user...
		ci.m_mygovURL = nil;
		ci.m_mygovURLTitle = nil;
		ci.m_webURL = nil;
		ci.m_webURLTitle =nil;
		ci.m_eventLocation = [[CLLocation alloc] initWithLatitude:42.827403 longitude:-86.056015];
		ci.m_eventDate = [NSDate dateWithTimeIntervalSinceNow:(60*60*24*7)];
		ci.m_image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"communityEventIcon.png"]];
		
		[delegateOrNil communityDataSource:self newCommunityItemArrived:ci];
		[ci release];
		
		[NSThread sleepForTimeInterval:2.0f];
	}
	
	return TRUE;
}


- (BOOL)updateItemOfType:(CommunityItemType)type 
			  withItemID:(NSInteger)itemID 
			 andDelegate:(id<CommunityDataSourceDelegate>)delegatOrNil
{
	return TRUE;
}


- (BOOL)submitCommunityItem:(CommunityItem *)item 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil
{
	return FALSE;
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

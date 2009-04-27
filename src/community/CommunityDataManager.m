//
//  CommunityDataManager.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"
#import "CommunityDataManager.h"
#import "CommunityItem.h"
#import "CommunityItemTableCell.h"

#define COMMUNITY_USE_JEREMYA_STATIC_DATA 1
#define COMMUNITY_USE_GOOGLEAPPS_DATA     0

#if COMMUNITY_USE_JEREMYA_STATIC_DATA
#	import "JeremyaStaticDataSource.h"
#	define DATA_SOURCE_TYPE JeremyaStaticDataSource
#elif COMMUNITY_USE_GOOGLEAPPS_DATA
#	import "GoogleAppsDataSource.h"
#	define DATA_SOURCE_TYPE GoogleAppsDataSource
#else
#	error "No Community Data Source Defined!"
#endif


@interface CommunityDataManager (private)
	- (void)setStatus:(NSString *)status;
@end


@implementation CommunityDataManager

@synthesize isDataAvailable, isBusy;

+ (NSString *)dataCachePath
{
	NSString *cachePath = [[myGovAppDelegate sharedAppCacheDir] stringByAppendingPathComponent:@"community"];
	return cachePath;
}

- (id)init
{
	if ( self = [super init] )
	{
		isDataAvailable = NO;
		isBusy = NO;
		m_currentStatusMessage = [[NSMutableString alloc] initWithString:@"Initializing..."];
		m_notifyTarget = nil;
		m_notifySelector = nil;
		
		m_dataSource = [[DATA_SOURCE_TYPE alloc] init];
		m_userData = [[myGovAppDelegate sharedUserData] retain];
		
		m_inMemoryStartDate = nil;
		m_inMemoryEndData = nil;
		m_feedbackData = nil;
		m_eventData = nil;
	}
	return self;
}


- (void)dealloc
{
	[m_notifyTarget release];
	[m_userData release];
	[(id)m_dataSource release];
	[m_currentStatusMessage release];
	
	[super dealloc];
}


- (void)setNotifyTarget:(id)target withSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = [target retain];
	m_notifySelector = sel;
}


- (NSString *)currentStatusMessage
{
	return (NSString *)m_currentStatusMessage;
}


// starts a possible data cache load, plus new data download
- (void)loadData
{
	// XXX - fill me in!
}


// drop items from cache which are too old (defined in a user preference)
- (void)purgeOldItemsFromCache
{
	// XXX - fill me in!
}


// Table data methods
- (NSInteger)numberOfSectionsForType:(CommunityItemType)type
{
	return 1;
}


- (NSString *)sectionName:(NSInteger)section forType:(CommunityItemType)type
{
	return nil;
}


- (NSInteger)numberOfRowsInSection:(NSInteger)section forType:(CommunityItemType)type
{
	switch ( type )
	{
		default:
			return 0;
			
		case eCommunity_Feedback:
			if ( section >= 1 ) return 0;
			else return [m_feedbackData count];
			
		case eCommunity_Event:
			if ( section >= 1 ) return 0;
			else return [m_eventData count];
	}
}


- (CGFloat)heightForDataAtIndexPath:(NSIndexPath *)indexPath forType:(CommunityItemType)type
{
	CommunityItem *item = [self itemForIndexPath:indexPath andType:type];
	return [CommunityItemTableCell getCellHeightForItem:item];
}


- (CommunityItem *)itemForIndexPath:(NSIndexPath *)indexPath andType:(CommunityItemType)type
{
	NSArray *itemArray = nil;
	CommunityItem *item = nil;
	switch ( type )
	{
		default:
			break;
		
		case eCommunity_Feedback:
			if ( indexPath.section >= 1 ) break;
			itemArray = m_feedbackData;
			break;
			
		case eCommunity_Event:
			if ( indexPath.section >= 1 ) break;
			itemArray = m_eventData;
			break;
	}
	
	if ( indexPath.row >= [itemArray count] ) return nil;
	item = [itemArray objectAtIndex:indexPath.row];
	return item;
}


#pragma mark CommunityDataManager Private


- (void)setStatus:(NSString *)status
{
	[m_currentStatusMessage setString:status];
	if ( nil != m_notifyTarget )
	{
		if ( [m_notifyTarget respondsToSelector:m_notifySelector] )
		{
			[m_notifyTarget performSelector:m_notifySelector withObject:m_currentStatusMessage];
		}
	}
}


#pragma mark CommunityDataSourceDelegate methods


- (void)communityDataSource:(id)dataSource 
	newCommunityItemArrived:(CommunityItem *)item
{
	NSMutableArray *itemArray = nil;
	
	if ( nil == item ) return;
	switch ( item.m_type )
	{
		default:
			return;
			
		case eCommunity_Feedback:
			if ( nil == m_feedbackData ) m_feedbackData = [[NSMutableArray alloc] initWithCapacity:2];
			itemArray = m_feedbackData;
			break;
			
		case eCommunity_Event:
			if ( nil == m_eventData ) m_eventData = [[NSMutableArray alloc] initWithCapacity:2];
			itemArray = m_eventData;
			break;
	}
	
	if ( nil == itemArray ) return;
	
	[itemArray addObject:item];
	[itemArray sortUsingSelector:@selector(compareItemByDate:)];
}


- (void)communityDataSource:(id)dataSource 
			userDataArrived:(MyGovUser *)user
{
	// XXX - do something with user data input...
}


- (void)communityDataSource:(id)dataSource 
		searchResultArrived:(CommunityItem *)item
{
	// XXX - handle search results!
}


- (void)communityDataSource:(id)dataSource 
			 operationError:(NSError *)error
{
	// XXX - handle operation error!
	[self setStatus:[NSString stringWithFormat:@"ERR: ",[error localizedDescription]]];
}


@end

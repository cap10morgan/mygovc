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
#import "MyGovUserData.h"

#define COMMUNITY_USE_JEREMYA_STATIC_DATA 0
#define COMMUNITY_USE_CHOLOR_DATA         1
#define COMMUNITY_USE_GOOGLEAPPS_DATA     0

#if COMMUNITY_USE_JEREMYA_STATIC_DATA
#	import "JeremyaStaticDataSource.h"
#	define DATA_SOURCE_TYPE JeremyaStaticDataSource
#elif COMMUNITY_USE_CHOLOR_DATA
#	import "CholorDataSource.h"
#	define DATA_SOURCE_TYPE CholorDataSource
#elif COMMUNITY_USE_GOOGLEAPPS_DATA
#	import "GoogleAppsDataSource.h"
#	define DATA_SOURCE_TYPE GoogleAppsDataSource
#else
#	error "No Community Data Source Defined!"
#endif


@interface CommunityDataManager (private)
	- (void)setStatus:(NSString *)status;
	- (NSString *)cachePathForItem:(CommunityItem *)item;
	- (NSDate *)dateFromCachePath:(NSString *)filePath;
	- (void)loadData_imp;
	- (void)downloadNewDataStartingAt:(NSDate *)date;
	- (void)syncInMemoryDataWithServer;
	- (void)purgeCacheItemsOlderThan:(NSDate *)date;
	- (BOOL)addCommunityItem:(CommunityItem *)newItem;
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
		m_chatterData = nil;
		m_chatterIDDict = nil;
		
		m_eventData = nil;
		m_eventIDDict = nil;
		
		m_searchData = nil;
		
		m_latestItemDate = [NSDate distantPast];
		
		// make sure the cache directories exists!
		[[NSFileManager defaultManager] createDirectoryAtPath:[[CommunityDataManager dataCachePath] stringByAppendingPathComponent:@"data"]
								  withIntermediateDirectories:YES 
												   attributes:nil 
														error:NULL];
		
		[[NSFileManager defaultManager] createDirectoryAtPath:[[CommunityDataManager dataCachePath] stringByAppendingPathComponent:@"usercache"]
								  withIntermediateDirectories:YES 
												   attributes:nil 
														error:NULL];
	}
	return self;
}


- (void)dealloc
{
	[m_notifyTarget release];
	[m_userData release];
	[(id)m_dataSource release];
	[m_currentStatusMessage release];
	
	[m_inMemoryStartDate release];
	[m_inMemoryEndData release];
	
	[m_chatterData release];
	[m_chatterIDDict release];
	
	[m_eventData release];
	[m_eventIDDict release];
	
	[m_searchData release];
	
	[super dealloc];
}


- (void)setNotifyTarget:(id)target withSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = [target retain];
	m_notifySelector = sel;
}


- (void)setDataSource:(id<CommunityDataSourceProtocol>)source
{
	[(id)m_dataSource release];
	m_dataSource = [(id)source retain];
}


- (id<CommunityDataSourceProtocol>)dataSource
{
	return m_dataSource;
}


- (NSString *)currentStatusMessage
{
	return (NSString *)m_currentStatusMessage;
}


// starts a possible data cache load, plus new data download
- (void)loadData
{
	// we're already working!
	if ( isBusy ) return;
	
	isBusy = YES;
	[self setStatus:@"Loading Community Data..."];
	
	// read disk data into memory (via a worker thread)
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		selector:@selector(loadData_imp) 
																		  object:nil];
	
	// Add the operation to the internal operation queue managed by the application delegate.
	[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
	
	[theOp release];
}


// drop items from cache which are too old (defined in a user preference)
- (void)purgeOldItemsFromCache:(BOOL)blocking
{
	if ( isBusy ) return;
	
	isBusy = YES;
	
	NSNumber *max_age_str = [[NSUserDefaults standardUserDefaults] objectForKey:@"mygov_community_data_age"];
	NSInteger max_age = -([max_age_str integerValue]);
	
	NSDate *oldestItemDate = [[NSDate date] addTimeInterval:max_age];
	
	if ( blocking )
	{
		// purge the data in a blocking way
		[self purgeCacheItemsOlderThan:oldestItemDate];
		isBusy = NO;
	}
	else
	{
		// start a worker thread to purge the data
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self 
																			selector:@selector(purgeCacheItemsOlderThan:) 
																			  object:oldestItemDate];
	
		// Add the operation to the internal operation queue managed by the application delegate.
		[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
		
		[theOp release];
	}
}


- (CommunityItem *)itemWithId:(NSInteger)itemID
{
	CommunityItem *item;
	
	// grrrr - I have to hack around the fact that I started using 
	// a string ID, and now am using an int...
	
	item = [m_chatterIDDict objectForKey:[NSString stringWithFormat:@"%0d",itemID]];
	if ( nil != item ) return item;
	
	item = [m_eventIDDict objectForKey:[NSString stringWithFormat:@"%0d",itemID]];
	if ( nil != item ) return item;
	
	return nil;
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
			
		case eCommunity_Chatter:
			if ( section >= 1 ) return 0;
			else return [m_chatterData count];
			
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
		
		case eCommunity_Chatter:
			if ( indexPath.section >= 1 ) break;
			itemArray = m_chatterData;
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


- (NSString *)cachePathForItem:(CommunityItem *)item
{
	NSString *cachePath = [[CommunityDataManager dataCachePath] stringByAppendingPathComponent:@"data"];
	
	NSInteger itemDate = [item.m_date timeIntervalSinceReferenceDate];
	NSString *itemID = item.m_id;
	if ( [itemID length] <= 0 ) itemID = @"Z";
	
	cachePath = [cachePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%d__%@",itemDate,itemID]];
	
	return cachePath;
}


- (NSDate *)dateFromCachePath:(NSString *)filePath
{
	NSString *fname = [filePath lastPathComponent];
	NSArray *nmArray = [fname componentsSeparatedByString:@"__"];
	if ( [nmArray count] < 2 )
	{
		// this file shouldn't be here - it has in incorrect name
		return nil;
	}
	
	NSInteger itemDate = [[nmArray objectAtIndex:0] integerValue];
	NSDate *date = [[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:itemDate] autorelease];
	return date;
}


- (void)loadData_imp
{
	isBusy = YES;
	
	//NSDate *newestDate = [NSDate distantPast];
	
	[self setStatus:@"Loading cached data..."];
	
	// load everything in our data cache!
	NSString *cachePath = [[CommunityDataManager dataCachePath] stringByAppendingPathComponent:@"data"];
	NSDirectoryEnumerator *dEnum = [[NSFileManager defaultManager] enumeratorAtPath:cachePath];
	NSString *file;
	while ( file = [dEnum nextObject] )
	{
		NSString *fPath = [cachePath stringByAppendingPathComponent:file];
		CommunityItem *newItem = [[CommunityItem alloc] initFromFile:fPath];
		
		// ignore return code...
		[self addCommunityItem:newItem];
		
		[newItem release];
	}
	
	// now download any new data!
	if ( NSOrderedSame == [m_latestItemDate compare:[NSDate distantPast]] )
	{
		// we have no cache - only download items within the 
		// timeframe specified by the user preference
		NSNumber *max_age_str = [[NSUserDefaults standardUserDefaults] objectForKey:@"mygov_community_data_age"];
		NSInteger max_age = -([max_age_str integerValue]);
		
		m_latestItemDate = [[NSDate date] addTimeInterval:max_age];
	}
	
	// download any new items
	[self downloadNewDataStartingAt:m_latestItemDate];
	
	isBusy = NO;
	isDataAvailable = YES;
	
	// 
	// Start a worker thread 
	// Update all our cached/downloaded items one-by one
	// to grab any new comments from users
	// 
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self 
																		selector:@selector(syncInMemoryDataWithServer) 
																		  object:nil];
	
	// Add the operation to the internal operation queue managed by the application delegate.
	[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
	
	[theOp release];
	
	[self setStatus:@"finished."];
}


- (void)downloadNewDataStartingAt:(NSDate *)date
{
	isBusy = YES;
	
	// XXX - validate username/password?!
	
	// perform the blocking data download: Feedback items
	[self setStatus:@"Downloading chatter..."];
	[m_dataSource downloadItemsOfType:eCommunity_Chatter notOlderThan:date withDelegate:self];
	
	// perform the blocking data download: Feedback items
	[self setStatus:@"Downloading events..."];
	[m_dataSource downloadItemsOfType:eCommunity_Event notOlderThan:date withDelegate:self];
	
	isBusy = NO;
}


- (void)syncInMemoryDataWithServer
{
	BOOL success = NO;
	
	// this method is intended to be run in a background thread
	// as it linearly runs through all the community items we
	// have in memory, and attempts to query the server for updates
	
	// retain a reference to the current set of CommunityItem objects
	// because as we download new ones, the old ones are replaced!
	NSMutableDictionary *itemDict = [[NSMutableDictionary alloc] initWithDictionary:m_chatterIDDict];
	[itemDict addEntriesFromDictionary:m_eventIDDict];
	
	NSEnumerator *iEnum = [itemDict objectEnumerator];
	CommunityItem *theItem = nil;
	while ( theItem = [iEnum nextObject] )
	{
		// do the updating via the CommunityDataSource object
		if ( [m_dataSource updateItemOfType:theItem.m_type 
								 withItemID:[theItem.m_id integerValue]
								andDelegate:self] )
		{
			success = YES;
		}
	}
	
	[itemDict release];
	
	if ( success )
	{
		// this will cause our associated UITableView to reload its data
		// and thus re-display the info we just updated
		[self setStatus:@"update finished"];
	}
}


- (void)purgeCacheItemsOlderThan:(NSDate *)date
{
	NSString *cachePath = [[CommunityDataManager dataCachePath] stringByAppendingPathComponent:@"data"];
	NSDirectoryEnumerator *dEnum = [[NSFileManager defaultManager] enumeratorAtPath:cachePath];
	NSString *file;
	while ( file = [dEnum nextObject] )
	{
		NSString *fPath = [cachePath stringByAppendingPathComponent:file];
		NSDate *itemDate = [self dateFromCachePath:fPath];
		if ( NSOrderedAscending == [itemDate compare:date] )
		{
			// 'itemDate' is earlier than the passed in date - remove this file!
			NSLog( @"Removing community cache: %@", fPath );
			[[NSFileManager defaultManager] removeItemAtPath:fPath error:NULL];
		}
	}
}


- (BOOL)addCommunityItem:(CommunityItem *)newItem
{
	NSMutableArray *itemArray = nil;
	NSMutableDictionary *itemDict = nil;
	
	if ( nil == newItem ) return FALSE;
	switch ( newItem.m_type )
	{
		default:
			return FALSE;
			
		case eCommunity_Chatter:
			if ( nil == m_chatterData ) m_chatterData = [[NSMutableArray alloc] initWithCapacity:2];
			if ( nil == m_chatterIDDict ) m_chatterIDDict = [[NSMutableDictionary alloc] initWithCapacity:2];
			itemArray = m_chatterData;
			itemDict = m_chatterIDDict;
			break;
			
		case eCommunity_Event:
			if ( nil == m_eventData ) m_eventData = [[NSMutableArray alloc] initWithCapacity:2];
			if ( nil == m_eventIDDict ) m_eventIDDict = [[NSMutableDictionary alloc] initWithCapacity:2];
			itemArray = m_eventData;
			itemDict = m_eventIDDict;
			break;
	}
	
	if ( nil == itemArray ) return FALSE;
	
	// search the itemDict for duplicates
	CommunityItem *obj = [itemDict objectForKey:newItem.m_id];
	if ( nil != obj )
	{
		NSLog( @"Replacing item: '%@'", newItem.m_id );
		
		NSUInteger arrayIdx = [itemArray indexOfObjectIdenticalTo:obj];
		if ( NSNotFound == arrayIdx )
		{
			NSLog( @"Item '%@' is in the dictionary, but not the array?! Ignoring it.", newItem.m_id );
			return FALSE;
		}
		
		[itemArray replaceObjectAtIndex:arrayIdx withObject:newItem];
		[itemDict setValue:newItem forKey:newItem.m_id];
		
		if ( isDataAvailable )
		{
			// if we're replacing an item, and data is available
			// then we're probably updating something and the object
			// managing us may appreciate a callback :-)
			[self setStatus:m_currentStatusMessage];
		}
	}
	else
	{
		// set the array value
		[itemArray addObject:newItem];
		[itemArray sortUsingSelector:@selector(compareItemByDate:)];
		
		// set the dictionary value
		[itemDict setValue:newItem forKey:newItem.m_id];
	}
	
	if ( NSOrderedAscending == [m_latestItemDate compare:newItem.m_date] )
	{
		// newItem.m_date is more recent than 'm_latestItemDate'
		m_latestItemDate = [[newItem.m_date retain] autorelease];
	}
	
	return TRUE;
}


#pragma mark CommunityDataSourceDelegate methods


- (void)communityDataSource:(id)dataSource 
	newCommunityItemArrived:(CommunityItem *)item
{
	// add the item to our in-memory structures
	if ( ![self addCommunityItem:item] ) return;
	
	// store the item in our data cache!
	NSString *filePath = [self cachePathForItem:item];
	[item writeItemToFile:filePath];
}


- (void)communityDataSource:(id)dataSource 
			userDataArrived:(MyGovUser *)user
{
	MyGovUserData *userData = [myGovAppDelegate sharedUserData];
	[userData setUserInCache:user];
}


- (void)communityDataSource:(id)dataSource 
		searchResultArrived:(CommunityItem *)item
{
	if ( nil == m_searchData ) m_searchData = [[NSMutableArray alloc] initWithCapacity:2];
	[m_searchData addObject:item];
	[m_searchData sortUsingSelector:@selector(compareItemByDate:)];
}


- (void)communityDataSource:(id)dataSource 
			 operationError:(NSError *)error
{
	[self setStatus:[NSString stringWithFormat:@"ERR: ",[error localizedDescription]]];
}


@end

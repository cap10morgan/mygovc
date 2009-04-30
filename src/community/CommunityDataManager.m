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
		m_feedbackData = nil;
		m_eventData = nil;
		m_searchData = nil;
		
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
	
	[m_feedbackData release];
	[m_eventData release];
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
	
	NSDate *newestDate = [NSDate distantPast];
	
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
		
		if ( NSOrderedAscending == [newestDate compare:newItem.m_date] )
		{
			// newItem.m_date is more recent than 'newestDate'
			newestDate = [[newItem.m_date retain] autorelease];
		}
		
		[newItem release];
	}
	
	// now download any new data!
	if ( NSOrderedSame == [newestDate compare:[NSDate distantPast]] )
	{
		// we have no cache - only download items within the 
		// timeframe specified by the use preference
		NSNumber *max_age_str = [[NSUserDefaults standardUserDefaults] objectForKey:@"mygov_community_data_age"];
		NSInteger max_age = -([max_age_str integerValue]);
		
		newestDate = [[NSDate date] addTimeInterval:max_age];
	}
	
	[self downloadNewDataStartingAt:newestDate];
	
	isBusy = NO;
	isDataAvailable = YES;
	
	[self setStatus:@"finished."];
}


- (void)downloadNewDataStartingAt:(NSDate *)date
{
	isBusy = YES;
	
	// XXX - validate username/password?!
	
	// perform the blocking data download: Feedback items
	[self setStatus:@"Downloading chatter..."];
	[m_dataSource downloadItemsOfType:eCommunity_Feedback notOlderThan:date withDelegate:self];
	
	// perform the blocking data download: Feedback items
	[self setStatus:@"Downloading events..."];
	[m_dataSource downloadItemsOfType:eCommunity_Event notOlderThan:date withDelegate:self];
	
	isBusy = NO;
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
	
	if ( nil == newItem ) return FALSE;
	switch ( newItem.m_type )
	{
		default:
			return FALSE;
			
		case eCommunity_Feedback:
			if ( nil == m_feedbackData ) m_feedbackData = [[NSMutableArray alloc] initWithCapacity:2];
			itemArray = m_feedbackData;
			break;
			
		case eCommunity_Event:
			if ( nil == m_eventData ) m_eventData = [[NSMutableArray alloc] initWithCapacity:2];
			itemArray = m_eventData;
			break;
	}
	
	if ( nil == itemArray ) return FALSE;
	
	// search the array for duplicates: O(n)... boo...
	NSEnumerator *objEnum = [itemArray objectEnumerator];
	CommunityItem *obj;
	while ( obj = [objEnum nextObject] )
	{
		if ( [obj.m_id isEqualToString:newItem.m_id] )
		{
			NSLog( @"Duplicate item: '%@' - ignoring!", newItem.m_id );
			return FALSE;
		}
	}
	
	[itemArray addObject:newItem];
	[itemArray sortUsingSelector:@selector(compareItemByDate:)];
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

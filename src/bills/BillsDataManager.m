/*
 File: BillsDataManager.m
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
#import "DataProviders.h"

#import "BillContainer.h"
#import "BillsDataManager.h"
#import "BillSummaryXMLParser.h"
#import "CongressDataManager.h"
#import "XMLParserOperation.h"


@interface BillsDataManager (private)
	- (void)beginBillSummaryDownload;
	- (void)writeBillDataToCache:(id)sender;
	- (void)readBillDataFromCache:(id)sender;
	- (void)setStatus:(NSString *)status;
	- (void)addNewBill:(BillContainer *)bill checkForDuplicates:(BOOL)checkDuplicates;
	- (void)clearData;
@end



@implementation BillsDataManager

@synthesize isDataAvailable;
@synthesize isBusy;

static NSInteger s_maxBillPages = 0;

+ (NSString *)dataCachePath
{
	NSString *congressDataPath = [[myGovAppDelegate sharedAppCacheDir] stringByAppendingPathComponent:@"bills"];
	return congressDataPath;
}


+ (NSString *)billDataCacheFile
{
	NSString *dataPath = [[BillsDataManager dataCachePath] stringByAppendingPathComponent:@"data"];
	NSString *billDataPath = [dataPath stringByAppendingPathComponent:@"bills.cache"];
	return billDataPath;
}


- (id)init
{
	if ( self = [super init] )
	{
		isDataAvailable = NO;
		isBusy = NO;
		isDownloading = NO;
		isReadingCache = NO;
		
		m_currentStatusMessage = [[NSMutableString alloc] init];
		[m_currentStatusMessage setString:@"Waiting for congress data..."];
		
		m_notifyTarget = nil;
		m_notifySelector = nil;
		
		// initialize data arrays...
		m_billData = [[NSMutableDictionary alloc] initWithCapacity:24];
		
		m_houseSections = [[NSMutableArray alloc] initWithCapacity:12];
		m_houseBills = [[NSMutableDictionary alloc] initWithCapacity:12];
		m_senateSections = [[NSMutableArray alloc] initWithCapacity:12];
		m_senateBills = [[NSMutableDictionary alloc] initWithCapacity:12];
		
		m_billsDownloaded = 0;
		m_billDownloadPage = 1;
		m_downloadReallyRecentStuff = NO;
		
		m_searching = NO;
		m_searchResults = nil;
		m_currentSearchString = nil;
		
		m_xmlParser = nil;
		m_timer = nil;
	}
	return self;
}


- (void)dealloc
{
	isDataAvailable = NO;
	isBusy = NO;
	isDownloading = NO;
	isReadingCache = NO;
	
	[m_xmlParser abort];
	[m_xmlParser release];
	
	[m_notifyTarget release];
	[m_houseSections release];
	[m_houseBills release];
	[m_senateSections release];
	[m_senateBills release];
	[m_billData release];
	
	[m_searchResults release];
	[m_currentSearchString release];
	
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
	return m_currentStatusMessage;
}


- (void)loadData
{
	//NSString *cachePath = [BillsDataManager billDataCacheFile];
	NSString *dataPath = [BillsDataManager dataCachePath]; //[[BillsDataManager dataCachePath] stringByAppendingPathComponent:@"data"];
	
	BOOL shouldReDownload = NO;
	
	// check to see if we should re-load the data!
	NSNumber *reloadFreq = [[NSUserDefaults standardUserDefaults] objectForKey:@"mygov_autoreload_bills"];
	NSInteger updateInterval = [reloadFreq integerValue];
	if ( updateInterval > 0 )
	{
		// the user wants us to auto-update:
		// do so once every 'specified interval'
		NSString *lastUpdatePath = [dataPath stringByAppendingPathComponent:@"lastUpdate"];
		NSString *lastUpdateStr = [NSString stringWithContentsOfFile:lastUpdatePath encoding:NSUTF8StringEncoding error:NULL];
		CGFloat lastUpdate = [lastUpdateStr floatValue];
		CGFloat now = (CGFloat)[[NSDate date] timeIntervalSinceReferenceDate];
		if ( (now - lastUpdate) > updateInterval ) // this will still be true if the file wasn't found :-)
		{
			m_downloadReallyRecentStuff = YES; // get the latest and greatest :-)
			shouldReDownload = YES;
		}
	}
	
	// Read cached data in: this also starts a download if cache is invalid!
	{
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																			selector:@selector(readBillDataFromCache:) 
																			  object:self];
		
		// Add the operation to the internal operation queue managed by the application delegate.
		[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
		
		[theOp release];
	}
	
	if ( shouldReDownload ) // || ![[NSFileManager defaultManager] fileExistsAtPath:cachePath] )
	{
		// we need to start a data download!
		m_billDownloadPage = 1;
		[self beginBillSummaryDownload];
	}
}


- (void)loadDataByDownload:(BOOL)removeCache
{
	if ( removeCache )
	{
		[self clearData];
		[[NSFileManager defaultManager] removeItemAtPath:[BillsDataManager dataCachePath] error:NULL];
		
		m_downloadReallyRecentStuff = NO;
	}
	else
	{
		m_downloadReallyRecentStuff = YES;
	}
	m_billDownloadPage = 1;
	[self beginBillSummaryDownload];
}


- (NSInteger)totalBills
{
	//return ([self houseBills] + [self senateBills]);
	return [m_billData count];
}


- (BillContainer *)billWithIdentifier:(NSString *)billIdent
{
	return [m_billData objectForKey:billIdent];
}


- (NSInteger)houseBills
{
	NSInteger numBills = 0;
	
	NSEnumerator *henum = [m_houseBills objectEnumerator];
	id obj;
	while ( obj = [henum nextObject] )
	{
		numBills += [obj count];
	}
	
	return numBills;
}


- (NSInteger)houseBillSections
{
	return [m_houseSections count];
}


- (NSInteger)houseBillsInSection:(NSInteger)section
{
	if ( section >= [m_houseSections count] ) return 0;
	return [[m_houseBills objectForKey:[m_houseSections objectAtIndex:section]] count];
}


- (NSString *)houseSectionTitle:(NSInteger)section
{
	if ( section >= [m_houseSections count] ) return nil;
	
	NSNumber *key = [m_houseSections objectAtIndex:section];
	NSInteger year = 3000 - ([key integerValue] >> 5);
	NSInteger month = 12 - ([key integerValue] & 0x1F);
	{
		// return the name of the month in which these 
		// bills were last acted upon
		
		NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
		
		NSString *title = [NSString stringWithFormat:@"%@ %4d",
										[[dateFmt monthSymbols] objectAtIndex:(month-1)],
										year
						   ];
		return title;
	}
}


- (BillContainer *)houseBillAtIndexPath:(NSIndexPath *)indexPath
{
	if ( indexPath.section >= [m_houseSections count] ) return nil;
	
	NSArray *monthBills = [m_houseBills objectForKey:[m_houseSections objectAtIndex:indexPath.section]];
	if ( indexPath.row >= [monthBills count] ) return nil;
	
	return [monthBills objectAtIndex:indexPath.row];
}


- (NSInteger)senateBills
{
	NSInteger numBills = 0;
	
	NSEnumerator *henum = [m_senateBills objectEnumerator];
	id obj;
	while ( obj = [henum nextObject] )
	{
		numBills += [obj count];
	}
	
	return numBills;
}


- (NSInteger)senateBillSections
{
	return [m_senateSections count];
}


- (NSInteger)senateBillsInSection:(NSInteger)section
{
	if ( section >= [m_senateSections count] ) return 0;
	return [[m_senateBills objectForKey:[m_senateSections objectAtIndex:section]] count];
}


- (NSString *)senateSectionTitle:(NSInteger)section
{
	if ( section >= [m_senateSections count] ) return nil;
	
	NSNumber *key = [m_senateSections objectAtIndex:section];
	NSInteger year = 3000 - ([key integerValue] >> 5);
	NSInteger month = 12 - ([key integerValue] & 0x1F);
	{
		// return the name of the month in which these 
		// bills were last acted upon
		
		NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
		
		NSString *title = [NSString stringWithFormat:@"%@ %4d",
						   [[dateFmt monthSymbols] objectAtIndex:(month-1)],
						   year
						   ];
		return title;
	}
}


- (BillContainer *)senateBillAtIndexPath:(NSIndexPath *)indexPath
{
	if ( indexPath.section >= [m_senateSections count] ) return nil;
	
	NSArray *monthBills = [m_senateBills objectForKey:[m_senateSections objectAtIndex:indexPath.section]];
	if ( indexPath.row >= [monthBills count] ) return nil;
	
	return [monthBills objectAtIndex:indexPath.row];
}


- (void)searchForBillsLike:(NSString *)searchText
{
	// 
	// NOTE: This is _completely_ blocking!
	// 
	
	m_currentSearchString = [[searchText retain] autorelease];
	
	// wait up to 30 seconds for congress data
	while ( ![[myGovAppDelegate sharedCongressData] isDataAvailable] )
	{
		static const CGFloat SLEEP_INTERVAL = 0.5f;
		static const CGFloat MAX_SLEEP_TIME = 30.0f;
		CGFloat sleepTime = 0.0f;
		[NSThread sleepForTimeInterval:SLEEP_INTERVAL];
		sleepTime += SLEEP_INTERVAL;
		if ( sleepTime > MAX_SLEEP_TIME ) break;
	}
	
	if ( ![[myGovAppDelegate sharedCongressData] isDataAvailable] )
	{
		return;
	}
	
	NSString *searchUrlStr = [DataProviders OpenCongress_BillQueryURL:searchText];
	NSURL *searchURL = [NSURL URLWithString:searchUrlStr];
	
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:searchURL];
	
	if ( nil == xmlParser ) return;
	
	BillSummaryXMLParser *bsxp = [[BillSummaryXMLParser alloc] initWithBillsData:self];
	[bsxp setNotifyTarget:nil andSelector:nil];
	
	if ( nil == bsxp ) return;
	
	m_searching = YES;
	
	[m_searchResults release];
	m_searchResults = [[NSMutableArray alloc] initWithCapacity:10];
	
	[xmlParser setDelegate:bsxp];
	[xmlParser parse];
	
	m_searching = NO;
}


- (NSString *)currentSearchString
{
	return m_currentSearchString;
}


- (NSInteger)numSearchResults
{
	return [m_searchResults count];
}


- (BillContainer *)searchResultAtIndexPath:(NSIndexPath *)indexPath
{
	if ( indexPath.row >= [m_searchResults count] ) return nil;
	
	return [m_searchResults objectAtIndex:indexPath.row];
}


#pragma BillsDataManager Private 


- (void)beginBillSummaryDownload
{
	if ( isDownloading ) return;
	
	isDownloading = YES;
	isBusy = YES;
	
	// make sure we have congress data before downloading bill data - 
	// this ensures that we grab the right congressional session!
	if ( ![[myGovAppDelegate sharedCongressData] isDataAvailable] )
	{
		[self setStatus:@"Waiting for congress data..."];
		
		// start a timer that will periodically check to see if
		// congressional data is ready... no this is not the most
		// efficient way of doing this...
		if ( nil == m_timer )
		{
			m_timer = [NSTimer timerWithTimeInterval:0.75 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
			[[NSRunLoop mainRunLoop] addTimer:m_timer forMode:NSDefaultRunLoopMode];
		}
		return;
	}
	
	[self setStatus:@"Preparing Bill Download..."];
	
	// This yields _so_ much noise it's not worth it:
	// use the default OpenCongress set of bills...
	NSString *xmlURL;
	NSDateComponents *dateComps = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) 
																  fromDate:[NSDate date]];
	
	// Determine the number of pages (number of months this year)
	if ( 0 == s_maxBillPages )
	{
		NSInteger currentMonth = [dateComps month];
		s_maxBillPages = currentMonth + 1;
		
		/* elections are held in even years, so if we're in an odd year: 
		   add 1 page for each of the previous year's months :-) */
		if ( !([dateComps year] & 0x1) ) s_maxBillPages += 12; 
	}
	
	// Use [DataProviders OpenCongress_BillsURLIntroducedSinceDate:];
	// 
	// Gather up to 30 bills from the current month
	// (users can search for other bills)
	// 
	NSDate *startDate = nil;
	if ( 1 == m_billDownloadPage )
	{
		NSInteger currentYear = [dateComps year];
		NSDateComponents *comps = [[NSDateComponents alloc] init];
		[comps setDay:1];
		[comps setMonth:s_maxBillPages-m_billDownloadPage];
		[comps setYear:currentYear];
		NSCalendar *gregorian = [[NSCalendar alloc]
								 initWithCalendarIdentifier:NSGregorianCalendar];
		startDate = [gregorian dateFromComponents:comps];
		[comps release];
		
		xmlURL = [DataProviders OpenCongress_BillsURLIntroducedSinceDate:startDate onPage:1];
	}
	else if ( m_downloadReallyRecentStuff && m_billDownloadPage >= s_maxBillPages )
	{
		// download _really_ recent stuff!
		static const CGFloat S_A_WEEK_OF_SECONDS = 604800.0f;
		dateComps = [[NSCalendar currentCalendar] components:(NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit) 
													fromDate:[[NSDate date] addTimeInterval:-S_A_WEEK_OF_SECONDS]];
		NSDateComponents *comps = [[NSDateComponents alloc] init];
		[comps setDay:[dateComps day]];
		[comps setMonth:[dateComps month]];
		[comps setYear:[dateComps year]];
		NSCalendar *gregorian = [[NSCalendar alloc]
								 initWithCalendarIdentifier:NSGregorianCalendar];
		startDate = [gregorian dateFromComponents:comps];
		[comps release];
		
		xmlURL = [DataProviders OpenCongress_BillsURLIntroducedSinceDate:startDate onPage:1];
	}
	else
	{
		xmlURL = [DataProviders OpenCongress_BillsURLOnPage:m_billDownloadPage-1];
	}
	
	m_billsDownloaded = 0;
	m_billDownloadPage++;
	
	if ( nil != m_xmlParser )
	{
		// abort any previous attempt at parsing/downloading
		[m_xmlParser abort];
	}
	else
	{
		m_xmlParser = [[XMLParserOperation alloc] initWithOpDelegate:self];
	}
	m_xmlParser.m_opDelegate = self;
	
	BillSummaryXMLParser *bsxp = [[BillSummaryXMLParser alloc] initWithBillsData:self];
	[bsxp setNotifyTarget:m_notifyTarget andSelector:m_notifySelector];
	
	[m_xmlParser parseXML:[NSURL URLWithString:xmlURL] withParserDelegate:bsxp];
	[bsxp release];
}


- (void)writeBillDataToCache:(id)sender
{	
	NSString *dataPath = [BillsDataManager dataCachePath];
	
	while ( isReadingCache || isDownloading )
	{
		[NSThread sleepForTimeInterval:0.5f];
	}
	
	// make sure the directoy exists!
	[[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:YES attributes:nil error:NULL];
	
	// temporary array to store bill dictionary entries
	NSMutableArray *billData = [[NSMutableArray alloc] initWithCapacity:[m_houseBills count]];
	BOOL wroteAtLeastOneCacheFile = FALSE;
	
	{
		// 
		// save house bills
		// 
		NSArray *sections = [m_houseSections sortedArrayUsingSelector:@selector(compare:)];
		NSEnumerator *monthEnum = [sections objectEnumerator];
		NSString *monthKey;
		while ( monthKey = [monthEnum nextObject] )
		{
			NSArray *monthBills = [m_houseBills objectForKey:monthKey];
			NSEnumerator *me = [monthBills objectEnumerator];
			BillContainer *bc; // bill container
			while ( bc = [me nextObject] )
			{
				NSDictionary *billDict = nil;
				@try 
				{
					billDict = [bc getBillDictionaryForCache];
					[billData addObject:billDict];	
				}
				@catch (NSException * e) 
				{
					NSLog(@"Bill[%@] exception: %@",[bc getShortTitle],[e reason]);
				}
				@finally 
				{
					[billDict release];
				}
			}
			
			// if there is more than 1 bill in this month, save the data
			if ( [billData count] > 0 )
			{
				// store the file
				NSString *cacheFilePath = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_h.cache",monthKey]];
				BOOL success = [billData writeToFile:cacheFilePath atomically:YES];
				wroteAtLeastOneCacheFile = success || wroteAtLeastOneCacheFile;
			}
			// clear data for the next month 
			[billData removeAllObjects];
		}
		
		// 
		// save senate bills
		// 
		sections = [m_senateSections sortedArrayUsingSelector:@selector(compare:)];
		monthEnum = [sections objectEnumerator];
		while ( monthKey = [monthEnum nextObject] )
		{
			NSArray *monthBills = [m_senateBills objectForKey:monthKey];
			NSEnumerator *me = [monthBills objectEnumerator];
			id bc; // bill container
			while ( bc = [me nextObject] )
			{
				NSDictionary *billDict = nil;
				@try 
				{
					billDict = [bc getBillDictionaryForCache];
					[billData addObject:billDict];	
				}
				@catch (NSException * e) 
				{
					NSLog(@"Bill[%@] exception: %@",[bc getShortTitle],[e reason]);
				}
				@finally 
				{
					[billDict release];
				}
			}
			
			// if there is more than 1 bill in this month, save the data
			if ( [billData count] > 0 )
			{
				// store the file
				NSString *cacheFilePath = [dataPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@_s.cache",monthKey]];
				BOOL success = [billData writeToFile:cacheFilePath atomically:YES];
				wroteAtLeastOneCacheFile = success || wroteAtLeastOneCacheFile;
			}
			// clear data for the next month 
			[billData removeAllObjects];
		}
	}
	
	[billData release];
	
	// write out the current date to a file to indicate the last time
	// we updated this database
	if ( wroteAtLeastOneCacheFile )
	{
		NSString *lastUpdatePath = [dataPath stringByAppendingPathComponent:@"lastUpdate"];
		NSString *lastUpdate = [NSString stringWithFormat:@"%0f",[[NSDate date] timeIntervalSinceReferenceDate]];
		BOOL success = [lastUpdate writeToFile:lastUpdatePath atomically:YES encoding:NSMacOSRomanStringEncoding error:NULL];
		if ( !success )
		{
			NSLog( @"Successfully wrote cache, but couldnt' write 'lastUpdate' file (may re-download bill data)" );
		}
	}
	
	// not busy any more!
	isBusy = NO;
}


- (void)readBillDataFromCache:(id)sender
{
	if ( isReadingCache ) return;
	
	isReadingCache = YES;
	isBusy = YES;
	
	// we're in a worker thread, so we can block like this:
	// wait until the congressional data loads!
	while ( ![[myGovAppDelegate sharedCongressData] isDataAvailable] )
	{
		[NSThread sleepForTimeInterval:0.2f];
	}
	
	isReadingCache = YES;
	[self setStatus:@"Reading Cached Bills..."];
	
	// Read in bill caches by month 
	NSString *billDataPath = [BillsDataManager dataCachePath];
	NSMutableArray *cacheFiles = [[[NSMutableArray alloc] initWithCapacity:12] autorelease];
	NSString *file;
	
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:billDataPath];
	while ( file = [dirEnum nextObject] ) 
	{
		NSString *fullPath = [billDataPath stringByAppendingPathComponent:file];
		if ( [[file pathExtension] isEqualToString: @"cache"] ) 
		{
			if ( [[file lastPathComponent] isEqualToString:@"bills.cache"] )
			{
				// remove old-style cache file
				[[NSFileManager defaultManager] removeItemAtPath:fullPath error:NULL];
			}
			else 
			{
				[cacheFiles addObject:fullPath];	
			}
		}
	}
	
	// if there are no ".cache" files in the cache path - start a data download
	if ( [cacheFiles count] < 1 )
	{
		if ( !isDownloading )
		{
			isBusy = NO;
			isDataAvailable = NO;
			[self clearData];
			m_billDownloadPage = 1;
			[self beginBillSummaryDownload];
		}
		isReadingCache = NO;
		return;
	}
	
	// open each cache file and read in the bill data 
	NSInteger billsAdded = 0;
	NSEnumerator *cacheEnum = [cacheFiles objectEnumerator];
	while ( file = [cacheEnum nextObject] )
	{
		NSArray *billData = [NSArray arrayWithContentsOfFile:file];
		if ( nil == billData )
		{
			// remove this invalid cache file!
			NSLog(@"Removing invalid bill cache file: %@",[file lastPathComponent]);
			[[NSFileManager defaultManager] removeItemAtPath:file error:NULL];
		}
		else 
		{
			[self setStatus:[NSString stringWithFormat:@"Loading %@...",[file lastPathComponent]]];
			
			NSEnumerator *e = [billData objectEnumerator];
			id billDict;
			while ( billDict = [e nextObject] )
			{
				BillContainer *bc = [[BillContainer alloc] initWithDictionary:billDict];
				if ( nil != bc )
				{
					[self addNewBill:bc checkForDuplicates:YES];
					[bc release];
					++billsAdded;
				}
			} // while ( billDict )
			
			if ( billsAdded > 0 ) isDataAvailable = YES;
		} // billData != nil
	} // while ( file = [cacheEnum nextObject] )
	
	isBusy = (isDownloading ? YES : NO);
	isDataAvailable = (billsAdded > 0) ? YES : NO;
	isReadingCache = NO;
	
	[self setStatus:@"END"];
}


- (void)setStatus:(NSString *)status
{
	[m_currentStatusMessage setString:status];
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:m_currentStatusMessage];
	}
}


- (void)addNewBill:(BillContainer *)bill checkForDuplicates:(BOOL)checkDuplicates
{
	NSMutableDictionary *chamberDict;
	NSMutableArray *chamberSections;
	if ( m_searching )
	{
		[m_searchResults addObject:bill];
		return;
	}
	else
	{
		switch ( bill.m_type ) 
		{
			default:
			case eBillType_h:
			case eBillType_hj:
			case eBillType_hc:
			case eBillType_hr:
				chamberDict = m_houseBills;
				chamberSections = m_houseSections;
				break;
			case eBillType_s:
			case eBillType_sj:
			case eBillType_sc:
			case eBillType_sr:
				chamberDict = m_senateBills;
				chamberSections = m_senateSections;
				break;
		}
	}
	
	NSInteger yearMonth = NSYearCalendarUnit | NSMonthCalendarUnit;
	NSDateComponents *keyComp = [[NSCalendar currentCalendar] components:yearMonth fromDate:[bill lastActionDate]];
	
	// create an integer key value from the month and year that can 
	// be used not only as a dictionay key, but also an easy sorting mechanism
	NSInteger keyVal = ((3000 - [keyComp year]) << 5) | ((12 - [keyComp month]) & 0x1F);
	NSNumber *key = [NSNumber numberWithInt:keyVal];
	NSMutableArray *monthArray = [chamberDict objectForKey:key];
	if ( nil == monthArray )
	{
		// This is a new month - add it to the dictionary, and update our section list
		monthArray = [[NSMutableArray alloc] initWithCapacity:20];
		[chamberDict setValue:monthArray forKey:(id)key];
		[chamberSections addObject:key];
		[chamberSections sortUsingSelector:@selector(compare:)];
	}
	else
	{
		[monthArray retain];
	}
	
	++m_billsDownloaded;
	
	// search through the array for a matching bill
	// to avoid duplicates!
	if ( checkDuplicates )
	{
		NSEnumerator *e = [monthArray objectEnumerator];
		id b;
		while ( b = [e nextObject] )
		{
			if ( [b m_id] == bill.m_id )
			{
				// duplicate: release the monthArray reference,
				// and get out of here
				[monthArray release];
				return;
			}
		}
	}
	
	[monthArray addObject:bill];
	[monthArray sortUsingSelector:@selector(lastActionDateCompare:)];
	
	[monthArray release];
	
	// also add this bill to our global hash of bills
	[m_billData setValue:bill forKey:[bill getIdent]];
}


- (void)clearData
{
	[m_houseSections release];
	[m_houseBills release];
	[m_senateSections release];
	[m_senateBills release];
	[m_billData release];
	
	m_billData = [[NSMutableDictionary alloc] initWithCapacity:24];
	m_houseSections = [[NSMutableArray alloc] initWithCapacity:12];
	m_houseBills = [[NSMutableDictionary alloc] initWithCapacity:12];
	m_senateSections = [[NSMutableArray alloc] initWithCapacity:12];
	m_senateBills = [[NSMutableDictionary alloc] initWithCapacity:12];
	
	m_billsDownloaded = 0;
}


- (void)timerFireMethod:(NSTimer *)timer
{
	if ( timer != m_timer ) return;
	
	CongressDataManager *cdm = [myGovAppDelegate sharedCongressData];
	if ( (nil != cdm) && ([cdm isDataAvailable]) )
	{
		// stop this timer, and start downloading some spending data!
		[timer invalidate];
		m_timer = nil;
		
		[self setStatus:@"Downloading bill data..."];
		
		m_billDownloadPage = 1;
		[self beginBillSummaryDownload];
	}
}


#pragma mark XMLParserOperationDelegate Methods


- (void)xmlParseOpStarted:(XMLParserOperation *)parseOp
{
	[self setStatus:[NSString stringWithFormat:@"Downloading Bill Data (%0d/%0d)...",(m_billDownloadPage-1),s_maxBillPages-1]];
	//NSLog( @"BillsDataManager started XML download for page %0d of %0d...", m_billDownloadPage-1, s_maxBillPages-1 );
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	isDownloading = NO;
	
	if ( m_downloadReallyRecentStuff && 
		 (m_billDownloadPage > s_maxBillPages) 
		)
	{
		// only allow this to happen once :-)
		m_downloadReallyRecentStuff = NO;
	}
	
	// we received the maximum number of bills - there might be more!
	// (don't go above a maximum numbe of pages)
	if ( m_downloadReallyRecentStuff ||
		 (m_billDownloadPage <= s_maxBillPages) ||
		 (m_billDownloadPage < (s_maxBillPages+2) && (m_billsDownloaded >= [DataProviders OpenCongress_MaxBillsReturned]))
	   ) 
	{
		// start another download !
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																			selector:@selector(beginBillSummaryDownload) 
																			  object:nil];
		
		// Add the operation to the internal operation queue managed by the application delegate.
		[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
		
		[theOp release];
		
		return;
	}
	
skip_newdownload:
	isDataAvailable = success || isDataAvailable;
	
	[self setStatus:@"END"];
	
	//NSLog( @"BillsDataManager XML parsing ended %@", (success ? @"successfully." : @" in failure!") );
	
	if ( isDataAvailable )
	{
		// archive the bill summary data !
		isBusy = YES; // we're writing the cache!
		
		// kick off the caching of this data
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																	  selector:@selector(writeBillDataToCache:) object:self];
		
		// Add the operation to the internal operation queue managed by the application delegate.
		[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
		
		[theOp release];
	}
	else
	{
		isBusy = NO;
	}
	
}


@end

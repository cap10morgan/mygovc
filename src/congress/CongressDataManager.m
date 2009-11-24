/*
 File: CongressDataManager.m
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

#import <Foundation/NSXMLParser.h>
#import "myGovAppDelegate.h"

#import "CongressDatabaseParser.h"
#import "CongressDataManager.h"
#import "CongressionalCommittees.h"
#import "CongressLocationParser.h"
#import "DataProviders.h"
#import "LegislatorContainer.h"
#import "XMLParserOperation.h"


@interface CongressDataManager (private)
	- (void)setStatus:(NSString *)status;
	- (void)destroyDataCache;
	- (void)discoverCurrentCongressSession;
	- (void)beginDataDownload;
	- (void)initFromDisk:(id)sender;
	- (void)setCurrentState:(NSString *)stateAbbr andDistrict:(NSUInteger)district;
	- (void)addLegislatorToInMemoryCache:(id)legislator release:(BOOL)flag;
	- (NSMutableArray *)states_mut;
	- (NSDictionary *)districtDictionary;
@end


@implementation CongressDataManager

@synthesize isDataAvailable;
@synthesize isBusy;
@synthesize isAnyDataCached;


// [KEY:state_district] -> [VALUE:legislator_container]
static NSMutableDictionary *s_districts = NULL;

static NSString *kTitleValue_Senator = @"Sen";



+ (NSString *)dataCachePath
{
	NSString *congressDataPath = [[myGovAppDelegate sharedAppCacheDir] stringByAppendingPathComponent:@"congress"];
	return congressDataPath;
}


- (id)initWithNotifyTarget:(id)target andSelector:(SEL)sel
{
	if ( self = [super init] )
	{
		isDataAvailable = NO;
		
		[self setNotifyTarget:target withSelector:sel];
		
		m_currentStatusMessage = [[NSMutableString alloc] init];
		m_currentSearchString = nil;
		
		// initialize states/house/senate arrays
		m_states = [[NSMutableArray alloc] initWithCapacity:60];
		m_house = [[NSMutableDictionary alloc] initWithCapacity:60];
		m_senate = [[NSMutableDictionary alloc] initWithCapacity:60];
		m_searchArray = nil;
		
		m_xmlParser = nil;
		m_currentCongressSession = 0;
		m_committees = [[CongressionalCommittees alloc] init];
		
		// check to see if we have congress data previously cached on this 
		// device - if we don't then we'll have to go fetch it!
		NSString *congressDataValidPath = [[CongressDataManager dataCachePath] stringByAppendingPathComponent:@"dataComplete"];
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:congressDataValidPath] )
		{
			// we need to start a data download!
			isAnyDataCached = NO;
			[self beginDataDownload];
		}
		else
		{
			isAnyDataCached = YES;
			// data is available - read disk data into memory (via a worker thread)
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		  selector:@selector(initFromDisk:) object:self];
			
			// Add the operation to the internal operation queue managed by the application delegate.
			[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
			
			[theOp release];
		}
	}
	return self;
}


- (void)dealloc
{
	isDataAvailable = NO;
	isBusy = YES;
	
	[m_xmlParser abort];
	[m_xmlParser release];
	
	[m_notifyTarget release];
	[m_states release];
	[m_house release];
	[m_senate release];
	[m_searchArray release];
	[m_committees release];
	
	[m_currentString release];
	[m_currentStatusMessage release];
	[m_currentSearchString release];
	
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


- (NSInteger)currentCongressSession
{
	return m_currentCongressSession;
}


- (NSArray *)states
{
	return (NSArray *)m_states;
}


- (NSArray *)houseMembersInState:(NSString *)state
{
	return (NSArray *)[m_house objectForKey:state];
}


- (NSArray *)senateMembersInState:(NSString *)state
{
	return (NSArray *)[m_senate objectForKey:state];
}


- (void)setSearchString:(NSString *)string
{
	[m_searchArray release]; m_searchArray = nil;
	[m_currentSearchString release]; m_currentSearchString = nil;
	if ( 0 == [string length] ) return;
	m_currentSearchString = [[NSString alloc] initWithString:string];
	
	// build a new search array
	m_searchArray = [[NSMutableArray alloc] initWithCapacity:10];
	
	// see if this search string is a committee key
	NSArray *committeeMembers = [m_committees legislatorsInCommittee:m_currentSearchString];
	if ( nil != committeeMembers )
	{
		NSEnumerator *cmEnum = [committeeMembers objectEnumerator];
		NSString *legGovTrackID;
		while ( legGovTrackID = [cmEnum nextObject] )
		{
			[m_searchArray addObject:[self getLegislatorFromGovtrackID:legGovTrackID]];
		}
		[m_searchArray sortUsingSelector:@selector(districtCompare:)];
		
		return;
	}
	
	// this is a district specification - build the search list quick and easy :-)
	if ( [string length] == 4 && [[string substringFromIndex:2] integerValue] > 0 )
	{
		// XXX - fix for At-Large districts...
		
		NSString *state = [[string substringToIndex:2] uppercaseString];
		
		// representative
		LegislatorContainer *lc = [self districtRepresentative:[string uppercaseString]]; 
		if ( nil != lc ) [m_searchArray addObject:lc];
		
		// senators
		NSArray *senators = [m_senate objectForKey:state];
		NSEnumerator *senum = [senators objectEnumerator];
		id legislator;
		while ( legislator = [senum nextObject] )
		{
			[m_searchArray addObject:legislator];
		}
		
		return;
	}
	
	// linearly search the house data
	NSEnumerator *houseEnum = [m_house objectEnumerator];
	id state;
	id legislator;
	while ( state = [houseEnum nextObject] ) 
	{
		NSEnumerator *legEnum = [state objectEnumerator];
		while ( legislator = [legEnum nextObject] )
		{
			if ( [legislator isSimilarToo:string] )
			{
				[m_searchArray addObject:legislator];
			}
		}
	}
	
	NSEnumerator *senateEnum = [m_senate objectEnumerator];
	while ( state = [senateEnum nextObject] ) 
	{
		NSEnumerator *legEnum = [state objectEnumerator];
		while ( legislator = [legEnum nextObject] )
		{
			if ( [legislator isSimilarToo:string] )
			{
				[m_searchArray addObject:legislator];
			}
		}
	}
}


- (void)setSearchLocation:(CLLocation *)loc
{
	[m_searchArray release]; m_searchArray = nil;
	
	NSString *searchStr = [DataProviders Govtrack_DistrictURLFromLocation:loc];
	
	if ( nil != m_xmlParser )
	{
		// abort any previous attempt at parsing/downloading
		[m_xmlParser abort];
	}
	else
	{
		m_xmlParser = [[XMLParserOperation alloc] initWithOpDelegate:self];
	}
	m_xmlParser.m_opDelegate = nil;
	
	CongressLocationParser *clxp = [[CongressLocationParser alloc] initWithCongressData:self];
	[clxp setNotifyTarget:m_notifyTarget andSelector:m_notifySelector];
	
	[m_xmlParser parseXML:[NSURL URLWithString:searchStr] withParserDelegate:clxp];
	[clxp release];
}


- (void)setSearchZip:(NSString *)zip
{
	[m_searchArray release]; m_searchArray = nil;
	
	NSString *searchStr = [DataProviders Govtrack_DistrictURLFromZip:zip];
	
	if ( nil != m_xmlParser )
	{
		// abort any previous attempt at parsing/downloading
		[m_xmlParser abort];
	}
	else
	{
		m_xmlParser = [[XMLParserOperation alloc] initWithOpDelegate:self];
	}
	m_xmlParser.m_opDelegate = nil;
	
	CongressLocationParser *clxp = [[CongressLocationParser alloc] initWithCongressData:self];
	[clxp setNotifyTarget:m_notifyTarget andSelector:m_notifySelector];
	
	[m_xmlParser parseXML:[NSURL URLWithString:searchStr] withParserDelegate:clxp];
	[clxp release];
}


- (NSArray *)searchResultsArray
{
	return (NSArray *)m_searchArray;
}


- (NSString *)currentSearchString
{
	return m_currentSearchString;
}


- (LegislatorContainer *)getLegislatorFromBioguideID:(NSString *)bioguideid
{
	// XXX - Linear search... maybe speed this up someday?
	
	// house data
	NSEnumerator *houseEnum = [m_house objectEnumerator];
	id state;
	id legislator;
	while ( state = [houseEnum nextObject] ) 
	{
		NSEnumerator *legEnum = [state objectEnumerator];
		while ( legislator = [legEnum nextObject] )
		{
			if ( [[legislator bioguide_id] isEqualToString:bioguideid] )
			{
				return (LegislatorContainer *)legislator;
			}
		}
	}
	
	// senate data
	NSEnumerator *senateEnum = [m_senate objectEnumerator];
	while ( state = [senateEnum nextObject] ) 
	{
		NSEnumerator *legEnum = [state objectEnumerator];
		while ( legislator = [legEnum nextObject] )
		{
			if ( [[legislator bioguide_id] isEqualToString:bioguideid] )
			{
				return (LegislatorContainer *)legislator;
			}
		}
	}
	
	return nil;
}


- (LegislatorContainer *)getLegislatorFromGovtrackID:(NSString *)govtrackID
{
	// XXX - Linear search... maybe speed this up someday?
	
	// house data
	NSEnumerator *houseEnum = [m_house objectEnumerator];
	id state;
	id legislator;
	while ( state = [houseEnum nextObject] ) 
	{
		NSEnumerator *legEnum = [state objectEnumerator];
		while ( legislator = [legEnum nextObject] )
		{
			if ( [[legislator govtrack_id] isEqualToString:govtrackID] )
			{
				return (LegislatorContainer *)legislator;
			}
		}
	}
	
	// senate data
	NSEnumerator *senateEnum = [m_senate objectEnumerator];
	while ( state = [senateEnum nextObject] ) 
	{
		NSEnumerator *legEnum = [state objectEnumerator];
		while ( legislator = [legEnum nextObject] )
		{
			if ( [[legislator govtrack_id] isEqualToString:govtrackID] )
			{
				return (LegislatorContainer *)legislator;
			}
		}
	}
	
	return nil;
}


- (NSArray *)congressionalDistricts
{
	NSDictionary *districtDict = [self districtDictionary];
	if ( nil == districtDict ) return nil;
	
	NSArray * dists = [[districtDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)];
	return dists;
}


- (LegislatorContainer *)districtRepresentative:(NSString *)district
{
	NSDictionary *districtDict = [self districtDictionary];
	if ( nil == districtDict ) return nil;
	
	return [districtDict objectForKey:district];
}


- (NSArray *)legislatorCommittees:(LegislatorContainer *)legislator
{
	return [m_committees getCommitteeDataFor:legislator];
}


- (void)writeLegislatorDataToCache:(id)sender
{
	isBusy = YES;
	
	NSString *congressDataPath = [[CongressDataManager dataCachePath] stringByAppendingPathComponent:@"data"];
	
	// make sure the directoy exists!
	[[NSFileManager defaultManager] createDirectoryAtPath:congressDataPath withIntermediateDirectories:YES attributes:nil error:NULL];
	
	NSString *path;
	NSString *state;
	
	// write out representative data
	for ( state in m_house )
	{
		// make sure state directory exists!
		NSString *stateDir = [congressDataPath stringByAppendingPathComponent:state];
		[[NSFileManager defaultManager] createDirectoryAtPath:stateDir withIntermediateDirectories:YES attributes:nil error:NULL];
		
		NSArray *reps = [m_house objectForKey:state];
		for ( id legislator in reps )
		{
			// congress/data/[STATE]/[ID].cache
			path = [stateDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.cache",[legislator bioguide_id]]];
			[legislator writeRecordToFile:path];
		}
	}
	
	// write out senate data
	for ( state in m_senate )
	{
		// make sure state directory exists!
		NSString *stateDir = [congressDataPath stringByAppendingPathComponent:state];
		[[NSFileManager defaultManager] createDirectoryAtPath:stateDir withIntermediateDirectories:YES attributes:nil error:NULL];
		
		NSArray *senators = [m_senate objectForKey:state];
		for ( id legislator in senators )
		{
			// congress/data/[STATE]/[ID].cache
			path = [stateDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.cache",[legislator bioguide_id]]];
			[legislator writeRecordToFile:path];
		}
	}
	
	// write out the committee data
	path = [congressDataPath stringByAppendingPathComponent:@"committees.xml"];
	BOOL success = [m_committees writeCommitteeDataToFile:path];
	if ( !success )
	{
		// XXX - what to do?
	}
	
	// create a file named 'dataComplete' to indicate we've
	// written out all of our congressional data
	path = [NSString stringWithFormat:@"%@Complete",congressDataPath];
	success = [[NSFileManager defaultManager] createFileAtPath:path contents:[NSData dataWithBytes:"1" length:1] attributes:nil];
	if ( !success )
	{
		// XXX - what to do?
	}
	
	isAnyDataCached = YES;
	isBusy = NO;
}


- (void)updateCongressData
{
	isDataAvailable = NO;
	isBusy = YES;
	
	[self setStatus:@"Removing Cached Congress Data..."];
	
	[self destroyDataCache];
	
	[s_districts release]; s_districts = NULL;
	
	[m_states release];
	[m_house release];
	[m_senate release];
	[m_committees release];
	m_states = [[NSMutableArray alloc] initWithCapacity:60];
	m_house = [[NSMutableDictionary alloc] initWithCapacity:60];
	m_senate = [[NSMutableDictionary alloc] initWithCapacity:60];
	
	// includes sub-committees...
	m_committees = [[CongressionalCommittees alloc] init];
	
	[self beginDataDownload];
}


#pragma mark CongressDataManager Private


- (void)setStatus:(NSString *)status
{
	[m_currentStatusMessage setString:status];
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:m_currentStatusMessage];
	}
}


- (void)destroyDataCache
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:[CongressDataManager dataCachePath] error:NULL];
	// XXX - do something on failure ?!
}


- (void)discoverCurrentCongressSession
{
	// get current congress session!
	NSString *govTrackDataURL = [DataProviders Govtrack_DataDirURL];
	NSData *govTrackDirData = [[NSData alloc] initWithContentsOfURL:[NSURL URLWithString:govTrackDataURL]];
	NSString *dirListHtmlStr = [[NSString alloc] initWithData:govTrackDirData encoding:NSUTF8StringEncoding];
	
	// we have to stat somewhere :-)
	m_currentCongressSession = 110;
	
	// hacker-parse the HTML string to find the highest number directory
	// link which should correspond to the current session of congress!
	NSRange pos = {0,[dirListHtmlStr length]};
	NSRange anchorPos = [dirListHtmlStr rangeOfString:@"a href=\"" options:NSCaseInsensitiveSearch range:pos];
	while ( anchorPos.length > 0 )
	{
		pos.location = (anchorPos.location + anchorPos.length);
		pos.length = [dirListHtmlStr length] - pos.location;
		// pos is not pointing to the larget of the anchor, 
		// look for the closing quote and chop off the directory slash
		NSRange tgtRange = {pos.location, 5}; // 110/" 
		NSString *targetStr = [dirListHtmlStr substringWithRange:tgtRange];
		if ( [targetStr characterAtIndex:3] == '/' && [targetStr characterAtIndex:4] == '"' )
		{
			// get a number from this - it's a congress session link!
			NSInteger session = [[targetStr substringToIndex:3] integerValue];
			if ( session > m_currentCongressSession ) m_currentCongressSession = session;
		}
		
		anchorPos = [dirListHtmlStr rangeOfString:@"a href=\"" options:NSCaseInsensitiveSearch range:pos];
	}
}


- (void)beginDataDownload
{
	isDataAvailable = NO;
	isBusy = YES;
	isAnyDataCached = NO;
	
	[self setStatus:@"Preparing Congress Data Download..."];
	
	NSString *xmlURL = [DataProviders SunlightLabs_LegislatorListURL];
	
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
	
	CongressDatabaseParser *cdxp = [[CongressDatabaseParser alloc] initWithCongressData:self];
	[cdxp setNotifyTarget:m_notifyTarget andSelector:m_notifySelector];
	
	[m_xmlParser parseXML:[NSURL URLWithString:xmlURL] withParserDelegate:cdxp];
	[cdxp release];
}


- (void)initFromDisk:(id)sender
{
	isDataAvailable = NO;
	[self setStatus:@"Reading cached data..."];
	
	NSString *congressDataPath = [[CongressDataManager dataCachePath] stringByAppendingPathComponent:@"data"];
	
	// read data from /Library/Caches/congress/...
	NSFileManager *fileManager = [NSFileManager defaultManager];
	NSDirectoryEnumerator *dirEnum = [fileManager enumeratorAtPath:congressDataPath];
	NSString *file;
	BOOL isDir;
	while ( file = [dirEnum nextObject] ) 
	{
		if ( [[file pathExtension] isEqualToString: @"cache"] ) 
		{
			m_currentLegislator = [[LegislatorContainer alloc] initFromFile:[congressDataPath stringByAppendingPathComponent:file]];
			[self addLegislatorToInMemoryCache:m_currentLegislator release:YES];
		}
		else if ( [fileManager fileExistsAtPath:[congressDataPath stringByAppendingPathComponent:file] isDirectory:&isDir] && isDir )
		{
			// directory entries are state names :-)
			//file = [file lastPathComponent];
			if ( ![m_states containsObject:file] )
			{
				[m_states addObject:file];
			}
			[m_states sortUsingSelector:@selector(caseInsensitiveCompare:)];
		}
	}
	
	// read committee data (and current congress session) from disk
	file = [congressDataPath stringByAppendingPathComponent:@"committees.xml"];
	[m_committees initCommitteeDataFromFile:file];
	
	m_currentCongressSession = [m_committees congressSession];
	
	isDataAvailable = YES;
	[self setStatus:@"END"];
	
	//NSLog( @"CongressDataManager cached data parsing complete." );
}


- (void)setCurrentState:(NSString *)stateAbbr andDistrict:(NSUInteger)district
{
	[m_searchArray release]; m_searchArray = nil;
	m_searchArray = [[NSMutableArray alloc] initWithCapacity:3];
	
	[m_currentSearchString release];
	m_currentSearchString = [[NSString alloc] initWithFormat:@"%@%02d",stateAbbr,district];
	
	// linearly search the house members in the current state
	NSEnumerator *houseEnum = [[self houseMembersInState:stateAbbr] objectEnumerator];
	id legislator;
	while ( legislator = [houseEnum nextObject] ) 
	{
		if ( [[legislator district] integerValue] == district )
		{
			[m_searchArray addObject:legislator];
		}
	}
	
	// add _all_ the senate members for the current state
	NSEnumerator *senateEnum = [[self senateMembersInState:stateAbbr] objectEnumerator];
	while ( legislator = [senateEnum nextObject] ) 
	{
		[m_searchArray addObject:legislator];
	}
	
	[self setStatus:@"LOCTN Search Complete"];
}


- (void)addLegislatorToInMemoryCache:(id)legislator release:(BOOL)flag
{
	LegislatorContainer *lc = legislator;
	
	// add this legislator to an appropriate array
	NSMutableArray *stateArray;
	if ( [[lc title] isEqualToString:kTitleValue_Senator] )
	{
		stateArray = [m_senate objectForKey:[lc state]];
		if ( nil == stateArray ) 
		{
			stateArray = [[NSMutableArray alloc] initWithCapacity:2];
			[m_senate setValue:stateArray forKey:[lc state]];
		}
		else
		{
			[stateArray retain];
		}
	}
	else
	{
		stateArray = [m_house objectForKey:[lc state]];
		if ( nil == stateArray ) 
		{
			stateArray = [[NSMutableArray alloc] initWithCapacity:8];
			[m_house setValue:stateArray forKey:[lc state]];
		}
		else
		{
			[stateArray retain];
		}
	}
	[stateArray addObject:lc];
	[stateArray sortUsingSelector:@selector(districtCompare:)];
	
	[stateArray release];
	
	if ( flag ) [lc release];
}


- (NSMutableArray *)states_mut
{
	return m_states;
}


- (NSDictionary *)districtDictionary
{
	if ( (NULL == s_districts) && isDataAvailable )
	{
		// allocate a new dictionary of district->legislator pairs
		// (cache this shit because a giant linear algorithm through all US district is NOOO GOOD!)
		s_districts = [[NSMutableDictionary alloc] initWithCapacity:490];
		
		// Painfully iterate through
		NSEnumerator *houseEnum = [m_house objectEnumerator];
		id stateArray;
		while ( (stateArray = [houseEnum nextObject]) )
		{
			NSEnumerator *districtEnum = [(NSArray *)stateArray objectEnumerator];
			id legislator;
			while ( (legislator = [districtEnum nextObject]) )
			{
				LegislatorContainer *lc = (LegislatorContainer *)legislator;
				NSString *districtStr = [NSString stringWithFormat:@"%@%.2d",[lc state],[[lc district] integerValue]];
				[s_districts setValue:lc forKey:districtStr];
			} // while (districts)
		} // while ( states )
	}
	return s_districts;
}


#pragma mark XMLParserOperationDelegate Methods


- (void)xmlParseOpStarted:(XMLParserOperation *)parseOp
{
	[self setStatus:@"Downloading Congress Data..."];
	//NSLog( @"CongessDataManager started XML parsing..." );
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	if ( success )
	{
		[self setStatus:@"Downloading Committee Data..."];
		
		[self discoverCurrentCongressSession];
		
		// download the committee data (wait for this...)
		NSString *committeeStr = [DataProviders Govtrack_CommitteeURL:m_currentCongressSession];
		NSURL *committeeURL = [NSURL URLWithString:committeeStr];
		[m_committees downloadDataFrom:committeeURL forCongressSession:m_currentCongressSession];
	}
	
	isDataAvailable = success;
	
	[self setStatus:(success ? @"END" : m_currentString)];
	
	//NSLog( @"CongressDataManager XML parsing ended %@", (success ? @"successfully." : @" in failure!") );
	
	if ( isDataAvailable )
	{
		isBusy = YES; // we're writing the cache!
		
		// kick off the caching of this data
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																			selector:@selector(writeLegislatorDataToCache:) object:self];
		
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

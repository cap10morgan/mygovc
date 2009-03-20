//
//  CongressDataManager.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <Foundation/NSXMLParser.h>
#import "CongressDataManager.h"
#import "LegislatorContainer.h"
#import "CongressionalCommittees.h"
#import "XMLParserOperation.h"
#import "myGovAppDelegate.h"


@interface CongressDataManager (private)
	- (void)destroyDataCache;
	- (void)beginDataDownload;
	- (void)initFromDisk:(id)sender;
	- (void)addLegislatorToInMemoryCache:(id)legislator release:(BOOL)flag;
	- (NSDictionary *)districtDictionary;
@end


@implementation CongressDataManager

@synthesize isDataAvailable;
@synthesize isBusy;

// [KEY:state_district] -> [VALUE:legislator_container]
static NSMutableDictionary *s_districts = NULL;


static NSString *kSunlight_APIKey = @"345973d49743956706bb04030ee5713b";
//static NSString *kPVS_APIKey = @"e9c18da5999464958518614cfa7c6e1c";
static NSString *kOpenCongress_APIKey = @"32aea132a66093e9bf9ebe9fc2e2a4c66b888777";
static NSString *kSunlight_getListXML = @"http://services.sunlightlabs.com/api/legislators.getList.xml";
static NSString *kGovtrack_committeeListXML = @"http://www.govtrack.us/data/us/111/committees.xml";

// Legislator XML key names
static NSString *kName_Response = @"response";
static NSString *kName_Legislator = @"legislator";
static NSString *kName_State = @"state";
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
		
		// initialize states/house/senate arrays
		m_states = [[NSMutableArray alloc] initWithCapacity:50];
		m_house = [[NSMutableDictionary alloc] initWithCapacity:50];
		m_senate = [[NSMutableDictionary alloc] initWithCapacity:50];
		
		m_committees = [[CongressionalCommittees alloc] init];
		
		// check to see if we have congress data previously cached on this 
		// device - if we don't then we'll have to go fetch it!
		NSString *congressDataValidPath = [[CongressDataManager dataCachePath] stringByAppendingPathComponent:@"dataComplete"];
		if ( ![[NSFileManager defaultManager] fileExistsAtPath:congressDataValidPath] )
		{
			// we need to start a data download!
			[self beginDataDownload];
		}
		else
		{
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
	[m_notifyTarget release];
	[m_states release];
	[m_house release];
	[m_senate release];
	[m_committees release];
	[m_xmlParser release];
	[m_currentString release];
	[super dealloc];
}


- (void)setNotifyTarget:(id)target withSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = [target retain];
	m_notifySelector = sel;
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
	
	isBusy = NO;
}


- (void)updateCongressData
{
	isDataAvailable = NO;
	isBusy = YES;
	
	if ( nil != m_notifyTarget )
	{
		NSString *message = [NSString stringWithString:@"Removing Cached Congress Data..."];
		[m_notifyTarget performSelector:m_notifySelector withObject:message];
	}
	
	[self destroyDataCache];
	
	[s_districts release]; s_districts = NULL;
	
	[m_states release];
	[m_house release];
	[m_senate release];
	[m_committees release];
	m_states = [[NSMutableArray alloc] initWithCapacity:50];
	m_house = [[NSMutableDictionary alloc] initWithCapacity:50];
	m_senate = [[NSMutableDictionary alloc] initWithCapacity:50];
	
	// includes sub-committees...
	m_committees = [[CongressionalCommittees alloc] init];
	
	[self beginDataDownload];
}


#pragma mark CongressDataManager Private


- (void)destroyDataCache
{
	NSFileManager *fileManager = [NSFileManager defaultManager];
	[fileManager removeItemAtPath:[CongressDataManager dataCachePath] error:NULL];
	// XXX - do something on failure ?!
}


- (void)beginDataDownload
{
	isDataAvailable = NO;
	isBusy = YES;
	
	if ( nil != m_notifyTarget )
	{
		NSString *message = [NSString stringWithString:@"Downloading Congress Data..."];
		[m_notifyTarget performSelector:m_notifySelector withObject:message];
	}
	
	NSString *xmlURL = [NSString stringWithFormat:@"%@?apikey=%@",kSunlight_getListXML,kSunlight_APIKey];
	
	if ( nil != m_xmlParser )
	{
		// abort any previous attempt at parsing/downloading
		[m_xmlParser abort];
	}
	else
	{
		m_xmlParser = [[XMLParserOperation alloc] initWithOpDelegate:self];
	}
	
	[m_xmlParser parseXML:[NSURL URLWithString:xmlURL] withParserDelegate:self];
}


- (void)initFromDisk:(id)sender
{
	isDataAvailable = NO;
	if ( nil != m_notifyTarget )
	{
		NSString *message = [NSString stringWithString:@"Reading cached data..."];
		[m_notifyTarget performSelector:m_notifySelector withObject:message];
	}
	
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
	
	file = [congressDataPath stringByAppendingPathComponent:@"committees.xml"];
	[m_committees initCommitteeDataFromFile:file];
	
	isDataAvailable = YES;
	if ( nil != m_notifyTarget )
	{
		NSString *message = [NSString stringWithString:@"Finished."];
		[m_notifyTarget performSelector:m_notifySelector withObject:message];
	}
	NSLog( @"CongressDataManager cached data parsing complete." );
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


- (NSDictionary *)districtDictionary
{
	if ( (NULL == s_districts) && isDataAvailable )
	{
		// allocate a new dictionary of district->legislator pairs
		// (cache this shit because a giant linear algorithm through all US district is NOOO GOOD!)
		s_districts = [[NSMutableDictionary alloc] initWithCapacity:480];
		
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
	if ( nil != m_notifyTarget )
	{
		NSString *message = [NSString stringWithString:@"Downloading Congress Data..."];
		[m_notifyTarget performSelector:m_notifySelector withObject:message];
	}
	NSLog( @"CongessDataManager started XML parsing..." );
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	if ( success )
	{
		if ( nil != m_notifyTarget )
		{
			NSString *message = [NSString stringWithString:@"Downloading Committee Data..."];;
			[m_notifyTarget performSelector:m_notifySelector withObject:message];
		}
		// download the committee data (wait for this...)
		[m_committees downloadDataFrom:[NSURL URLWithString:kGovtrack_committeeListXML]];
	}
	
	isDataAvailable = success;
	
	if ( nil != m_notifyTarget )
	{
		NSString *message = [NSString stringWithFormat:@"%@",(success ? @"Finished." : m_currentString)];
		[m_notifyTarget performSelector:m_notifySelector withObject:message];
	}
	NSLog( @"CongressDataManager XML parsing ended %@", (success ? @"successfully." : @" in failure!") );
	
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


#pragma mark XMLParser Delegate Methods


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ( [elementName isEqualToString:kName_Response] )
	{
		if ( nil != m_notifyTarget )
		{
			NSString *message = [NSString stringWithString:@"Parsing data..."];
			[m_notifyTarget performSelector:m_notifySelector withObject:message];
		}
	}
    else if ( [elementName isEqualToString:kName_Legislator] ) 
	{
		parsingLegislator = YES;
		
		// alloc a new Legislator 
		m_currentLegislator = [[LegislatorContainer alloc] init];
    } 
	else if ( parsingLegislator ) 
	{
		m_currentString = [[NSMutableString alloc] initWithString:@""];
        storingCharacters = YES;
    }
	else
	{
		storingCharacters = NO;
		parsingLegislator = NO;
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	storingCharacters = NO;
	if ( [elementName isEqualToString:kName_Legislator] ) 
	{
		parsingLegislator = NO;
		[self addLegislatorToInMemoryCache:m_currentLegislator release:YES];
	}
	else if ( parsingLegislator )
	{
		[m_currentLegislator addKey:elementName withValue:m_currentString];
		
		// Build a dynamic list of states :-)
		if ( [elementName isEqualToString:kName_State] )
		{
			if ( ![m_states containsObject:m_currentString] )
			{
				[m_states addObject:m_currentString];
			}
			[m_states sortUsingSelector:@selector(caseInsensitiveCompare:)];
		}
		
		[m_currentString release];
	}
	else
	{
	}
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
    if ( storingCharacters ) [m_currentString appendString:string];
}


// XXX - handle XML parse errors in some sort of graceful way...
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
	parsingLegislator = NO;
	storingCharacters = NO;
	[m_currentLegislator release];
	[m_currentString release];
	m_currentString = [[NSString alloc] initWithString:@"ERROR XML parsing error"];
	[m_states release]; m_states = nil;
	[m_house release]; m_house = nil;
	[m_senate release]; m_senate = nil;
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	parsingLegislator = NO;
	storingCharacters = NO;
	[m_currentLegislator release];
	[m_currentString release];
	m_currentString = [[NSString alloc] initWithString:@"ERROR XML validation error"];
	[m_states release]; m_states = nil;
	[m_house release]; m_house = nil;
	[m_senate release]; m_senate = nil;
}


/*
– (void)parserDidStartDocument:(NSXMLParser *)parser
{
}

– (void)parserDidEndDocument:(NSXMLParser *)parser
{
}


– (void)parser:(NSXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI
{
}

– (void)parser:(NSXMLParser *)parser didEndMappingPrefix:(NSString *)prefix
{
}

– (void)parser:(NSXMLParser *)parser resolveExternalEntityName:(NSString *)entityName systemID:(NSString *)systemID
{
}

– (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
}


– (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
}

– (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString
{
}

– (void)parser:(NSXMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data
{
}

– (void)parser:(NSXMLParser *)parser foundComment:(NSString *)comment
{
}

– (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{
}
*/

@end

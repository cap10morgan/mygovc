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
#import "XMLParserOperation.h"
#import "myGovAppDelegate.h"

@interface LegislatorContainer (extended)
	-(void)addKey:(NSString *)field withValue:(NSString *)value;
@end


@interface CongressDataManager (private)
	- (void)beginDataDownload;
	- (void)initFromDisk;
@end

@implementation CongressDataManager

@synthesize isDataAvailable;

static NSString *kSunlight_APIKey = @"345973d49743956706bb04030ee5713b";
static NSString *kPVS_APIKey = @"e9c18da5999464958518614cfa7c6e1c";

XMLParserOperation *s_xmlParser;


- (id)init
{
	if ( self = [super init] )
	{
		isDataAvailable = NO;
		
		m_notifyTarget = nil;
		
		// initialize states/house/senate arrays
		m_states = [[NSMutableArray alloc] initWithCapacity:50];
		m_house = [[NSMutableDictionary alloc] initWithCapacity:50];
		m_senate = [[NSMutableDictionary alloc] initWithCapacity:50];
		
		// check to see if we have congress data previously cached on this 
		// device - if we don't then we'll have to go fetch it!
		NSArray *cachePaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
		NSString *cacheDir = [cachePaths objectAtIndex:0];
		
		NSString *congressDataValidPath = [[NSString alloc] initWithFormat:@"%@/%@",cacheDir,@"congress/dataComplete"];
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
		}
		
		[congressDataValidPath release];
	}
	return self;
}


- (void)dealloc
{
	[s_xmlParser release];
	if ( nil != m_notifyTarget ) [m_notifyTarget release];
	[super dealloc];
}


- (void)setNotifyTarget:(id)target withSelector:(SEL)sel
{
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


- (void)beginDataDownload
{
	NSString *xmlURL = [[NSString alloc] initWithFormat:@"http://services.sunlightlabs.com/api/legislators.getList.xml?apikey=%@",kSunlight_APIKey];
	
	if ( nil == s_xmlParser ) s_xmlParser = [[XMLParserOperation alloc] initWithOpDelegate:self];
	
	[s_xmlParser parseXML:[NSURL URLWithString:xmlURL] withParserDelegate:self];
}


- (void)initFromDisk
{
	// XXX - read data from /Library/Caches/congress/...
	int a = 1;
}


- (void)xmlParseOpStarted:(XMLParserOperation *)parseOp
{
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
	else
	{
		NSLog( @"CongessDataManager started XML parsing..." );
	}
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	isDataAvailable = YES;
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
	else
	{
		NSLog( @"CongressDataManager XML parsing ended %@", (success ? @"successfully." : @" in failure!") );
	}
}

#pragma mark XMLParser Delegate Methods

static NSString *kName_Legislator = @"legislator";
static NSString *kName_State = @"state";
static NSString *kTitleValue_Senator = @"Sen";


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict 
{
    if ( [elementName isEqualToString:kName_Legislator] ) 
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
		
		// add this legislator to an appropriate array
		NSMutableArray *stateArray;
		if ( [[m_currentLegislator title] isEqualToString:kTitleValue_Senator] )
		{
			stateArray = [m_senate objectForKey:[m_currentLegislator state]];
			if ( nil == stateArray ) 
			{
				stateArray = [[NSMutableArray alloc] initWithCapacity:2];
				[m_senate setValue:stateArray forKey:[m_currentLegislator state]];
			}
		}
		else
		{
			stateArray = [m_house objectForKey:[m_currentLegislator state]];
			if ( nil == stateArray ) 
			{
				stateArray = [[NSMutableArray alloc] initWithCapacity:8];
				[m_house setValue:stateArray forKey:[m_currentLegislator state]];
			}
		}
		[stateArray addObject:m_currentLegislator];
		
		[m_currentLegislator release];
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
				
				// Add this state to our house/senate state dictionaries
				if ( nil == [m_house objectForKey:m_currentString] )
				{
					[m_house setValue:[[NSMutableArray alloc] initWithCapacity:8] forKey:m_currentString];
				}
				if ( nil == [m_senate objectForKey:m_currentString] )
				{
					[m_senate setValue:[[NSMutableArray alloc] initWithCapacity:2] forKey:m_currentString];
				}
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
	[m_currentString setString:@""];
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	parsingLegislator = NO;
	storingCharacters = NO;
	[m_currentLegislator release];
	[m_currentString setString:@""];
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

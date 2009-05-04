//
//  LegislatorInfoData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import "myGovAppDelegate.h"
#import "ComposeMessageViewController.h"
#import "CongressionalCommittees.h"
#import "DataProviders.h"
#import "LegislatorContainer.h"
#import "LegislatorInfoData.h"
#import "MiniBrowserController.h"


enum
{
	eSection_Contact = 0,
	eSection_InfoStream = 1,
	eSection_Committe = 2,
	eSection_Recent = 3,
};

#define KEY_CONTACT    @"Contact Information" 
#define KEY_COMMITTEE  @"Committee Membership"
#define KEY_INFOSTREAM @"Legislator Info Stream"
#define KEY_RECENT     @"Recent Activity"

// The order here _must_ correspond to the order in the enumeration above
#define DATA_SECTIONS KEY_CONTACT, \
                      KEY_INFOSTREAM, \
                      KEY_COMMITTEE, \
                      KEY_RECENT, \
                      nil

// 
// Setup the contact section data
// 
#define CONTACT_ROWKEY @"01_email",@"02_phone",@"03_twitter",@"04_fax", \
                       @"05_webform",@"06_website",@"07_office", \
                       nil

#define CONTACT_ROWSEL @selector(email),@selector(phone),@selector(twitter_id), \
                       @selector(fax),@selector(webform),@selector(website), \
                       @selector(congress_office)

#define CONTACT_ROWACTION @selector(rowActionMailto:),\
                          @selector(rowActionPhoneCall:), \
                          @selector(rowActionTwitterDM:), \
                          @selector(rowActionNone:), \
                          @selector(rowActionURL:), \
                          @selector(rowActionURL:), \
                          @selector(rowActionLegislatorMap:)

// 
// Setup the infostream section data 
// 
#define INFOSTREAM_ROWKEY @"01_twitter",@"02_youtube", \
                          @"03_OpenCongress", \
                          @"04_eventful", \
                          nil

#define INFOSTREAM_ROWSEL @selector(twitter_url), @selector(youtube_url), \
                          @selector(congresspedia_url), @selector(eventful_url)

#define INFOSTREAM_ROWACTION @selector(rowActionURL:), \
                             @selector(rowActionURL:), \
                             @selector(rowActionURL:), \
                             @selector(rowActionURL:)


@interface LegislatorInfoData (private)
	- (NSArray *)setupDataSection:(NSInteger)section;
	- (void)startActivityDownload;
	- (void)rowActionTwitterDM:(NSIndexPath *)indexPath;
	- (void)rowActionLegislatorMap:(NSIndexPath *)indexPath;
@end



@implementation LegislatorInfoData

static NSString *kName_Response = @"person";
static NSString *kName_NewsItem = @"recent-news";
static NSString *kNewsItem_Attr_Type = @"type";
static NSString *kNewsItem_responseArray = @"array";
static NSString *kNewsItem_Excerpt = @"excerpt";
static NSString *kNewsItem_URL = @"url";
static NSString *kNewsItem_Source = @"source";
static NSString *kNewsItem_Title = @"title";

/*
	For the future: more person stats!
 *
static NSString *kName_PersonStats = @"person-stats";
static NSString *kName_CosponsoredBills = @"cosponsored-bills"; // integer
static NSString *kName_CosponsoredBillsPassed = @"cosponsored-bills-passed"; // integer
static NSString *kName_SponsoredBills = @"sponsored-bills"; // integer
static NSString *kName_SponsoredBillsPassed = @"sponsored-bills-passed"; // integer
static NSString *kName_AbstainsPct = @"abstains-percentage"; // float
static NSString *kName_VotesWithPartyPct = @"party-votes-percentage"; // float
*/

- (id)init
{
	if ( self = [super init] )
	{
		m_legislator = nil;
		
		m_activityDownloaded = NO;
		m_activityData = nil;
		
		m_parsingResponse = NO;
		m_storingCharacters = NO;
		m_currentString = nil;
		m_currentTitle = nil;
		m_currentExcerpt = nil;
		m_currentSource = nil;
		m_currentRowData = nil;
		m_xmlParser = nil;
		
		m_dataSections = [[NSArray alloc] initWithObjects:DATA_SECTIONS];
	}
	return self;
}


- (void)dealloc
{
	[m_xmlParser abort];
	[m_xmlParser release];
	[m_currentString release];
	[m_currentTitle release];
	[m_currentExcerpt release];
	[m_currentSource release];
	[m_currentRowData release];

	[m_legislator release];
	[m_activityData release];
	
	[super dealloc];
}


- (void)setLegislator:(LegislatorContainer *)legislator
{
	[m_data release]; m_data = nil;
	[m_legislator release]; m_legislator = [legislator retain];
	m_activityDownloaded = NO;
	
	// allocate data
	m_data = [[NSMutableArray alloc] initWithCapacity:[m_dataSections count]];
	
	for ( NSInteger ii = 0; ii < [m_dataSections count]; ++ii )
	{
		NSArray *sectionData = [self setupDataSection:ii];
		[m_data addObject:sectionData];
		[sectionData release];
	}
}


- (void)stopAnyWebActivity
{
	[m_xmlParser abort];
}


#pragma mark LegislatorInfoData Private


- (NSArray *)setupDataSection:(NSInteger)section
{
	NSMutableArray *retVal = [[NSMutableArray alloc] init];
	
	switch ( section )
	{
		case eSection_Contact:
		{
			NSArray *keys = [NSArray arrayWithObjects:CONTACT_ROWKEY];
			SEL dataSelector[] = { CONTACT_ROWSEL };
			SEL dataAction[] = { CONTACT_ROWACTION };
			for ( NSInteger ii = 0; ii < [keys count]; ++ii )
			{
				NSString *value = [m_legislator performSelector:dataSelector[ii]];
				if ( [value length] > 0 )
				{
					TableRowData *rd = [[TableRowData alloc] init];
					rd.title = [keys objectAtIndex:ii];
					rd.titleFont = [UIFont boldSystemFontOfSize:12.0f];
					rd.line1 = value;
					rd.line1Font = [UIFont systemFontOfSize:12.0f];
					
					rd.action = dataAction[ii];
					[retVal addObject:rd];
				}
			}
		}
			[retVal sortUsingSelector:@selector(compareTitle:)];
			break;
		
		case eSection_InfoStream:
		{
			NSArray *keys = [NSArray arrayWithObjects:INFOSTREAM_ROWKEY];
			SEL dataSelector[] = { INFOSTREAM_ROWSEL };
			SEL dataAction[] = { INFOSTREAM_ROWACTION };
			for ( NSInteger ii = 0; ii < [keys count]; ++ii )
			{
				NSString *value = [m_legislator performSelector:dataSelector[ii]];
				if ( [value length] > 0 )
				{
					TableRowData *rd = [[TableRowData alloc] init];
					rd.title = [keys objectAtIndex:ii];
					rd.titleFont = [UIFont boldSystemFontOfSize:12.0f];
					rd.line1 = value;
					rd.line1Font = [UIFont systemFontOfSize:12.0f];
					
					rd.action = dataAction[ii];
					[retVal addObject:rd];
				}
			}
		}
			[retVal sortUsingSelector:@selector(compareTitle:)];
			break;
		case eSection_Committe:
		{
			NSArray *comData = [m_legislator committee_data];
			NSEnumerator *comEnum = [comData objectEnumerator];
			id obj;
			while (obj = [comEnum nextObject]) 
			{
				LegislativeCommittee *committee = (LegislativeCommittee *)obj;
				
				NSString *cID = [NSString stringWithFormat:@"%@_%@",
											committee.m_id,
											(nil == committee.m_parentCommittee ? 
												committee.m_id : 
												[NSString stringWithFormat:@"[%@]",committee.m_parentCommittee]
											 )
								 ];
				TableRowData *rd = [[TableRowData alloc] init];
				rd.title = cID;
				rd.titleFont = [UIFont boldSystemFontOfSize:14.0f];
				rd.line2 = committee.m_name;
				rd.line2Font = [UIFont systemFontOfSize:14.0f];
				
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
			}
		}
			break;
		case eSection_Recent:
		{
			if ( m_activityDownloaded )
			{
				[retVal addObjectsFromArray:m_activityData];
			}
			else
			{
				if ( nil != m_activityData )
				{
					// there might be an error message in here!
					[retVal addObjectsFromArray:m_activityData];
				}
				else
				{
					TableRowData *rd = [[TableRowData alloc] init];
					rd.title = @"Downloading...";
					rd.action = @selector(rowActionNone:);
					[retVal addObject:rd];
				}
				[self startActivityDownload];
			}
		}
			break;
	}
	
	return retVal;
}


- (void)startActivityDownload
{
	[m_activityData release];
	m_activityData = [[NSMutableArray alloc] init];
	
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
	
	NSString *urlStr = [DataProviders OpenCongress_PersonURL:m_legislator];
	[m_xmlParser parseXML:[NSURL URLWithString:urlStr] withParserDelegate:self];
}


- (void)rowActionTwitterDM:(NSIndexPath *)indexPath
{
	// display a message composer to tweet the legislator!
	MessageData *msg = [[MessageData alloc] init];
	msg.m_transport = opSendTwitterDM;
	msg.m_to = [NSString stringWithFormat:@"@%@",[m_legislator twitter_id]];
	msg.m_subject = @"";
	
	ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
	[cmvc display:msg fromParent:[[myGovAppDelegate sharedAppDelegate] topViewController]];
}


- (void)rowActionLegislatorMap:(NSIndexPath *)indexPath
{
	static NSString * kGoogleMapsURLFmt = @"http://maps.google.com/maps?q=%@+%@+%@+Washington+DC&ie=UTF&z=18&cd=1";
	
	NSString *title = @"representative";
	if ( [[[m_legislator title] uppercaseString] isEqualToString:@"Sen"] )
	{
		title = @"senator";
	}
	else if ( [[[m_legislator title] uppercaseString] isEqualToString:@"Del"] )
	{
		title = @"delegate";
	}
	
	NSString *genderTitle = @"Congressman";
	if ( [[[m_legislator gender] uppercaseString] isEqualToString:@"F"] )
	{
		genderTitle = @"Congresswoman";
	}
	NSString *name = [NSString stringWithFormat:@"%@+%@", 
								[m_legislator firstname], [m_legislator lastname]];
	name = [name stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	
	NSString *urlStr = [NSString stringWithFormat:kGoogleMapsURLFmt,
									title,
									genderTitle, 
									name];
	
	// open GoogleMaps application!
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
}



#pragma mark XMLParserOperationDelegate Methods


- (void)xmlParseOpStarted:(XMLParserOperation *)parseOp
{
	// delay the downloading of recent info so that the
	// legislator's image download has a chance to start first...
	// (yes this is a bit of a hack)
	[NSThread sleepForTimeInterval:1.1f]; 
	//NSLog( @"LegislatorInfoData started OpenCongress download for %@...",[m_legislator shortName] );
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	m_activityDownloaded = success;
	if ( !m_activityDownloaded )
	{
		[m_activityData release]; 
		m_activityData = [[NSMutableArray alloc] init];
		
		TableRowData *rd = [[TableRowData alloc] init];
		if ( [m_currentString length] > 0 )
		{
			rd.title = m_currentString; // the error string
		}
		else
		{
			rd.title = @"Error downloading activity...";
		}
		rd.url = nil;
		rd.action = @selector(rowActionNone:);
		[m_activityData addObject:rd];
	}
	
	// add the activity data to our main data stucture
	if ( [m_data count] > eSection_Recent )
	{
		[m_data replaceObjectAtIndex:eSection_Recent withObject:m_activityData];
	}
	
	if ( nil != m_notifyTarget )
	{
		NSString *str = @"LINFO Success!";
		[m_notifyTarget performSelector:m_notifySelector withObject:str];
	}
	//NSLog( @"LegislatorInfoData XML parsing ended %@", (success ? @"successfully." : @" in failure!") );
}


#pragma mark XMLParser Delegate Methods


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ( [elementName isEqualToString:kName_Response] )
	{
		m_parsingResponse = YES;
		[m_currentRowData release]; m_currentRowData = nil;
		
		[m_currentString release]; 
		m_currentString = [[NSMutableString alloc] init];
    } 
	else if ( m_parsingResponse ) 
	{
		NSString *niType = [attributeDict objectForKey:kNewsItem_Attr_Type];
		if ( [elementName isEqualToString:kName_NewsItem] )
		{
			[m_currentTitle release]; m_currentTitle = nil;
			[m_currentExcerpt release]; m_currentExcerpt = nil;
			[m_currentSource release]; m_currentSource = nil;
			[m_currentRowData release]; m_currentRowData = nil;
			
			if ( [niType isEqualToString:kNewsItem_responseArray] )
			{
				// This is the beginning of the recent new array
				m_storingCharacters = NO;
				
				// allocate the activity data array
				m_activityData = [[NSMutableArray alloc] init];
			}
			else
			{
				// start a news item
				m_currentRowData = [[TableRowData alloc] init]; 
				
				m_storingCharacters = YES;
			}
		}
		[m_currentString setString:@""];
    }
	else
	{
		m_storingCharacters = NO;
		m_parsingResponse = NO;
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	if ( [elementName isEqualToString:kName_Response] ) 
	{
		m_parsingResponse = NO;
		// This is the end of the data!
	}
	else if ( m_parsingResponse && (nil != m_currentRowData) )
	{
		if ( [elementName isEqualToString:kNewsItem_URL] )
		{
			NSURL *url = [[NSURL alloc] initWithString:m_currentString];
			m_currentRowData.url = url;
			[url release];
		}
		else if ( [elementName isEqualToString:kNewsItem_Title] )
		{
			m_currentTitle = [[NSString alloc] initWithString:m_currentString];
		}
		else if ( [elementName isEqualToString:kNewsItem_Source] )
		{
			m_currentSource = [[NSString alloc] initWithString:m_currentString];
		}
		else if ( [elementName isEqualToString:kNewsItem_Excerpt] )
		{
			m_currentExcerpt = [[NSString alloc] initWithString:m_currentString];
		}
		else if ( [elementName isEqualToString:kName_NewsItem]  )
		{
			// put together the final 'value'
			m_currentRowData.line1 = ([m_currentTitle length] > 0) ? m_currentTitle : m_currentSource;
			m_currentRowData.line1Font = [UIFont boldSystemFontOfSize:14.0f];
			m_currentRowData.line1Color = [UIColor blackColor];
			m_currentRowData.line2 = m_currentExcerpt;
			m_currentRowData.line2Font = [UIFont systemFontOfSize:12.0f];
			m_currentRowData.action = @selector(rowActionURL:);
			
			[m_activityData addObject:m_currentRowData];
			[m_currentRowData release]; m_currentRowData = nil;
		}
	}
	else
	{
		// XXX - nothing to do!
	}
	
	// reset the current string
	[m_currentString setString:@""];
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
    if ( m_storingCharacters ) [m_currentString appendString:string];
}


// XXX - handle XML parse errors in some sort of graceful way...
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
	m_parsingResponse = NO;
	m_storingCharacters = NO;
	[m_currentString setString:[NSString stringWithFormat:@"ERROR XML parse error: %@",
											[parseError localizedDescription]]
	];
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:m_currentString];
	}
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	m_parsingResponse = NO;
	m_storingCharacters = NO;
	[m_currentString setString:[NSString stringWithFormat:@"ERROR XML validation error: %@",
								[validError localizedDescription]]
	];
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:m_currentString];
	}
}


@end

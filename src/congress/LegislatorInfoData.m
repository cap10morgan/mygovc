//
//  LegislatorInfoData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CongressionalCommittees.h"
#import "LegislatorContainer.h"
#import "LegislatorInfoCell.h"
#import "LegislatorInfoData.h"
#import "MiniBrowserController.h"

@interface SectionRowData : NSObject
{
	NSString *field;
	NSString *value;
	SEL action;
}
@property (nonatomic,retain) NSString *field;
@property (nonatomic,retain) NSString *value;
@property (nonatomic) SEL action;

- (NSComparisonResult)compareField:(SectionRowData *)other;

@end

@implementation SectionRowData

@synthesize field, value, action;

- (NSComparisonResult)compareField:(SectionRowData *)other
{
	return [field compare:other.field];
}

@end


enum
{
	eSection_Contact = 0,
	eSection_Committe = 1,
	eSection_InfoStream = 2,
	eSection_Recent = 3,
};

#define KEY_CONTACT    @"ContactInformation" 
#define KEY_COMMITTEE  @"Committee Membership"
#define KEY_INFOSTREAM @"Legislator Info Stream"
#define KEY_RECENT     @"Recent Activity"

// The order here _must_ correspond to the order in the enumeration above
#define DATA_SECTIONS KEY_CONTACT, \
                      KEY_COMMITTEE, \
                      KEY_INFOSTREAM, \
                      KEY_RECENT, \
                      nil

// 
// Setup the contact section data
// 
#define CONTACT_ROWKEY @"01_email",@"02_phone",@"03_fax", \
                       @"04_webform",@"05_website",@"06_office", \
                       nil

#define CONTACT_ROWSEL @selector(email),@selector(phone),@selector(fax), \
                       @selector(webform),@selector(website),@selector(congress_office)

#define CONTACT_ROWACTION @selector(rowActionMailto:),\
                          @selector(rowActionPhoneCall:), \
                          @selector(rowActionNone:), \
                          @selector(rowActionURL:), \
                          @selector(rowActionURL:), \
                          @selector(rowActionMap:)


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
	- (SectionRowData *)dataForIndexPath:(NSIndexPath *)indexPath;
	- (void)rowActionNone:(NSIndexPath *)indexPath;
	- (void)rowActionMailto:(NSIndexPath *)indexPath;
	- (void)rowActionPhoneCall:(NSIndexPath *)indexPath;
	- (void)rowActionURL:(NSIndexPath *)indexPath;
	- (void)rowActionMap:(NSIndexPath *)indexPath;
@end



@implementation LegislatorInfoData

static NSInteger        s_sectionRefCount = 0;
static NSMutableArray * s_dataSections = NULL;
static NSMutableArray * s_sectionKeys = NULL;


- (id)init
{
	if ( self = [super init] )
	{
		m_notifyTarget = nil;
		m_notifySelector = nil;
		m_legislator = nil;
		m_data = nil;
		
		m_opQ = [[NSOperationQueue alloc] init];
		
		// build up the array of data sections if necessary
		if ( NULL == s_dataSections )
		{
			s_dataSections = [[NSArray alloc] initWithObjects:DATA_SECTIONS];
		} // if ( NULL == s_dataSections )
		++s_sectionRefCount;
	}
	return self;
}


- (void)dealloc
{
	[m_notifyTarget release];
	[m_legislator release];
	[m_data release];
	[m_opQ release];
	
	if ( 0 == --s_sectionRefCount )
	{
		[s_dataSections release]; s_dataSections = NULL;
		[s_sectionKeys release]; s_sectionKeys = NULL;
	}
	
	[super dealloc];
}


- (void)setNotifyTarget:(id)target andSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = target;
	m_notifySelector = sel;
}


- (void)setLegislator:(LegislatorContainer *)legislator
{
	[m_data release]; m_data = nil;
	[m_legislator release]; m_legislator = [legislator retain];
	
	// stop all download activity...
	[m_opQ cancelAllOperations];
	
	// allocate data
	m_data = [[NSMutableArray alloc] initWithCapacity:[s_dataSections count]];
	
	for ( NSInteger ii = 0; ii < [s_dataSections count]; ++ii )
	{
		NSArray *sectionData = [self setupDataSection:ii];
		[m_data addObject:sectionData];
		[sectionData release];
	}
}


- (NSInteger)numberOfSections
{
	return [m_data count];
}


- (NSString *)titleForSection:(NSInteger)section
{
	if ( section < [s_dataSections count] )
	{
		return [s_dataSections objectAtIndex:section];
	}
	return nil;
}


- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
	if ( section >= [m_data count] ) return 0;
	return [[m_data objectAtIndex:section] count];
}


- (CGFloat)heightForDataAtIndexPath:(NSIndexPath *)indexPath
{
	SectionRowData *rd = [self dataForIndexPath:indexPath];
	return [LegislatorInfoCell cellHeightForText:rd.value withKeyname:rd.field];
}


- (void)setInfoCell:(LegislatorInfoCell *)cell forIndex:(NSIndexPath *)indexPath
{
	if ( nil == cell ) return;
	if ( nil == indexPath ) return;
	
	SectionRowData *rd = [self dataForIndexPath:indexPath];
	[cell setField:rd.field withValue:rd.value];
	
	SEL none = @selector(rowActionNone:);
	if ( rd.action == none )
	{
		cell.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
}


- (void)performActionForIndex:(NSIndexPath *)indexPath withParent:(id)parent
{
	m_actionParent = [parent retain];
	
	SectionRowData *rd = [self dataForIndexPath:indexPath];
	if ( nil != rd )
	{
		[self performSelector:rd.action withObject:indexPath];
	}
	
	[m_actionParent release]; m_actionParent = nil;
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
					SectionRowData *rd = [[SectionRowData alloc] init];
					rd.value = value;
					rd.field = [keys objectAtIndex:ii];
					rd.action = dataAction[ii];
					[retVal addObject:rd];
				}
			}
		}
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
					SectionRowData *rd = [[SectionRowData alloc] init];
					rd.value = value;
					rd.field = [keys objectAtIndex:ii];
					rd.action = dataAction[ii];
					[retVal addObject:rd];
				}
			}
		}
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
												@"" : 
												[NSString stringWithFormat:@"[%@]",committee.m_parentCommittee]
											 )
								 ];
				NSString *cNM = [NSString stringWithFormat:@"%@\n%@",
											(nil == committee.m_parentCommittee ? committee.m_id : @""),
											committee.m_name
								 ];
				
				SectionRowData *rd = [[SectionRowData alloc] init];
				rd.value = cNM;
				rd.field = cID;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
			}
		}
			break;
		case eSection_Recent:
		{
		}
			break;
	}
	
	[retVal sortUsingSelector:@selector(compareField:)];
	
	return retVal;
}


- (SectionRowData *)dataForIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	
	if ( section >= [m_data count] ) 30.0f; // some arbitrary default...
	
	NSArray *secArray = [m_data objectAtIndex:section];
	if ( row >= [secArray count] ) return nil;
	
	// 
	// Get the key/value pair from the single-object-dictionary stored
	// in the 'm_data' object at: m_data[indexPath.section][indexPath.row]
	// 
	return [secArray objectAtIndex:row];
}


- (void)rowActionNone:(NSIndexPath *)indexPath
{
	(void)indexPath;
	return;
}


- (void)rowActionMailto:(NSIndexPath *)indexPath
{
	SectionRowData *rd = [self dataForIndexPath:indexPath];
	if ( nil == rd ) return;
	
	NSString *emailStr = [[NSString alloc] initWithFormat:@"mailto:%@?subject=%@",
						  [rd.value stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], 
						  @"Message from a concerned citizen"
						  ];
	NSURL *emailURL = [[NSURL alloc] initWithString:emailStr];
	[[UIApplication sharedApplication] openURL:emailURL];
	[emailStr release];
	[emailURL release];
}


- (void)rowActionPhoneCall:(NSIndexPath *)indexPath
{
	SectionRowData *rd = [self dataForIndexPath:indexPath];
	if ( nil == rd ) return;
	
	// make a phone call!
	NSString *telStr = [[[NSString alloc] initWithFormat:@"tel:%@",rd.value] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	NSURL *telURL = [[NSURL alloc] initWithString:telStr];
	[[UIApplication sharedApplication] openURL:telURL];
	[telStr release];
	[telURL release];
}


- (void)rowActionURL:(NSIndexPath *)indexPath
{
	SectionRowData *rd = [self dataForIndexPath:indexPath];
	if ( nil == rd ) return;
	
	MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:[NSURL URLWithString:rd.value]];
	[mbc display:m_actionParent];
}


- (void)rowActionMap:(NSIndexPath *)indexPath
{
	static NSString * kGoogleMapsURLFmt = @"http://maps.google.com/maps?q=%@+%@+%@+Washington+DC&ie=UTF&z=17&cd=1";
	
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
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:urlStr]];
	/*
	MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:[NSURL URLWithString:urlStr]];
	[mbc display:m_actionParent];
	 */
}


#pragma mark XMLParser Delegate Methods

#if 0

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ( [elementName isEqualToString:kName_Response] )
	{
		m_parsingResponse = YES;
		[m_currentState release]; m_currentState = nil;
		m_currentDistrict = 0;
    } 
	else if ( m_parsingResponse ) 
	{
		m_currentString = [[NSMutableString alloc] initWithString:@""];
		m_storingCharacters = YES;
    }
	else
	{
		m_storingCharacters = NO;
		m_parsingResponse = NO;
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	m_storingCharacters = NO;
	if ( [elementName isEqualToString:kName_Response] ) 
	{
		m_parsingResponse = NO;
		[m_data setCurrentState:m_currentState andDistrict:m_currentDistrict];
	}
	else if ( m_parsingResponse && [elementName isEqualToString:kName_State] )
	{
		m_currentState = [[NSString alloc] initWithString:m_currentString];
	}
	else if ( m_parsingResponse && [elementName isEqualToString:kName_District] )
	{
		m_currentDistrict = [m_currentString integerValue];
	}
	else
	{
		// XXX - nothing to do!
	}
	[m_currentString release]; m_currentString = nil;
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
	[m_currentString release]; 
	m_currentString = [[NSString alloc] initWithString:@"ERROR XML parsing error"];
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:m_currentString];
	}
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	m_parsingResponse = NO;
	m_storingCharacters = NO;
	[m_currentString release];
	m_currentString = [[NSString alloc] initWithString:@"ERROR XML validation error"];
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:m_currentString];
	}
}

#endif


@end

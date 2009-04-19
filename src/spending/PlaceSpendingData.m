//
//  PlaceSpendingData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <Foundation/NSCalendar.h>

#import "PlaceSpendingData.h"
#import "SpendingDataManager.h"
#import "StateAbbreviations.h"
#import "XMLParserOperation.h"


@interface PlaceSpendingData (private)
	- (void)genericInit;
@end


@implementation PlaceSpendingData

@synthesize isDataAvailable;
@synthesize isBusy;
@synthesize m_place;
@synthesize m_year;
@synthesize m_rank;
@synthesize m_totalDollarsObligated;
@synthesize m_totalContractors;
@synthesize m_totalTransactions;
@synthesize m_placeType;

static NSString *kName_Data = @"data";
static NSString *kName_Record = @"record";

static NSString *kName_Totals = @"totals";
static NSString *kName_SummaryYear = @"fiscal_year";
static NSString *kName_SummaryPercentFY = @"percent_of_fiscal_year";
static NSString *kName_SummaryTotalDollars = @"total_ObligatedAmount";
static NSString *kName_SummaryDistrictRank = @"rank_among_congressional_districts";
static NSString *kName_SummaryStateRank = @"rank_among_states";
static NSString *kName_SummaryNumContactors = @"number_of_contractors";
static NSString *kName_SummaryNumTransactions = @"number_of_transactions";

static NSString *kName_TopCDistWhereWorkPerformed = @"top_known_congressional_districts";
static NSString *kName_CongressionalDistrict = @"congressional_district";

static NSString *kName_TopCategories = @"top_products_or_services_sold";
static NSString *kName_ContractCategory = @"product_or_service_category";

static NSString *kName_TopAgencies = @"top_contracting_agencies";
static NSString *kName_ContractAgency = @"agency";

static NSString *kName_TopContractors = @"top_contractor_parent_companies";
static NSString *kName_ContractCompany = @"contractor_parent_company";
static NSString *kProp_DollarAmount = @"total_obligatedAmount";


#pragma mark PlaceSpendingData Private 


- (void)genericInit
{
	isDataAvailable = NO;
	isBusy = NO;
	
	m_year = 0;
	m_rank = 0;
	m_totalDollarsObligated = 0.0;
	m_totalContractors = 0;
	m_totalTransactions = 0;
	
	m_topCDists = [[NSMutableDictionary alloc] initWithCapacity:10];
	m_topContractors = [[NSMutableDictionary alloc] initWithCapacity:10];
	m_topAgencies = [[NSMutableDictionary alloc] initWithCapacity:10];
	m_topCategories = [[NSMutableDictionary alloc] initWithCapacity:10];
	
	m_xmlParser = nil;
	m_parsingData = NO;
	m_parsingRecord = NO;
	m_currentXMLStr = nil;
	m_currentParseElement = eDSE_None;
	
	m_tryAlternateURL = NO;
	
	m_notifyTarget = nil;
}


#pragma mark PlaceSpendingData Public

- (id)initWithDistrict:(NSString *)district
{
	if ( self = [super init] )
	{
		[self genericInit];
		m_placeType = eSPT_District;
		m_place = [[NSString alloc] initWithString:district];
	}
	return self;
}


- (id)initWithState:(NSString *)state 
{
	if ( self = [super init] )
	{
		[self genericInit];
		m_placeType = eSPT_State;
		m_place = [[NSString alloc] initWithString:state];
	}
	return self;
}


- (void)dealloc
{
	[m_place release];
	[m_topCDists release];
	[m_topContractors release];
	[m_topAgencies release];
	[m_topCategories release];
	[m_xmlParser release];
	[m_currentXMLStr release];
	[m_notifyTarget release];
	[super dealloc];
}


- (NSDictionary *)topCDistsWhereWorkPerformed
{
	return (NSDictionary *)m_topCDists;
}


- (NSDictionary *)topContractors
{
	return (NSDictionary *)m_topContractors;
}


- (NSDictionary *)topAgencies
{
	return (NSDictionary *)m_topAgencies;
}


- (NSDictionary *)topCategories
{
	return (NSDictionary *)m_topCategories;
}


// Asynchronous download of 
- (void)downloadDataWithCallback:(SEL)sel onObject:(id)obj synchronously:(BOOL)waitForData
{
	isDataAvailable = NO;
	isBusy = YES;
	
	m_notifyTarget = obj;
	m_notifySelector = sel;
	
	if ( nil != m_xmlParser )
	{
		// abort any previous attempt at parsing/downloading
		[m_xmlParser abort];
	}
	else
	{
		m_xmlParser = [[XMLParserOperation alloc] initWithOpDelegate:self];
	}
	
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	NSInteger year = [[gregorian components:NSYearCalendarUnit fromDate:[NSDate date]] year];
	[gregorian release];
	m_year = year;
	
	NSString *altPlace = nil;
	if ( m_tryAlternateURL )
	{
		m_tryAlternateURL = NO;
		if ( [m_place length] > 2 )
		{
			altPlace = [NSString stringWithFormat:@"%@98",[m_place substringToIndex:2]];
		}
		else
		{
			altPlace = [m_place stringByAppendingString:@"98"];
		}
	}
	
	NSURL *detailSummaryURL;
	if ( eSPT_District == m_placeType )
	{
		NSString *urlStr = [DataProviders USASpending_districtURL:(nil == altPlace ? m_place : altPlace)
														  forYear:year 
													   withDetail:eSpendingDetailSummary 
														 sortedBy:eSpendingSortDollars];
		detailSummaryURL = [NSURL URLWithString:urlStr];
	}
	else if ( eSPT_State == m_placeType )
	{
		NSString *urlStr = [DataProviders USASpending_stateURL:(nil == altPlace ? m_place : altPlace) 
													   forYear:year 
													withDetail:eSpendingDetailSummary 
													  sortedBy:eSpendingSortDollars];
		detailSummaryURL = [NSURL URLWithString:urlStr];
	}
	
	// kick off the download/parsing of XML data 
	if ( !waitForData )
	{
		[m_xmlParser parseXML:detailSummaryURL withParserDelegate:self withStringEncoding:NSMacOSRomanStringEncoding];
	}
	else
	{
		// download synchronously :-)
		//NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:detailSummaryURL];
		NSData *data = [NSData dataWithContentsOfURL:detailSummaryURL];
		NSString *xmlStr = [[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding];
		NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:[xmlStr dataUsingEncoding:NSUTF8StringEncoding]];
		[xmlStr release];
		
		if ( nil == xmlParser ) 
		{
			isDataAvailable = NO;
			isBusy = NO;
			if ( nil != m_notifyTarget )
			{
				[m_notifyTarget performSelector:m_notifySelector withObject:self];
			}
			return;
		}
		
		[xmlParser setDelegate:self];
		isDataAvailable = [xmlParser parse];
		isBusy = NO;
		
		if ( nil != m_notifyTarget )
		{
			[m_notifyTarget performSelector:m_notifySelector withObject:self];
		}
	}
}


#pragma mark XMLParserOperationDelegate Methods 


- (void)xmlParseOpStarted:(XMLParserOperation *)parseOp
{
	NSLog( @"[PlaceSpendingData:%@] started XML parsing...",m_place );
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	isDataAvailable = success;
	isBusy = NO;
	
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
	NSLog( @"[PlaceSpendingData:%@] XML parsing ended %@", m_place, (success ? @"successfully." : @" in failure!") );
	
	if ( isDataAvailable )
	{
		// XXX - cache this data somewhere?
	}
}


#pragma mark XMLParser Delegate Methods


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ( [elementName isEqualToString:kName_Data] )
	{
		m_parsingData = YES;
	}
    else if ( m_parsingData && [elementName isEqualToString:kName_Record] ) 
	{
		m_parsingRecord = YES;
    } 
	else if ( m_parsingRecord && [elementName isEqualToString:kName_Totals] ) 
	{
		m_currentParseElement = eDSE_Totals;
    }
	else if ( m_parsingRecord && [elementName isEqualToString:kName_TopCDistWhereWorkPerformed] )
	{
		m_currentParseElement = eDSE_TopCongDistricts;
	}
	else if ( m_parsingRecord && [elementName isEqualToString:kName_TopAgencies] )
	{
		m_currentParseElement = eDSE_TopAgencies;
	}
	else if ( m_parsingRecord && [elementName isEqualToString:kName_TopContractors] ) 
	{
		m_currentParseElement = eDSE_TopContractors;
	}
	else if ( m_parsingRecord && [elementName isEqualToString:kName_TopCategories] )
	{
		m_currentParseElement = eDSE_TopCategories;
	}
	else
	{
		// nothing to do for this new key
	}
	if ( m_currentParseElement != eDSE_None )
	{
		[m_currentXMLStr release];
		m_currentXMLStr = [[NSMutableString alloc] init];
		m_currentFloatVal = [[attributeDict objectForKey:kProp_DollarAmount] doubleValue];
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	if ( [elementName isEqualToString:kName_Data] )
	{
		m_parsingData = NO;
		m_parsingRecord = NO;
		m_currentParseElement = eDSE_None;
	}
    else if ( m_parsingData && [elementName isEqualToString:kName_Record] ) 
	{
		m_parsingRecord = NO;
		m_currentParseElement = eDSE_None;
    } 
	else if ( m_parsingRecord && [elementName isEqualToString:kName_Totals] ) 
	{
		m_currentParseElement = eDSE_None;
    }
	else if ( m_parsingRecord && [elementName isEqualToString:kName_TopCDistWhereWorkPerformed] )
	{
		m_currentParseElement = eDSE_None;
	}
	else if ( m_parsingRecord && [elementName isEqualToString:kName_TopAgencies] )
	{
		m_currentParseElement = eDSE_None;
	}
	else if ( m_parsingRecord && [elementName isEqualToString:kName_TopContractors] ) 
	{
		m_currentParseElement = eDSE_None;
	}
	else if ( m_parsingRecord && [elementName isEqualToString:kName_TopCategories] )
	{
		m_currentParseElement = eDSE_None;
	}
	else
	{
		switch ( m_currentParseElement )
		{
			case eDSE_Totals:
				{
					if ( [elementName isEqualToString:kName_SummaryYear] )
					{
						NSUInteger year =  [m_currentXMLStr integerValue];
						//if ( year != m_year ) NSLog( @"District %@: year in returned data (%d) doesn't match current year (%d)!", m_place, year, m_year );
						m_year = year;
					}
					else if ( [elementName isEqualToString:kName_SummaryTotalDollars] )
					{
						m_totalDollarsObligated = [m_currentXMLStr doubleValue];
					}
					else if ( [elementName isEqualToString:kName_SummaryDistrictRank] )
					{
						m_rank = (NSUInteger)[m_currentXMLStr integerValue];
					}
					else if ( [elementName isEqualToString:kName_SummaryStateRank] )
					{
						m_rank = (NSUInteger)[m_currentXMLStr integerValue];
					}
					else if ( [elementName isEqualToString:kName_SummaryNumContactors] )
					{
						m_totalContractors = [m_currentXMLStr integerValue];
					}
					else if ( [elementName isEqualToString:kName_SummaryNumTransactions] )
					{
						m_totalTransactions = [m_currentXMLStr integerValue];
					}
				}
				break;
			case eDSE_TopCongDistricts:
				{
					if ( [elementName isEqualToString:kName_CongressionalDistrict] )
					{
						// district name format from XML: "{State} {Dist} ({Representative})"
						NSArray *components = [m_currentXMLStr componentsSeparatedByString:@" "];
						if ( [components count] > 1 )
						{
							NSString *state = [StateAbbreviations abbrFromName:[components objectAtIndex:0]];
							NSString *distStr = [components objectAtIndex:1];
							if ( [distStr isEqualToString:@"At"] ) { distStr = @"00"; } // At Large district...
							NSString *dist = [NSString stringWithFormat:@"%@%.2d",state,[distStr integerValue]];
							[m_topCDists setValue:[NSNumber numberWithFloat:m_currentFloatVal] forKey:dist];
						}
					}
				}
				break;
			case eDSE_TopAgencies:
				{
					if ( [elementName isEqualToString:kName_ContractAgency] )
					{
						[m_topAgencies setValue:[NSNumber numberWithFloat:m_currentFloatVal] forKey:m_currentXMLStr];
					}
				}
				break;
			case eDSE_TopCategories:
				{
					if ( [elementName isEqualToString:kName_ContractCategory] )
					{
						[m_topCategories setValue:[NSNumber numberWithFloat:m_currentFloatVal] forKey:m_currentXMLStr];
					}
				}
				break;
			case eDSE_TopContractors:
				{
					if ( [elementName isEqualToString:kName_ContractCompany] )
					{
						[m_topContractors setValue:[NSNumber numberWithFloat:m_currentFloatVal] forKey:m_currentXMLStr];
					}
				}
				break;
			default: 
				break;
		}
	}
	
	[m_currentXMLStr release];
	m_currentXMLStr = nil;
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	if ( m_currentParseElement != eDSE_None ) [m_currentXMLStr appendString:string];
}


// XXX - handle XML parse errors in some sort of graceful way...
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
	NSLog( @"[PlaceSpendingData:%@] XMLParser error: %@",m_place,[parseError localizedDescription] );
	m_tryAlternateURL = YES;
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	NSLog( @"[PlaceSpendingData:%@] XMLParser validation error: %@",m_place,[validError localizedDescription] );
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
}




@end

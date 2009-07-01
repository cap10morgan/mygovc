/*
 File: PlaceSpendingData.m
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

#import <Foundation/NSCalendar.h>
#import "CongressDataManager.h"
#import "myGovAppDelegate.h"
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
@synthesize m_pctOfYear;
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
	m_pctOfYear = 0.0;
	m_rank = 0;
	m_totalDollarsObligated = 0.0;
	m_totalContractors = 0;
	m_totalTransactions = 0;
	
	m_topCDists = [[NSMutableDictionary alloc] initWithCapacity:10];
	m_topContractors = [[NSMutableDictionary alloc] initWithCapacity:10];
	m_topAgencies = [[NSMutableDictionary alloc] initWithCapacity:10];
	m_topCategories = [[NSMutableDictionary alloc] initWithCapacity:10];
	
	m_currentURL = nil;
	
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


- (NSArray *)placeLegislators:(BOOL)includeSenators
{
	NSMutableArray *legislators = [[[NSMutableArray alloc] init] autorelease];
	switch ( m_placeType )
	{
		case eSPT_District:
		{
			LegislatorContainer *lc =  [[myGovAppDelegate sharedCongressData] districtRepresentative:m_place];
			if ( nil != lc ) [legislators addObject:lc];
		}
			if ( !includeSenators ) break;
		case eSPT_State:
		{
			NSString *state = ([m_place length] > 1) ? [m_place substringToIndex:2] : m_place;
			NSArray *senateMembers = [[myGovAppDelegate sharedCongressData] senateMembersInState:state];
			NSEnumerator *senum = [senateMembers objectEnumerator];
			id senator;
			while ( senator = [senum nextObject] )
			{
				[legislators addObject:senator];
			}
		}
			break;
		default:
			break;
	}
	return (NSArray *)legislators;
}


- (NSString *)placeDescrip
{
	switch ( m_placeType )
	{
		case eSPT_District:
		{
			if ( [m_place length] > 3 )
			{
				NSString *state = [StateAbbreviations nameFromAbbr:[m_place substringToIndex:2]];
				NSString *district = [m_place substringFromIndex:2];
				if ( [district integerValue] <= 0 )
				{
					return [NSString stringWithFormat:@"%@ At-Large",state];
				}
				else
				{
					return [NSString stringWithFormat:@"%@ District %@",state,district];
				}
			}
			else return m_place;
		}
			break;
		case eSPT_State:
		{
			if ( [m_place length] > 1 )
			{
				return [StateAbbreviations nameFromAbbr:[m_place substringToIndex:2]];
			}
			else return m_place;
		}
			break;
		default:
			return m_place;
	}
}


- (NSString *)fiscalYearDescrip
{
	return [NSString stringWithFormat:@"   %04d: %0.2f%% of total dollars",m_year,m_pctOfYear];
}


- (NSString *)totalDollarsStr
{
	return [NSString stringWithFormat:@"   $%0.3f M",m_totalDollarsObligated / 1000000];
}


- (NSString *)rankStr
{
	NSInteger rankTotal;
	CGFloat millionsOfDollars = m_totalDollarsObligated / 1000000;
	
	switch ( m_placeType )
	{
		case eSPT_District:
			rankTotal = [[[myGovAppDelegate sharedSpendingData] congressionalDistricts] count];
			break;
		case eSPT_State:
			rankTotal = [[StateAbbreviations abbrList] count];
			break;
		default:
			rankTotal = -1;
			break;
	}
	
	BOOL top25 = (millionsOfDollars > 0.1 && ((CGFloat)(m_rank) / (CGFloat)rankTotal) <= 0.25);
	
	NSString *rankText = [[[NSString alloc] initWithFormat:@"$%.1fM %@%d/%d%@",
											   millionsOfDollars,
											   (top25 ?  @" » " : @" : "),
											   m_rank,	
											   rankTotal,
											   (top25 ? @" «" : @"")
						   ] autorelease];
	return rankText;
}


- (NSString *)rankStrAlt
{
	NSInteger rankTotal;
	CGFloat millionsOfDollars = m_totalDollarsObligated / 1000000;
	
	switch ( m_placeType )
	{
		case eSPT_District:
			rankTotal = [[[myGovAppDelegate sharedSpendingData] congressionalDistricts] count];
			break;
		case eSPT_State:
			rankTotal = [[StateAbbreviations abbrList] count];
			break;
		default:
			rankTotal = -1;
			break;
	}
	
	BOOL top25 = (millionsOfDollars > 0.1 && ((CGFloat)(m_rank) / (CGFloat)rankTotal) <= 0.25);
	
	NSString *rankText = [[[NSString alloc] initWithFormat:@"%@%d / %d%@",
											   (top25 ?  @" » " : @"   "),
											   m_rank,	
											   rankTotal,
											   (top25 ? @" «" : @"")
						   ] autorelease];
	return rankText;
}


- (BOOL)rankIsTop25Pct
{
	NSInteger rankTotal;
	CGFloat millionsOfDollars = m_totalDollarsObligated / 1000000;
	
	switch ( m_placeType )
	{
		case eSPT_District:
			rankTotal = [[[myGovAppDelegate sharedSpendingData] congressionalDistricts] count];
			break;
		case eSPT_State:
			rankTotal = [[StateAbbreviations abbrList] count];
			break;
		default:
			rankTotal = -1;
			break;
	}
	BOOL top25 = (millionsOfDollars > 0.1 && ((CGFloat)(m_rank) / (CGFloat)rankTotal) <= 0.25);
	return top25;
}


- (NSString *)totalContractorsStr
{
	return [NSString stringWithFormat:@"   %0d",m_totalContractors];
}


- (NSString *)totalTransactionsStr
{
	return [NSString stringWithFormat:@"   %0d",m_totalTransactions];
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


- (NSURL *)getContractorListURL
{
	NSString *urlStr;
	switch ( m_placeType )
	{
		case eSPT_District:
			urlStr = [DataProviders USASpending_districtURL:m_place forYear:m_year withDetail:eSpendingDetailLow sortedBy:eSpendingSortDollars xmlURL:NO];
			break;
		case eSPT_State:
			urlStr = [DataProviders USASpending_stateURL:m_place forYear:m_year withDetail:eSpendingDetailLow sortedBy:eSpendingSortDollars xmlURL:NO];
			break;
		default:
			urlStr = nil;
			break;
	}
	
	NSURL *url = [[[NSURL alloc] initWithString:urlStr] autorelease];
	return url;
}


- (NSURL *)getTransactionListURL
{
	NSString *urlStr;
	switch ( m_placeType )
	{
		case eSPT_District:
			urlStr = [DataProviders USASpending_districtURL:m_place forYear:m_year withDetail:eSpendingDetailHigh sortedBy:eSpendingSortDollars xmlURL:NO];
			break;
		case eSPT_State:
			urlStr = [DataProviders USASpending_stateURL:m_place forYear:m_year withDetail:eSpendingDetailHigh sortedBy:eSpendingSortDollars xmlURL:NO];
			break;
		default:
			urlStr = nil;
			break;
	}
	
	NSURL *url = [[[NSURL alloc] initWithString:urlStr] autorelease];
	return url;
}


- (NSURL *)getSummaryURL
{
	return m_currentURL;
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
														 sortedBy:eSpendingSortDollars xmlURL:YES];
		detailSummaryURL = [NSURL URLWithString:urlStr];
	}
	else if ( eSPT_State == m_placeType )
	{
		NSString *urlStr = [DataProviders USASpending_stateURL:(nil == altPlace ? m_place : altPlace) 
													   forYear:year 
													withDetail:eSpendingDetailSummary 
													  sortedBy:eSpendingSortDollars xmlURL:YES];
		detailSummaryURL = [NSURL URLWithString:urlStr];
	}
	
	m_currentURL = [[detailSummaryURL retain] autorelease];
	
	// kick off the download/parsing of XML data 
	if ( !waitForData )
	{
		[m_xmlParser parseXML:detailSummaryURL withParserDelegate:self withStringEncoding:NSMacOSRomanStringEncoding];
	}
	else
	{
		// download synchronously :-)
		if ( ![myGovAppDelegate networkIsAvailable:YES] )
		{
			isDataAvailable = NO;
			isBusy = NO;
			return;
		}
		
		//NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:detailSummaryURL];
		NSData *data = [NSData dataWithContentsOfURL:detailSummaryURL];
		NSString *xmlStr = [[NSString alloc] initWithData:data encoding:NSMacOSRomanStringEncoding];
		NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithData:[xmlStr dataUsingEncoding:NSUTF8StringEncoding]];
		[xmlStr release];
		
		[myGovAppDelegate networkNoLongerInUse];
		
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
		// this allows the process to short-circuit (returning false), 
		// but still provide (possibly incomplete) data
		BOOL parseSuccess = [xmlParser parse];
		isDataAvailable = parseSuccess || isDataAvailable;
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
	//NSLog( @"[PlaceSpendingData:%@] started XML parsing...",m_place );
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	isDataAvailable = success;
	isBusy = NO;
	
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
	//NSLog( @"[PlaceSpendingData:%@] XML parsing ended %@", m_place, (success ? @"successfully." : @" in failure!") );
	
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
					else if ( [elementName isEqualToString:kName_SummaryPercentFY] )
					{
						m_pctOfYear = [m_currentXMLStr doubleValue];
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
	
	// try to use what we have...
	isDataAvailable = YES;
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	NSLog( @"[PlaceSpendingData:%@] XMLParser validation error: %@",m_place,[validError localizedDescription] );
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
	
	// try to use what we have...
	isDataAvailable = YES;
}




@end

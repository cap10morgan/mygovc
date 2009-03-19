//
//  DistrictSpendingData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <Foundation/NSCalendar.h>

#import "DistrictSpendingData.h"
#import "SpendingDataManager.h"
#import "XMLParserOperation.h"


@implementation DistrictSpendingData

@synthesize m_dataAvailable;
@synthesize m_district;
@synthesize m_year;
@synthesize m_districtRank;
@synthesize m_totalDollarsObligated;
@synthesize m_totalContractors;
@synthesize m_totalTransactions;

static NSString *kName_Data = @"data";
static NSString *kName_Record = @"record";

static NSString *kName_Totals = @"totals";
static NSString *kName_SummaryYear = @"fiscal_year";
static NSString *kName_SummaryTotalDollars = @"total_ObligatedAmount";
static NSString *kName_SummaryDistrictRank = @"rank_among_congressional_districts";
static NSString *kName_SummaryNumContactors = @"number_of_contractors";
static NSString *kName_SummaryNumTransactions = @"number_of_transactions";

static NSString *kName_TopCategories = @"top_products_or_services_sold";
static NSString *kName_ContractCategory = @"product_or_service_category";

static NSString *kName_TopAgencies = @"top_contracting_agencies";
static NSString *kName_ContractAgency = @"agency";

static NSString *kName_TopContractors = @"top_contractor_parent_companies";
static NSString *kName_ContractCompany = @"contractor_parent_company";
static NSString *kProp_DollarAmount = @"total_obligatedAmount";



- (id)initWithDistrict:(NSString *)district
{
	if ( self = [super init] )
	{
		m_dataAvailable = NO;
		m_district = [[NSString alloc] initWithString:district];
		m_year = 0;
		m_districtRank = 0.0;
		m_totalDollarsObligated = 0.0;
		m_totalContractors = 0;
		m_totalTransactions = 0;
		
		m_topContractors = [[NSMutableDictionary alloc] initWithCapacity:10];
		m_topAgencies = [[NSMutableDictionary alloc] initWithCapacity:10];
		m_topCategories = [[NSMutableDictionary alloc] initWithCapacity:10];
		
		m_xmlParser = nil;
		m_parsingData = NO;
		m_parsingRecord = NO;
		m_currentXMLStr = nil;
		m_currentParseElement = eDSE_None;
		
		m_notifyTarget = nil;
	}
	return self;
}


- (void)dealloc
{
	[m_district release];
	[m_topContractors release];
	[m_topAgencies release];
	[m_topCategories release];
	[m_xmlParser release];
	[m_currentXMLStr release];
	[m_notifyTarget release];
	[super dealloc];
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
- (void)downloadDataWithCallback:(SEL)sel onObject:(id)obj
{
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
	
	NSURL *detailSummaryURL = [SpendingDataManager getURLForDistrict:m_district 
												   forYear:year 
												   withDetail:eSpendingDetailSummary 
												   sortedBy:eSpendingSortDollars];
	
	// kick off the download/parsing of XML data 
	[m_xmlParser parseXML:detailSummaryURL withParserDelegate:self];
}


#pragma mark XMLParserOperationDelegate Methods 


- (void)xmlParseOpStarted:(XMLParserOperation *)parseOp
{
	NSLog( @"District %@ started XML parsing...",m_district );
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	m_dataAvailable = success;
	
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
	NSLog( @"Distric %@ XML parsing ended %@", m_district, (success ? @"successfully." : @" in failure!") );
	
	if ( m_dataAvailable )
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
						//if ( year != m_year ) NSLog( @"District %@: year in returned data (%d) doesn't match current year (%d)!", m_district, year, m_year );
						m_year = year;
					}
					else if ( [elementName isEqualToString:kName_SummaryTotalDollars] )
					{
						m_totalDollarsObligated = [m_currentXMLStr doubleValue];
					}
					else if ( [elementName isEqualToString:kName_SummaryDistrictRank] )
					{
						m_districtRank = [m_currentXMLStr doubleValue];
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
	NSLog( @"District %@ XMLParser error: %@",m_district,[parseError localizedDescription] );
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	NSLog( @"District %@ XMLParser validation error: %@",m_district,[validError localizedDescription] );
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
}




@end

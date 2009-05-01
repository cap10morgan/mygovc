//
//  ContractorSpendingData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ContractorSpendingData.h"
#import "SpendingDataManager.h"

static const int kNumContractorsToQuery = 100;


@implementation ContractorInfo

@synthesize m_parentCompany;
@synthesize m_fiscalYear;
@synthesize m_obligatedAmount;
@synthesize m_parentDUNS;

- (id)init
{
	if ( self = [super init] )
	{
		m_parentCompany = nil;
		m_additionalNames = nil;
		m_fiscalYear = 0;
		m_obligatedAmount = 0.00;
		m_parentDUNS = 0;
	}
	return self;
}


- (void)dealloc
{
	[m_parentCompany release];
	[m_additionalNames release];
	[super dealloc];
}


- (NSArray *)additionalNames
{
	return m_additionalNames;
}

- (void)setAdditionalNamesFromString:(NSString *)namesSeparatedBySemiColon
{
	[m_additionalNames release]; m_additionalNames = nil;
	
	m_additionalNames = [[namesSeparatedBySemiColon componentsSeparatedByString:@"; "] retain];
}

- (NSComparisonResult)compareDollarsWith:(ContractorInfo *)that
{
	if ( m_obligatedAmount < that.m_obligatedAmount )
	{
		return NSOrderedDescending;
	}
	else if ( m_obligatedAmount > that.m_obligatedAmount )
	{
		return NSOrderedAscending;
	}
	else
	{
		return NSOrderedSame;
	}
}

- (NSComparisonResult)compareNameWith:(ContractorInfo *)that
{
	return [m_parentCompany caseInsensitiveCompare:that.m_parentCompany];
}

@end


@implementation ContractorSpendingData

@synthesize isDataAvailable;
@synthesize isBusy;

static NSString *kName_Data = @"data";
static NSString *kName_Record = @"record";
static NSString *kName_Parent = @"mod_parent";
static NSString *kName_AdditionalNames = @"name_add";
static NSString *kName_FiscalYear = @"fiscal_year";
static NSString *kName_ObligatedAmt = @"obligatedAmount";
static NSString *kName_ParentDUNS = @"eeParentDuns";


- (id)init
{
	if ( self = [super init] )
	{
		isDataAvailable = NO;
		isBusy = NO;
		
		m_infoSortedByName = [[NSMutableArray alloc] initWithCapacity:kNumContractorsToQuery];
		m_infoSortedByDollars = [[NSMutableArray alloc] initWithCapacity:kNumContractorsToQuery];
		
		m_xmlParser = nil;
		m_currentXMLStr = nil;
		
		m_notifyTarget = nil;
	}
	return self;
}


- (void)dealloc
{
	[m_infoSortedByName release];
	[m_infoSortedByDollars release];
	[m_xmlParser release];
	[m_currentXMLStr release];
	[m_currentContractorInfo release];
	[m_notifyTarget release];
	[super dealloc];
}


- (NSArray *)contractorsSortedBy:(SpendingSortMethod)order
{
	if ( !isDataAvailable ) return nil;
	
	switch ( order )
	{
		default:
		case eSpendingSortDollars:
			return m_infoSortedByDollars;
			break;
		
		case eSpendingSortContractor:
			return m_infoSortedByName;
			break;
	}
}


- (ContractorInfo *)contractorAtIndex:(NSInteger)idx whenSortedBy:(SpendingSortMethod)order
{
	if ( !isDataAvailable ) return nil;
	if ( idx >= [m_infoSortedByName count] ) return nil;
	
	switch ( order )
	{
		default:
		case eSpendingSortDollars:
			return (ContractorInfo *)[m_infoSortedByDollars objectAtIndex:idx];
			break;
			
		case eSpendingSortContractor:
			return (ContractorInfo *)[m_infoSortedByName objectAtIndex:idx];
			break;
	}
}


// Asynchronous download of 
- (void)downloadDataWithCallback:(SEL)sel onObject:(id)obj synchronously:(BOOL)waitForData
{
	if ( isBusy ) return;
	
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
	
	// get the current year
	NSCalendar *gregorian = [[NSCalendar alloc]
							 initWithCalendarIdentifier:NSGregorianCalendar];
	NSInteger year = [[gregorian components:NSYearCalendarUnit fromDate:[NSDate date]] year];
	[gregorian release];
	
	NSString *urlStr = [DataProviders USASpending_topContractorURL:year 
												 maxNumContractors:kNumContractorsToQuery 
														withDetail:eSpendingDetailLow 
														  sortedBy:eSpendingSortDollars 
															xmlURL:YES];
	NSURL *dataURL = [NSURL URLWithString:urlStr];
	
	// kick off the download/parsing of XML data 
	if ( !waitForData )
	{
		[m_xmlParser parseXML:dataURL withParserDelegate:self withStringEncoding:NSMacOSRomanStringEncoding];
	}
	else
	{
		// download synchronously :-)
		//NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:detailSummaryURL];
		NSData *data = [NSData dataWithContentsOfURL:dataURL];
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
	//NSLog( @"[ContractorSpendingData] started XML Download..." );
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	isDataAvailable = success;
	isBusy = NO;
	
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
	//NSLog( @"[ContractorSpendingData] XML parsing ended %@", (success ? @"successfully." : @" in failure!") );
	
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
		//NSLog( @"[ContractorSpendingData] XML Parsing started..." );
		m_parsingData = YES;
	}
    else if ( m_parsingData && [elementName isEqualToString:kName_Record] ) 
	{
		m_parsingRecord = YES;
		[m_currentContractorInfo release];
		m_currentContractorInfo = [[ContractorInfo alloc] init];
    } 
	else
	{
		// nothing to do...
	}
	
	if ( m_parsingRecord )
	{
		[m_currentXMLStr release];
		m_currentXMLStr = [[NSMutableString alloc] initWithString:@""];
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	if ( [elementName isEqualToString:kName_Data] )
	{
		m_parsingData = NO;
		m_parsingRecord = NO;
	}
	else if ( m_parsingData && [elementName isEqualToString:kName_Record] ) 
	{
		m_parsingRecord = NO;
		// Add the new records to each array and keep it sorted appropriately
		[m_infoSortedByName addObject:m_currentContractorInfo];
		[m_infoSortedByName sortUsingSelector:@selector(compareNameWith:)];
		
		[m_infoSortedByDollars addObject:m_currentContractorInfo];
		[m_infoSortedByDollars sortUsingSelector:@selector(compareDollarsWith:)];
		
		[m_currentContractorInfo release];
		m_currentContractorInfo = nil;
	} 
	else if ( m_parsingRecord && [elementName isEqualToString:kName_Parent] ) 
	{
		m_currentContractorInfo.m_parentCompany = m_currentXMLStr;
    }
	else if ( m_parsingRecord && [elementName isEqualToString:kName_FiscalYear] )
	{
		m_currentContractorInfo.m_fiscalYear = [m_currentXMLStr integerValue];
	}
	else if ( m_parsingRecord && [elementName isEqualToString:kName_AdditionalNames] )
	{
		[m_currentContractorInfo setAdditionalNamesFromString:m_currentXMLStr];
	}
	else if ( m_parsingRecord && [elementName isEqualToString:kName_ParentDUNS] ) 
	{
		m_currentContractorInfo.m_parentDUNS = [m_currentXMLStr integerValue];
	}
	else if ( m_parsingRecord && [elementName isEqualToString:kName_ObligatedAmt] )
	{
		m_currentContractorInfo.m_obligatedAmount = [m_currentXMLStr doubleValue];
	}
	
	[m_currentXMLStr release];
	m_currentXMLStr = nil;
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	if ( m_parsingRecord && (nil != m_currentXMLStr) ) [m_currentXMLStr appendString:string];
}


// XXX - handle XML parse errors in some sort of graceful way...
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
	NSLog( @"[ContractorSpendingData] XMLParser error: %@",[parseError localizedDescription] );
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	NSLog( @"[ContractorSpendingData] XMLParser validation error: %@",[validError localizedDescription] );
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
	}
}



@end

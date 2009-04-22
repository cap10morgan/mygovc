//
//  SpendingSummaryData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ContractorSpendingData.h"
#import "LegislatorContainer.h"
#import "PlaceSpendingData.h"
#import "SpendingSummaryData.h"

enum
{
	eSection_Legislators    = 0,
	eSection_Summary        = 1,
	eSection_TopContractors = 2,
	eSection_TopAgencies    = 3,
	eSection_TopCategories  = 4,
	eSection_TopCDistricts  = 5,
	
	eSection_Contractor      = 0,
	eSection_AdditionalNames = 1,
};

#define KEY_LEGISLATORS      @"Legislators"
#define KEY_SUMMARY          @"Summary" 
#define KEY_TOPCONTRACTORS   @"Top Contractors"
#define KEY_TOPAGENCIES      @"Top Govt. Agencies"
#define KEY_TOPCATEGORIES    @"Top Contract Categories"
#define KEY_TOPCDISTS        @"Top Districts where Work is Performed"
#define KEY_CONTRACTOR       @"Contractor"
#define KEY_ADDITIONAL_NAMES @"Additional Names"

#define PLACE_DATA_SECTIONS \
			KEY_LEGISLATORS, \
			KEY_SUMMARY, \
			KEY_TOPCONTRACTORS, \
			KEY_TOPAGENCIES, \
			KEY_TOPCATEGORIES, \
			KEY_TOPCDISTS, \
			nil

#define CNTR_DATA_SECTIONS \
			KEY_CONTRACTOR, \
			KEY_ADDITIONAL_NAMES, \
			nil

// 
// Setup the Summary section
// 
#define SUMMARY_ROWKEY \
				@"01_Fiscal Year:", \
				@"02_Total Dollars Obligated:",\
				@"03_Rank:",@"04_Total Contractors:", \
				@"05_Total Transactions:",nil

#define SUMMARY_ROWSEL \
			@selector(fiscalYearDescrip), \
			@selector(totalDollarsStr), \
			@selector(rankStrAlt), \
			@selector(totalContractorsStr),\
			@selector(totalTransactionsStr)

#define SUMMARY_ROWACTION \
			@selector(rowActionNone:), \
			@selector(rowActionNone:), \
			@selector(rowActionNone:), \
			@selector(rowActionURL:), \
			@selector(rowActionURL:)

#define SUMMARY_ROWURLSEL \
			nil, nil, nil, \
			@selector(getContractorListURL), \
			@selector(getTransactionListURL)


@interface SpendingSummaryData (private)
	- (NSArray *)setupPlaceDataSection:(NSInteger)section;
	- (NSArray *)setupContractorDataSection:(NSInteger)section;
@end


@implementation SpendingSummaryData

- (id)init
{
	if ( self = [super init] )
	{
		m_placeData = nil;
		m_contractorData = nil;
		m_dataSections = [[NSMutableArray alloc] init];
	}
	return self;
}


- (void)dealloc
{
	[m_placeData release];
	[m_contractorData release];
	// we don't have to release 'm_dataSections' - that happens in our super class :-)
	[super dealloc];
}


- (void)setPlaceData:(PlaceSpendingData *)data
{
	[m_contractorData release]; m_contractorData = nil;
	[m_placeData release]; 
	m_placeData = [data retain];
	
	m_dataSections = [[NSMutableArray alloc] initWithObjects:PLACE_DATA_SECTIONS];
	
	if ( nil == m_placeData ) return;
	
	// allocate data
	[m_data release];
	m_data = [[NSMutableArray alloc] initWithCapacity:[m_dataSections count]];
	
	for ( NSInteger ii = 0; ii < [m_dataSections count]; ++ii )
	{
		NSArray *sectionData = [self setupPlaceDataSection:ii];
		if ( nil != sectionData )
		{
			[m_data addObject:sectionData];
		}
		[sectionData release];
	}
}


- (void)setContractorData:(ContractorInfo *)data
{
	[m_placeData release]; m_placeData = nil;
	[m_contractorData release]; 
	m_contractorData = [data retain];
	
	m_dataSections = [[NSMutableArray alloc] initWithObjects:CNTR_DATA_SECTIONS];
	
	if ( nil == m_contractorData ) return;
	
	// allocate data
	[m_data release];
	m_data = [[NSMutableArray alloc] initWithCapacity:[m_dataSections count]];
	
	for ( NSInteger ii = 0; ii < [m_dataSections count]; ++ii )
	{
		NSArray *sectionData = [self setupContractorDataSection:ii];
		if ( nil != sectionData )
		{
			[m_data addObject:sectionData];
		}
		[sectionData release];
	}
}


#pragma mark BillInfoData Private 


- (NSArray *)setupPlaceDataSection:(NSInteger)section
{
	NSMutableArray *retVal = [[NSMutableArray alloc] init];
	
	switch ( section )
	{
		case eSection_Legislators:
		{
			NSArray *legislators = [m_placeData placeLegislators:YES]; // include senators in district list!
			NSEnumerator *lenum = [legislators objectEnumerator];
			id legislator;
			
			while ( legislator = [lenum nextObject] )
			{
				TableRowData *rd = [[TableRowData alloc] init];
				
				LegislatorContainer *lc = (LegislatorContainer *)legislator;
				NSString *legName = [NSString stringWithFormat:@"%@ (%@)",
												 [lc shortName],
												 [lc party]
									 ];
				
				UIColor *c = [LegislatorContainer partyColor:[lc party]];
				
				NSString *urlStr = [NSString stringWithFormat:@"mygov://congress/%@",
												[lc bioguide_id]
									];
				rd.title = legName;
				rd.titleColor = c;
				rd.titleFont = [UIFont boldSystemFontOfSize:14.0f];
				
				rd.url = [NSURL URLWithString:urlStr];
				rd.action = @selector(rowActionURL:);
				
				[retVal addObject:rd];
				[rd release];
			}
		}
			break;
		case eSection_Summary:
		{
			NSArray *keys = [NSArray arrayWithObjects:SUMMARY_ROWKEY];
			SEL dataSelector[] = { SUMMARY_ROWSEL };
			SEL dataUrlSel[] = { SUMMARY_ROWURLSEL };
			SEL dataAction[] = { SUMMARY_ROWACTION };
			
			for ( NSInteger ii = 0; ii < [keys count]; ++ii )
			{
				NSString *value = [m_placeData performSelector:dataSelector[ii]];
				if ( [value length] > 0 )
				{
					TableRowData *rd = [[TableRowData alloc] init];
					
					rd.title = [keys objectAtIndex:ii];
					rd.titleColor = [UIColor blackColor];
					rd.titleFont = [UIFont boldSystemFontOfSize:16.0f];
					rd.line2 = value;
					rd.line2Color = [UIColor darkGrayColor];
					rd.line2Font = [UIFont systemFontOfSize:16.0f];
					
					rd.url = nil;
					if ( nil != dataUrlSel[ii] )
					{
						rd.url = [m_placeData performSelector:dataUrlSel[ii]];
					}
					
					rd.action = dataAction[ii];
					[retVal addObject:rd];
					[rd release];
				} // if ( [value length] > 0 )
			}
		}
			[retVal sortUsingSelector:@selector(compareTitle:)];
			break;	
		case eSection_TopContractors:
		{
			NSDictionary *top = [m_placeData topContractors];
			NSArray *sortedTopKeys = [top keysSortedByValueUsingSelector:@selector(compare:)];
			NSEnumerator *tenum = [sortedTopKeys reverseObjectEnumerator];
			id k;
			while ( k = [tenum nextObject] )
			{
				NSString *contractor = (NSString *)k;
				CGFloat dollars = [[top valueForKey:contractor] floatValue];
				
				TableRowData *rd = [[TableRowData alloc] init];
				
				rd.line1 = contractor;
				rd.line1Color = [UIColor blackColor];
				rd.line1Font = [UIFont boldSystemFontOfSize:14.0f];
				rd.line2 = [NSString stringWithFormat:@"   $%0.3f M",(dollars/1000000)];
				rd.line2Color = [UIColor darkGrayColor];
				rd.line2Font = [UIFont systemFontOfSize:14.0f];
				
				NSString *urlStr = [DataProviders USASpending_contractorSearchURL:contractor forYear:m_placeData.m_year withDetail:eSpendingDetailMed sortedBy:eSpendingSortDollars xmlURL:NO];
				rd.url = [NSURL URLWithString:urlStr];
				rd.action = @selector(rowActionURL:);
				[retVal addObject:rd];
				[rd release];				
			}
		}
			break;
		case eSection_TopAgencies:
		{
			NSDictionary *top = [m_placeData topAgencies];
			NSArray *sortedTopKeys = [top keysSortedByValueUsingSelector:@selector(compare:)];
			NSEnumerator *tenum = [sortedTopKeys reverseObjectEnumerator];
			id k;
			while ( k = [tenum nextObject] )
			{
				NSString *contractor = (NSString *)k;
				CGFloat dollars = [[top valueForKey:contractor] floatValue];
				
				TableRowData *rd = [[TableRowData alloc] init];
				
				rd.line1 = contractor;
				rd.line1Color = [UIColor blackColor];
				rd.line1Font = [UIFont boldSystemFontOfSize:14.0f];
				rd.line2 = [NSString stringWithFormat:@"   $%0.3f M",(dollars/1000000)];
				rd.line2Color = [UIColor darkGrayColor];
				rd.line2Font = [UIFont systemFontOfSize:14.0f];
				
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];				
			}
		}
			break;
		case eSection_TopCategories:
		{
			NSDictionary *top = [m_placeData topCategories];
			NSArray *sortedTopKeys = [top keysSortedByValueUsingSelector:@selector(compare:)];
			NSEnumerator *tenum = [sortedTopKeys reverseObjectEnumerator];
			id k;
			while ( k = [tenum nextObject] )
			{
				NSString *contractor = (NSString *)k;
				CGFloat dollars = [[top valueForKey:contractor] floatValue];
				
				TableRowData *rd = [[TableRowData alloc] init];
				
				rd.line1 = contractor;
				rd.line1Color = [UIColor blackColor];
				rd.line1Font = [UIFont boldSystemFontOfSize:14.0f];
				rd.line2 = [NSString stringWithFormat:@"   $%0.3f M",(dollars/1000000)];
				rd.line2Color = [UIColor darkGrayColor];
				rd.line2Font = [UIFont systemFontOfSize:14.0f];
				
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];				
			}
		}
			break;
		case eSection_TopCDistricts:
		{
			NSDictionary *top = [m_placeData topCDistsWhereWorkPerformed];
			NSArray *sortedTopKeys = [top keysSortedByValueUsingSelector:@selector(compare:)];
			NSEnumerator *tenum = [sortedTopKeys reverseObjectEnumerator];
			id k;
			while ( k = [tenum nextObject] )
			{
				NSString *contractor = (NSString *)k;
				CGFloat dollars = [[top valueForKey:contractor] floatValue];
				
				TableRowData *rd = [[TableRowData alloc] init];
				
				rd.line1 = contractor;
				rd.line1Color = [UIColor blackColor];
				rd.line1Font = [UIFont boldSystemFontOfSize:14.0f];
				rd.line2 = [NSString stringWithFormat:@"   $%0.3f M",(dollars/1000000)];
				rd.line2Color = [UIColor darkGrayColor];
				rd.line2Font = [UIFont systemFontOfSize:14.0f];
				
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];				
			}
		}
			break;
		default:
			break;
			
	} // switch ( section )
	
	return retVal;
}


- (NSArray *)setupContractorDataSection:(NSInteger)section
{
	NSMutableArray *retVal = [[NSMutableArray alloc] init];
	
	switch ( section )
	{
		case eSection_Contractor:
		{
			TableRowData *rd = [[TableRowData alloc] init];
			rd.line1 = m_contractorData.m_parentCompany;
			rd.line1Color = [UIColor darkGrayColor];
			rd.line1Font = [UIFont systemFontOfSize:14.0f];
			NSString *urlStr = [DataProviders USASpending_contractorSearchURL:m_contractorData.m_parentCompany forYear:m_contractorData.m_fiscalYear withDetail:eSpendingDetailMed sortedBy:eSpendingSortDollars xmlURL:NO];
			rd.url = [NSURL URLWithString:urlStr];
			rd.action = @selector(rowActionURL:);
			[retVal addObject:rd];
			[rd release];
			
			rd = [[TableRowData alloc] init];
			rd.title = @"DUNS";
			rd.titleColor = [UIColor blackColor];
			rd.titleFont = [UIFont boldSystemFontOfSize:14.0f];
			rd.line1 = [NSString stringWithFormat:@"%0d",m_contractorData.m_parentDUNS];
			rd.line1Color = [UIColor darkGrayColor];
			rd.line1Font = [UIFont systemFontOfSize:14.0f];
			rd.url = nil;
			rd.action = @selector(rowActionNone:);
			[retVal addObject:rd];
			[rd release];
			
			rd = [[TableRowData alloc] init];
			rd.title = @"Total Obligated Amount";
			rd.titleColor = [UIColor blackColor];
			rd.titleFont = [UIFont boldSystemFontOfSize:14.0f];
			rd.line2 = [NSString stringWithFormat:@"   $%.3f M",(m_contractorData.m_obligatedAmount/1000000)];
			rd.line2Color = [UIColor darkGrayColor];
			rd.line2Font = [UIFont systemFontOfSize:14.0f];
			rd.url = nil;
			rd.action = @selector(rowActionNone:);
			[retVal addObject:rd];
			[rd release];
		}
			break;
		case eSection_AdditionalNames:
		{
			NSArray *names = [m_contractorData additionalNames];
			NSEnumerator *nenum = [names objectEnumerator];
			id nm;
			while ( nm = [nenum nextObject] )
			{
				TableRowData *rd = [[TableRowData alloc] init];
				rd.line1 = (NSString *)nm;
				rd.line1Color = [UIColor darkGrayColor];
				rd.line1Font = [UIFont systemFontOfSize:12.0f];
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];
			}
		}
			break;
		default:
			break;
	}
	
	return retVal;
}

@end

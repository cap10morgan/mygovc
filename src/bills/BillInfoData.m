//
//  BillInfoData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BillInfoData.h"
#import "BillContainer.h"
#import "CustomTableCell.h"
#import "LegislatorContainer.h"
#import "MiniBrowserController.h"


enum
{
	eSection_Info       = 0,
	eSection_Sponsor    = 1,
	eSection_CoSponsors = 2,
	eSection_History    = 3,
};

#define KEY_INFO      @"Bill Info" 
#define KEY_SPONSOR   @"Sponsor"
#define KEY_COSPONSOR @"CoSponsor(s)"
#define KEY_HISTORY   @"History"

// The order here _must_ correspond to the order in the enumeration above
#define DATA_SECTIONS	KEY_INFO, \
						KEY_SPONSOR, \
						KEY_COSPONSOR, \
						KEY_HISTORY, \
						nil


// 
// Setup the bill info section
// 
#define INFO_ROWKEY @"01_",@"02_",@"03_status", \
                    @"04_introduced",@"05_last action",nil

#define INFO_ROWSEL @selector(getShortTitle), \
                    @selector(summaryText), \
                    @selector(m_status), \
                    @selector(bornOnString),\
                    @selector(lastActionString)

#define INFO_ROWSUBSEL nil, \
					   nil, \
					   @selector(voteString), \
					   nil,\
					   nil

#define INFO_ROWACTION  @selector(rowActionURL:), \
                        @selector(rowActionNone:), \
                        @selector(rowActionNone:), \
                        @selector(rowActionNone:), \
                        @selector(rowActionNone:)

#define INFO_ROWURLSEL  @selector(getFullTextURL), \
                        nil, nil, nil, nil


@interface BillInfoData (private)
	- (NSArray *)setupDataSection:(NSInteger)section;
@end


@implementation BillInfoData

- (id)init
{
	if ( self = [super init] )
	{
		m_bill = nil;
		m_dataSections = [[NSMutableArray alloc] initWithObjects:DATA_SECTIONS];
	}
	return self;
}


- (void)dealloc
{
	[m_bill release];
	// we don't have to release 'm_dataSections' - that happens in our super class :-)
	[super dealloc];
}


- (void)setBill:(BillContainer *)bill
{
	[m_data release]; m_data = nil;
	[m_bill release]; m_bill = [bill retain];
	
	if ( nil == m_bill ) return;
	
	// allocate data
	m_data = [[NSMutableArray alloc] initWithCapacity:[m_dataSections count]];
	
	for ( NSInteger ii = 0; ii < [m_dataSections count]; ++ii )
	{
		NSArray *sectionData = [self setupDataSection:ii];
		if ( nil != sectionData )
		{
			[m_data addObject:sectionData];
		}
		[sectionData release];
	}
}


#pragma mark BillInfoData Private 


- (NSArray *)setupDataSection:(NSInteger)section
{
	NSMutableArray *retVal = [[NSMutableArray alloc] init];
	
	switch ( section )
	{
		case eSection_Info:
		{
			NSArray *keys = [NSArray arrayWithObjects:INFO_ROWKEY];
			SEL dataSelector[] = { INFO_ROWSEL };
			SEL dataSubSel[] = { INFO_ROWSUBSEL };
			SEL dataUrlSel[] = { INFO_ROWURLSEL };
			SEL dataAction[] = { INFO_ROWACTION };
			
			for ( NSInteger ii = 0; ii < [keys count]; ++ii )
			{
				NSString *value = [m_bill performSelector:dataSelector[ii]];
				if ( [value length] > 0 )
				{
					TableRowData *rd = [[TableRowData alloc] init];
					rd.title = [keys objectAtIndex:ii];
					rd.titleColor = [UIColor blackColor];
					rd.line1 = value;
					rd.line1Color = [UIColor darkGrayColor];
					if ( nil != dataSubSel[ii] )
					{
						rd.line2 = [m_bill performSelector:dataSubSel[ii]];
						rd.line2Font = [UIFont boldSystemFontOfSize:14.0f];
						if ( [rd.line2 isEqualToString:@"Passed"] )
						{
							rd.line2 = [NSString stringWithFormat:@"                    %@",rd.line2];
							rd.line2Color = [UIColor greenColor];
						}
						else if ( [rd.line2 isEqualToString:@"Failed"] )
						{
							rd.line2 = [NSString stringWithFormat:@"                    %@",rd.line2];
							rd.line2Color = [UIColor blackColor];
						}
						else
						{
							rd.line2Color = [UIColor darkGrayColor];
						}
					}
					rd.url = nil;
					if ( nil != dataUrlSel[ii] )
					{
						rd.url = [m_bill performSelector:dataUrlSel[ii]];
					}
					rd.action = dataAction[ii];
					[retVal addObject:rd];
					[rd release];
				}
			}
		}
			break;
			
		case eSection_Sponsor:
		{
			TableRowData *rd = [[TableRowData alloc] init];
			LegislatorContainer *lc = [m_bill sponsor];
			NSInteger district = [[lc district] integerValue];
			rd.title = [NSString stringWithFormat:@"%@ (%@), %@%@",
									[lc shortName],
									[lc party],
									[lc state],
									([[lc district] length] > 0 ? [NSString stringWithFormat:@"-%02d",district] : @"")
			           ];
			rd.titleColor = [LegislatorContainer partyColor:[lc party]];
			NSString *appUrlStr = [NSString stringWithFormat:@"mygov://congress/%@",[lc bioguide_id]];
			NSURL *appUrl = [[NSURL alloc] initWithString:appUrlStr];
			rd.url = appUrl;
			rd.action = @selector(rowActionURL:);
			[appUrl release];
			[retVal addObject:rd];
			[rd release];
		}
			break;
			
		case eSection_CoSponsors:
		{
			NSArray *csArray = [m_bill cosponsors];
			NSEnumerator *csEnum = [csArray objectEnumerator];
			id legislator;
			while ( legislator = [csEnum nextObject] )
			{
				TableRowData *rd = [[TableRowData alloc] init];
				LegislatorContainer *lc = (LegislatorContainer *)legislator;
				NSInteger district = [[lc district] integerValue];
				rd.title = [NSString stringWithFormat:@"%@ (%@), %@%@",
										[lc shortName],
										[lc party],
										[lc state],
										([[lc district] length] > 0 ? [NSString stringWithFormat:@"-%02d",district] : @"")
							];
				rd.titleColor = [LegislatorContainer partyColor:[lc party]];
				NSString *appUrlStr = [NSString stringWithFormat:@"mygov://congress/%@",[lc bioguide_id]];
				NSURL *appUrl = [[NSURL alloc] initWithString:appUrlStr];
				rd.url = appUrl;
				rd.action = @selector(rowActionURL:);
				[appUrl release];
				[retVal addObject:rd];
				[rd release];
			}
		}
			break;
		
		case eSection_History:
		{
			NSArray *hArray = [m_bill billActions];
			NSEnumerator *hEnum = [hArray objectEnumerator];
			id bi;
			while ( bi = [hEnum nextObject] )
			{
				TableRowData *rd = [[TableRowData alloc] init];
				BillAction *bAction = (BillAction *)bi;
				rd.title = @"";
				rd.line1 = [bAction shortDescrip];
				rd.line1Color = [UIColor blackColor];
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];
			}
		}
			break;
		
	} // switch ( section )
	
	
	[retVal sortUsingSelector:@selector(compareTitle:)];
	return retVal;
}


@end

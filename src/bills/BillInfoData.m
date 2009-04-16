//
//  BillInfoData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BillInfoData.h"
#import "BillContainer.h"
#import "LegislatorContainer.h"
#import "MiniBrowserController.h"

@implementation BillRowData

@synthesize title, line1, line2, url, action;

- (NSComparisonResult)compareTitle:(BillRowData *)other
{
	return [title compare:other.title];
}

@end



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
                    @selector(titleNoBillNum), \
                    @selector(m_status), \
                    @selector(bornOnString),\
                    @selector(lastActionString)

#define INFO_ROWACTION  @selector(rowActionNone:), \
                        @selector(rowActionNone:), \
                        @selector(rowActionNone:), \
                        @selector(rowActionNone:), \
                        @selector(rowActionNone:)


@interface BillInfoData (private)
	- (BillRowData *)dataForIndexPath:(NSIndexPath *)indexPath;
	- (NSArray *)setupDataSection:(NSInteger)section;
	- (void)rowActionNone:(NSIndexPath *)indexPath;
	- (void)rowActionURL:(NSIndexPath *)indexPath;
@end


@implementation BillInfoData

static NSInteger        s_sectionRefCount = 0;
static NSMutableArray * s_dataSections = NULL;


- (id)init
{
	if ( self = [super init] )
	{
		m_notifyTarget = nil;
		m_notifySelector = nil;
		m_bill = nil;
		m_data = nil;
		m_actionParent = nil;
		
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
	[m_bill release];
	[m_data release];
	
	if ( 0 == --s_sectionRefCount )
	{
		[s_dataSections release]; s_dataSections = NULL;
	}
	
	[super dealloc];
}


- (void)setNotifyTarget:(id)target andSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = target;
	m_notifySelector = sel;
}


- (void)setBill:(BillContainer *)bill
{
	[m_data release]; m_data = nil;
	[m_bill release]; m_bill = [bill retain];
	
	// allocate data
	m_data = [[NSMutableArray alloc] initWithCapacity:[s_dataSections count]];
	
	for ( NSInteger ii = 0; ii < [s_dataSections count]; ++ii )
	{
		NSArray *sectionData = [self setupDataSection:ii];
		if ( nil != sectionData )
		{
			[m_data addObject:sectionData];
		}
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
	return 35.0f;
	/*
	BillRowData *rd = [self dataForIndexPath:indexPath];
	return [LegislatorInfoCell cellHeightForText:rd.value withKeyname:rd.field];
	*/
}

/*
- (void)setInfoCell:(LegislatorInfoCell *)cell forIndex:(NSIndexPath *)indexPath
{
	if ( nil == cell ) return;
	if ( nil == indexPath ) return;
	
	BillRowData *rd = [self dataForIndexPath:indexPath];
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
*/


- (BillRowData *)billForIndex:(NSIndexPath *)indexPath
{
	return [self dataForIndexPath:indexPath];
}


- (void)performActionForIndex:(NSIndexPath *)indexPath withParent:(id)parent
{
	m_actionParent = [parent retain];
	
	BillRowData *rd = [self dataForIndexPath:indexPath];
	if ( nil != rd && nil != rd.action )
	{
		[self performSelector:rd.action withObject:indexPath];
	}
	
	[m_actionParent release]; m_actionParent = nil;
}


#pragma mark BillInfoData Private 


- (BillRowData *)dataForIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	
	if ( section >= [m_data count] ) return nil;
	
	NSArray *secArray = [m_data objectAtIndex:section];
	if ( row >= [secArray count] ) return nil;
	
	// 
	// Get the key/value pair from the single-object-dictionary stored
	// in the 'm_data' object at: m_data[indexPath.section][indexPath.row]
	// 
	return [secArray objectAtIndex:row];
}


- (NSArray *)setupDataSection:(NSInteger)section
{
	NSMutableArray *retVal = [[NSMutableArray alloc] init];
	
	switch ( section )
	{
		case eSection_Info:
		{
			NSArray *keys = [NSArray arrayWithObjects:INFO_ROWKEY];
			SEL dataSelector[] = { INFO_ROWSEL };
			SEL dataAction[] = { INFO_ROWACTION };
			for ( NSInteger ii = 0; ii < [keys count]; ++ii )
			{
				NSString *value = [m_bill performSelector:dataSelector[ii]];
				if ( [value length] > 0 )
				{
					BillRowData *rd = [[BillRowData alloc] init];
					rd.title = [keys objectAtIndex:ii];
					rd.line1 = value;
					rd.url = nil;
					rd.action = dataAction[ii];
					[retVal addObject:rd];
					[rd release];
				}
			}
		}
			break;
		case eSection_Sponsor:
		{
			LegislatorContainer *lc = [m_bill sponsor];
			BillRowData *rd = [[BillRowData alloc] init];
			rd.title = @"";
			rd.line1 = [lc shortName];
			NSString *appUrlStr = [NSString stringWithFormat:@"mygov://congress/house:0:0:%@",[lc bioguide_id]];
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
				LegislatorContainer *lc = (LegislatorContainer *)legislator;
				BillRowData *rd = [[BillRowData alloc] init];
				rd.title = @"";
				rd.line1 = [lc shortName];
				NSString *appUrlStr = [NSString stringWithFormat:@"mygov://congress/house:0:0:%@",[lc bioguide_id]];
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
				BillAction *bAction = (BillAction *)bi;
				BillRowData *rd = [[BillRowData alloc] init];
				rd.title = @"";
				rd.line1 = [bAction shortDescrip];
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];
			}
		}
			break;
	}
	
	
	[retVal sortUsingSelector:@selector(compareTitle:)];
	return retVal;
}


- (void)rowActionNone:(NSIndexPath *)indexPath
{
	(void)indexPath;
	return;
}


- (void)rowActionURL:(NSIndexPath *)indexPath
{
	BillRowData *rd = [self dataForIndexPath:indexPath];
	if ( nil == rd ) return;
	
	NSURL *url;
	if ( [[rd.url absoluteString] length] > 0 )
	{
		url = rd.url;
	}
	else
	{
		url = [NSURL URLWithString:rd.line2];
	}
	
	NSString *urlStr = [url absoluteString];
	
	// look for in-app URLS and open them appropriately
	NSRange mgRange = {0,5};
	if ( ([urlStr length] >= mgRange.length) && 
		 (NSOrderedSame == [urlStr compare:@"mygov" options:NSCaseInsensitiveSearch range:mgRange])
		)
	{
		[[UIApplication sharedApplication] openURL:url];
	}
	else
	{
		// open other URLs in our mini browser
		MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:url];
		[mbc display:m_actionParent];
	}
}


@end

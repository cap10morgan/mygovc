//
//  BillContainer.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"
#import "BillContainer.h"
#import "CongressDataManager.h"
#import "LegislatorContainer.h"

@implementation BillAction
	@synthesize m_type, m_date, m_descrip, m_voteResult, m_how;
@end



@implementation BillContainer

@synthesize m_id, m_bornOn, m_title, m_type, m_number, m_status, m_summary;


+ (BillType)billTypeFromString:(NSString *)string
{
	if ( [string isEqualToString:@"h"] )
	{
		return eBillType_h;
	}
	else if ( [string isEqualToString:@"s"] )
	{
		return eBillType_s;
	}
	else if ( [string isEqualToString:@"hj"] )
	{
		return eBillType_hj;
	}
	else if ( [string isEqualToString:@"sj"] )
	{
		return eBillType_sj;
	}
	else if ( [string isEqualToString:@"hc"] )
	{
		return eBillType_hc;
	}
	else if ( [string isEqualToString:@"sc"] )
	{
		return eBillType_sc;
	}
	else if ( [string isEqualToString:@"hr"] )
	{
		return eBillType_hr;
	}
	else if ( [string isEqualToString:@"sr"] )
	{
		return eBillType_sr;
	}
	else
	{
		return eBillType_unknown;
	}
}


+ (NSString *)getBillTypeDescrip:(BillType)type
{
	switch ( type )
	{
		case eBillType_h:
			return @"House Bill";
		case eBillType_s:
			return @"Senate Bill";
		case eBillType_hj:
			return @"House Joint Resolution";
		case eBillType_sj:
			return @"Senate Joint Resolution";
		case eBillType_hc:
			return @"House Concurrent Resolution";
		case eBillType_sc:
			return @"Senate Concurrent Resolution";
		case eBillType_hr:
			return @"House Resolution";
		case eBillType_sr:
			return @"Senate Resolution";
		default:
			return @"Unknown Bill Type";
	}
}


+ (NSString *)getBillTypeShortDescrip:(BillType)type
{
	switch ( type )
	{
		case eBillType_h:
			return @"H.R.";
		case eBillType_s:
			return @"S.";
		case eBillType_hj:
			return @"H. Joint Res.";
		case eBillType_sj:
			return @"S. Joint Res.";
		case eBillType_hc:
			return @"H. Con. Res.";
		case eBillType_sc:
			return @"S. Con. Res.";
		case eBillType_hr:
			return @"H. Res.";
		case eBillType_sr:
			return @"S. Res.";
		default:
			return @"??";
	}
}


- (id)init
{
	if ( self = [super init] )
	{
		m_title = nil;
		m_type = eBillType_unknown;
		m_number = 0;
		m_status = nil;
		m_lastActionDate = nil;
		m_lastAction = nil;
		
		m_sponsors = [[NSMutableArray alloc] initWithCapacity:2];
		m_cosponsors = [[NSMutableArray alloc] initWithCapacity:4];
		m_history = [[NSMutableArray alloc] initWithCapacity:2];
	}
	return self;
}


- (void)dealloc
{
	[m_title release];
	[m_status release];
	[m_sponsors release];
	[m_cosponsors release];
	[m_lastActionDate release];
	[m_history release];
	[super dealloc];
}


- (void)addSponsor:(NSString *)bioguideID
{
	CongressDataManager *cdm = [myGovAppDelegate sharedCongressData];
	LegislatorContainer *lc = [cdm getLegislatorFromBioguideID:bioguideID];
	if ( nil != lc )
	{
		[m_sponsors addObject:lc];
	}
}


- (void)addCoSponsor:(NSString *)bioguideID
{
	CongressDataManager *cdm = [myGovAppDelegate sharedCongressData];
	LegislatorContainer *lc = [cdm getLegislatorFromBioguideID:bioguideID];
	if ( nil != lc )
	{
		[m_cosponsors addObject:lc];
	}
}


- (void)addBillAction:(BillAction *)action
{
	[m_history addObject:action];
	if ( nil == m_lastActionDate )
	{
		m_lastActionDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:1.0f];
	}
	if ( NSOrderedDescending == [m_lastActionDate compare:action.m_date] )
	{
		[m_lastActionDate release];
		m_lastActionDate = [action.m_date retain];
		m_lastAction = action;
	}
}


- (NSDate *)lastActionDate
{
	return m_lastActionDate;
}


- (BillAction *)lastBillAction
{
	return m_lastAction;
}


- (NSString *)getShortTitle
{
	NSString *shortTitle = [[[NSString alloc] initWithFormat:@"%@ %d",
								[BillContainer getBillTypeShortDescrip:m_type],
								m_number
							] autorelease];
	return shortTitle;
}


@end

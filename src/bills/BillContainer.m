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

@synthesize m_id, m_type, m_date, m_descrip, m_voteResult, m_how;

- (NSString *)shortDescrip
{
	NSUInteger compsFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	NSDateComponents *actionDate = [[NSCalendar currentCalendar] components:compsFlags fromDate:m_date];
	
	NSString *desc = [[[NSString alloc] initWithFormat:@"%04d-%02d-%02d: %@",
											[actionDate year],
											[actionDate month],
											[actionDate day],
											([m_descrip length] > 0 ? m_descrip : m_type)
					  ] autorelease];
	return desc;
}

@end



@implementation BillContainer

@synthesize m_id, m_bornOn, m_title, m_type, m_number, m_status, m_summary;

static NSString *kGovtrackBillTextURL_fmt = @"http://www.govtrack.us/data/us/bills.text/%d/%@/%@%d.html";


+ (NSString *)stringFromBillType:(BillType)type
{
	switch ( type )
	{
		case eBillType_h:
			return @"h";
		case eBillType_s:
			return @"s";
		case eBillType_hj:
			return @"hj";
		case eBillType_sj:
			return @"sj";
		case eBillType_hc:
			return @"hc";
		case eBillType_sc:
			return @"sc";
		case eBillType_hr:
			return @"hr";
		case eBillType_sr:
			return @"sr";
		default:
			return nil;
	}
}


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


- (NSComparisonResult)lastActionDateCompare:(BillContainer *)that
{
	return [[that lastActionDate] compare:m_lastActionDate];
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
	//if ( NSOrderedDescending == [m_lastActionDate compare:action.m_date] )
	if ( nil == m_lastAction || action.m_id > m_lastAction.m_id )
	{
		[m_lastActionDate release];
		m_lastActionDate = [action.m_date retain];
		m_lastAction = action;
	}
}


- (NSString *)titleNoBillNum
{
	NSRange space = [m_title rangeOfString:@" "];
	NSInteger spaceIdx = (space.length > 0 ? space.location + 1 : 0);
	
	return [m_title substringFromIndex:spaceIdx];
}


- (NSString *)bornOnString
{
	NSUInteger compsFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	NSDateComponents *actionDate = [[NSCalendar currentCalendar] components:compsFlags fromDate:m_bornOn];
	
	NSString *str = [[[NSString alloc] initWithFormat:@"%04d-%02d-%02d",
					  [actionDate year],
					  [actionDate month],
					  [actionDate day]
					  ] autorelease];
	return str;
}


- (LegislatorContainer *)sponsor
{
	if ( [m_sponsors count] > 0 )
	{
		return [m_sponsors objectAtIndex:0];
	}
	else return nil;
}


- (NSArray *)cosponsors
{
	return (NSArray *)m_cosponsors;
}


- (NSDate *)lastActionDate
{
	return m_lastActionDate;
}


- (NSString *)lastActionString
{
	NSUInteger compsFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
	NSDateComponents *actionDate = [[NSCalendar currentCalendar] components:compsFlags fromDate:m_lastActionDate];
	
	NSString *str = [[[NSString alloc] initWithFormat:@"%04d-%02d-%02d",
										   [actionDate year],
										   [actionDate month],
										   [actionDate day]
					   ] autorelease];
	return str;
}


- (BillAction *)lastBillAction
{
	return m_lastAction;
}


- (NSArray *)billActions
{
	return (NSArray *)m_history;
}


- (NSString *)getShortTitle
{
	NSString *shortTitle = [[[NSString alloc] initWithFormat:@"%@ %d",
								[BillContainer getBillTypeShortDescrip:m_type],
								m_number
							] autorelease];
	return shortTitle;
}


- (NSURL *)getFullTextURL
{
	CongressDataManager *cdm = [myGovAppDelegate sharedCongressData];
	
	NSString *urlStr = [[NSString alloc] initWithFormat:kGovtrackBillTextURL_fmt,
											[cdm currentCongressSession],
											[BillContainer stringFromBillType:m_type],
											[BillContainer stringFromBillType:m_type],
											m_number,
											@"" // XXX - "ih", "eh" "ih.gen", "rfs", etc.
						];
	NSURL *url = [[[NSURL alloc] initWithString:urlStr] autorelease];
	return url;
}


- (NSString *)voteString
{
	VoteResult v = [m_lastAction m_voteResult];
	if ( eVote_passed == v )
	{
		return @"Passed";
	}
	else if ( eVote_failed == v )
	{
		return @"Failed";
	}
	else
	{
		return nil;
	}
}


@end

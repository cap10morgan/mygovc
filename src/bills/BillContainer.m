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
#import "DataProviders.h"
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

static NSString *kCache_IDKey                = @"BillID";
static NSString *kCache_TypeKey              = @"BillType";
static NSString *kCache_TitleKey             = @"BillTitle";
static NSString *kCache_NumberKey            = @"BillNumber";
static NSString *kCache_BornOnKey            = @"BillBornOn";
static NSString *kCache_StatusKey            = @"BillStatus";
static NSString *kCache_SummaryKey           = @"BillSummary";
static NSString *kCache_SponsorKey           = @"BillSponsor";
static NSString *kCache_CoSponsorKey         = @"BillCoSponsors";
static NSString *kCache_BillActionsKey       = @"BillHistory";
static NSString *kCache_Action_IDKey         = @"ActionID";
static NSString *kCache_Action_DateKey       = @"ActionDate";
static NSString *kCache_Action_HowKey        = @"ActionHow";
static NSString *kCache_Action_TypeKey       = @"ActionType";
static NSString *kCache_Action_DescripKey    = @"ActionDescrip";
static NSString *kCache_Action_VoteResultKey = @"ActionVoteResult";


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
		m_history = [[NSMutableArray alloc] initWithCapacity:6];
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


- (NSDictionary *)getBillDictionaryForCache
{
	NSMutableDictionary *billDict = [[[NSMutableDictionary alloc] init] autorelease];
	
	[billDict setValue:[NSNumber numberWithInt:m_id] forKey:kCache_IDKey];
	[billDict setValue:[NSNumber numberWithInt:[m_bornOn timeIntervalSinceReferenceDate]] forKey:kCache_BornOnKey];
	[billDict setValue:m_title forKey:kCache_TitleKey];
	[billDict setValue:[NSNumber numberWithInt:(int)m_type] forKey:kCache_TypeKey];
	[billDict setValue:[NSNumber numberWithInt:m_number] forKey:kCache_NumberKey];
	[billDict setValue:[m_status stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding] forKey:kCache_StatusKey];
	[billDict setValue:[m_summary stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding] forKey:kCache_SummaryKey];
	[billDict setValue:[[m_sponsors objectAtIndex:0] bioguide_id] forKey:kCache_SponsorKey];
	
	// co-sponsors
	NSMutableArray *coSponsorArray = [[NSMutableArray alloc] init];
	NSEnumerator *e = [m_cosponsors objectEnumerator];
	id lc;
	while ( lc = [e nextObject] )
	{
		[coSponsorArray addObject:[lc bioguide_id]];
	}
	
	if ( [coSponsorArray count] > 0 )
	{
		[billDict setValue:coSponsorArray forKey:kCache_CoSponsorKey];
	}
	[coSponsorArray release];
	
	// actions
	NSMutableArray *actions = [[NSMutableArray alloc] init];
	e = [m_history objectEnumerator];
	id ba;
	while ( ba = [e nextObject] )
	{
		NSMutableDictionary *actionDict = [[NSMutableDictionary alloc] init];
		[actionDict setValue:[NSNumber numberWithInt:[ba m_id]] forKey:kCache_Action_IDKey];
		[actionDict setValue:[ba m_type] forKey:kCache_Action_TypeKey];
		[actionDict setValue:[NSNumber numberWithInt:[[ba m_date] timeIntervalSinceReferenceDate]] forKey:kCache_Action_DateKey];
		[actionDict setValue:[[ba m_descrip] stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding] forKey:kCache_Action_DescripKey];
		[actionDict setValue:[NSNumber numberWithInt:(int)[ba m_voteResult]] forKey:kCache_Action_VoteResultKey];
		[actionDict setValue:[ba m_how] forKey:kCache_Action_HowKey];
		
		[actions addObject:actionDict];
		[actionDict release];
	}
	
	if ( [actions count] > 0 )
	{
		[billDict setValue:actions forKey:kCache_BillActionsKey];
	}
	[actions release];
	
	return (NSDictionary *)billDict;
}


- (id)initWithDictionary:(NSDictionary *)billData
{
	if ( self = [super init] )
	{
		m_id = [[billData objectForKey:kCache_IDKey] integerValue];
		m_bornOn = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:[[billData objectForKey:kCache_BornOnKey] integerValue]];
		m_title = [[NSString alloc] initWithString:[billData objectForKey:kCache_TitleKey]];
		m_type = (BillType)[[billData objectForKey:kCache_TypeKey] integerValue];
		m_number = [[billData objectForKey:kCache_NumberKey] integerValue];
		m_status = [[NSString alloc] initWithString:[[billData objectForKey:kCache_StatusKey] stringByReplacingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]];
		m_summary = [[NSString alloc] initWithString:[[billData objectForKey:kCache_SummaryKey] stringByReplacingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]]; 
		
		m_sponsors = [[NSMutableArray alloc] initWithCapacity:2];
		m_cosponsors = [[NSMutableArray alloc] initWithCapacity:4];
		m_history = [[NSMutableArray alloc] initWithCapacity:6];
		
		NSString *bioguideID = [billData objectForKey:kCache_SponsorKey];
		[self addSponsor:bioguideID];
		
		NSArray *cosponsors = [billData objectForKey:kCache_CoSponsorKey];
		NSEnumerator *e = [cosponsors objectEnumerator];
		id bID;
		while ( bID = [e nextObject] )
		{
			[self addCoSponsor:(NSString *)bID];
		}
		
		NSArray *actions = [billData objectForKey:kCache_BillActionsKey];
		e = [actions objectEnumerator];
		id bAction;
		while ( bAction = [e nextObject] )
		{
			// initialize the BillAction!
			BillAction *ba = [[BillAction alloc] init];
			NSDictionary *actionDict = (NSDictionary *)bAction;
			
			ba.m_id = [[actionDict objectForKey:kCache_Action_IDKey] integerValue];
			ba.m_type = [actionDict objectForKey:kCache_Action_TypeKey];
			NSDate *actDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:[[actionDict objectForKey:kCache_Action_DateKey] integerValue]];
			ba.m_date = actDate; [actDate release];
			ba.m_descrip = [[actionDict objectForKey:kCache_Action_DescripKey] stringByReplacingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding];
			ba.m_voteResult = (VoteResult)[[actionDict objectForKey:kCache_Action_VoteResultKey] integerValue];
			ba.m_how = [actionDict objectForKey:kCache_Action_HowKey];
			
			[self addBillAction:ba];
			[ba release];
		}
	}
	return self;
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
		m_lastAction = action; // don't need to retain this...
	}
}


- (NSString *)summaryText
{
	NSRange htmlBR = [m_summary rangeOfString:@"<br/>"];
	NSInteger brIdx = (htmlBR.length > 0 ? htmlBR.location + htmlBR.length : 0);
	
	NSString *summary = [[m_summary substringFromIndex:brIdx] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	summary = [summary stringByReplacingOccurrencesOfString:@"<br/>" withString:@""];
	if ( [summary length] > 0 ) return summary;
	
	// if the summary is blank - use the title
	NSRange space = [m_title rangeOfString:@" "];
	NSInteger spaceIdx = (space.length > 0 ? space.location + 1 : 0);
	return [[m_title substringFromIndex:spaceIdx] stringByReplacingOccurrencesOfString:@"<br/>" withString:@""];
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


- (NSString *)getIdent
{
	NSString *ident = [[[NSString alloc] initWithFormat:@"%@ %0d",
											[BillContainer stringFromBillType:m_type],
											m_number
					   ] autorelease];
	return ident;
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
	NSString *urlStr = [DataProviders Govtrack_FullBillTextURL:m_number withBillType:m_type];
	NSURL *url = [[[NSURL alloc] initWithString:urlStr] autorelease];
	return url;
}


- (NSString *)voteString
{
	// We can have a bill that was marked as "PASSED" or "FAILED"
	// and then have subsequent actions (such as moved from house to senate).
	// Because of this, I run through all the bill actions and find the latest
	// one with a valid voteResult...
	NSEnumerator *actEnum = [m_history objectEnumerator];
	id action;
	while ( action = [actEnum nextObject] )
	{
		if ( eVote_passed == [action m_voteResult] )
		{
			return @"Passed";
		}
		else if ( eVote_failed == [action m_voteResult] )
		{
			return @"Failed";
		}
	}
	return nil;
	
	/*
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
	*/
}


@end

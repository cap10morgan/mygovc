//
//  BillContainer.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BillContainer.h"

@implementation BillAction
	@synthesize m_type, m_date, m_descrip, m_voteResult;
@end



@implementation BillContainer

@synthesize m_title, m_type, m_number, m_status;


- (id)init
{
	if ( self = [super init] )
	{
		m_title = nil;
		m_type = eBillType_unknown;
		m_number = 0;
		m_status = nil;
		m_lastActionDate = nil;
		
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


- (void)addSponsor:(NSString *)openCongressID
{
	[m_sponsors addObject:openCongressID];
}


- (void)addCoSponsor:(NSString *)openCongressID
{
	[m_cosponsors addObject:openCongressID];
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
	}
}

- (NSDate *)lastActionDate
{
	return m_lastActionDate;
}

@end

//
//  CommunityItem.m
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//
#import <CoreLocation/CoreLocation.h>
#import "CommunityItem.h"

@implementation CommunityComment
@synthesize m_id, m_owner, m_title, m_text;
@end 


@implementation CommunityItem

@synthesize m_id, m_type;
@synthesize m_image, m_title, m_date;
@synthesize m_owner, m_summary, m_text;
@synthesize m_mygovURLTitle, m_mygovURL;
@synthesize m_webURLTitle, m_webURL;
@synthesize m_eventLocation;
@synthesize m_eventDate;

- (id)init
{
	if ( self = [super init] )
	{
		m_type = eCommunity_Feedback; // default type
		m_image = nil;
		m_title = nil;
		m_date = nil;
		m_owner = 0;
		m_summary = nil;
		m_text = nil;
		m_mygovURLTitle = nil;
		m_mygovURL = nil;
		m_webURLTitle = nil;
		m_webURL = nil;
		m_userComments = nil;
		m_eventLocation = nil;
		m_eventDate = nil;
		m_eventAttendees = nil;
	}
	
	return self;
}


- (void)dealloc
{
	[m_userComments release];
	[m_eventAttendees release];
	[super dealloc];
}


- (void)addComment:(NSString *)comment fromUser:(NSInteger)mygovUser withTitle:(NSString *)title
{
	if ( nil == m_userComments )
	{
		m_userComments = [[NSMutableArray alloc] initWithCapacity:2];
	}
	
	CommunityComment *cc = [[CommunityComment alloc] init];
	cc.m_text = comment;
	cc.m_title = title;
	cc.m_owner = mygovUser;
	
	[m_userComments addObject:cc];
}


- (void)addComment:(CommunityComment *)comment
{
	if ( nil == m_userComments )
	{
		m_userComments = [[NSMutableArray alloc] initWithCapacity:2];
	}
	[m_userComments addObject:comment];
}


- (NSArray *)comments
{
	return (NSArray *)m_userComments;
}


- (NSComparisonResult)compareItemByDate:(CommunityItem *)that
{
	return [m_date compare:[that m_date]];
}


- (void)addEventAttendee:(NSString *)mygovUser
{
	if ( nil == m_eventAttendees )
	{
		m_eventAttendees = [[NSMutableArray alloc] initWithCapacity:2];
	}
	
	[m_eventAttendees addObject:mygovUser];
}


- (NSArray *)eventAttendees
{
	return (NSArray *)m_eventAttendees;
}


@end

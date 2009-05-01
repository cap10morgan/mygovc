//
//  CommunityDetailData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"
#import "CommunityDetailData.h"
#import "CommunityItem.h"
#import "ComposeMessageViewController.h"
#import "MyGovUserData.h"


#define KEY_TOP           @"" 
#define KEY_USERCOMMENTS  @"User Comments"

// The order here _must_ correspond to the order in the enumeration above
#define DATA_SECTIONS	KEY_TOP, \
						KEY_USERCOMMENTS, \
						nil


@interface CommunityDetailData (private)
	- (NSArray *)setupDataSection:(NSInteger)section;
	- (void)rowActionAddComment:(NSIndexPath *)indexPath;
@end


@implementation CommunityDetailData


- (id)init
{
	if ( self = [super init] )
	{
		m_item = nil;
		m_dataSections = [[NSMutableArray alloc] initWithObjects:DATA_SECTIONS];
	}
	return self;
}


- (void)dealloc
{
	[m_item release];
	// we don't have to release 'm_dataSections' - that happens in our super class :-)
	[super dealloc];
}


- (void)setItem:(CommunityItem *)item
{
	[m_data release]; m_data = nil;
	[m_item release]; m_item = [item retain];
	
	if ( nil == m_item ) return;
	
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


#pragma mark CommunityDetailData Private


- (NSArray *)setupDataSection:(NSInteger)section
{
	NSMutableArray *retVal = [[NSMutableArray alloc] init];
	
	switch ( m_item.m_type )
	{
		default:
		case eCommunity_Chatter:
			break;
			
		case eCommunity_Event:
			switch ( section )
		{
			default:
			case eCDetailSection_UserComments:
			{
				// add the first item, and make it an "Add Comment" button :-)
				TableRowData *rd = [[TableRowData alloc] init];
				rd.line1 = @"Add Comment";
				rd.line1Font = [UIFont boldSystemFontOfSize:14.0f];
				rd.line1Color = [UIColor blackColor];
				rd.line1Alignment = UITextAlignmentLeft;
				rd.url = nil;
				rd.action = @selector(rowActionAddComment:);
				[retVal addObject:rd];
				[rd release];
			}
				break;
			case eCDetailSection_Top:
			{
				#define TOP_TITLE_FONT  [UIFont boldSystemFontOfSize:14.0f]
				#define TOP_TITLE_COLOR [UIColor blackColor]
				#define TOP_DATA_FONT   [UIFont systemFontOfSize:14.0f]
				#define TOP_DATA_COLOR  [UIColor colorWithRed:0.2f green:0.25f blue:0.7f alpha:0.9f]
				
				TableRowData *rd = [[TableRowData alloc] init];
				rd.title = @"Location";
				rd.titleColor = TOP_TITLE_COLOR;
				rd.titleFont = TOP_TITLE_FONT;
				rd.line1 = @"??";
				rd.line1Color = TOP_DATA_COLOR;
				rd.line1Font = TOP_DATA_FONT;
				rd.line1Alignment = UITextAlignmentRight;
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];
				
				rd = [[TableRowData alloc] init];
				rd.title = @"Organizer";
				rd.titleColor = TOP_TITLE_COLOR;
				rd.titleFont = TOP_TITLE_FONT;
				rd.line1 = [[[myGovAppDelegate sharedUserData] userFromID:m_item.m_creator] m_username];
				rd.line1Color = TOP_DATA_COLOR;
				rd.line1Font = TOP_DATA_FONT;
				rd.line1Alignment = UITextAlignmentRight;
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];
				
				NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init]  autorelease];
				[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
				[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
				
				rd = [[TableRowData alloc] init];
				rd.title = @"Date";
				rd.titleColor = TOP_TITLE_COLOR;
				rd.titleFont = TOP_TITLE_FONT;
				rd.line1 = [dateFormatter stringFromDate:[m_item m_date]];
				rd.line1Color = TOP_DATA_COLOR;
				rd.line1Font = TOP_DATA_FONT;
				rd.line1Alignment = UITextAlignmentRight;
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];
				
				[dateFormatter setDateStyle:NSDateFormatterNoStyle];
				[dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
				
				rd = [[TableRowData alloc] init];
				rd.title = @"Time";
				rd.titleColor = TOP_TITLE_COLOR;
				rd.titleFont = TOP_TITLE_FONT;
				rd.line1 = [dateFormatter stringFromDate:[m_item m_date]];
				rd.line1Color = TOP_DATA_COLOR;
				rd.line1Font = TOP_DATA_FONT;
				rd.line1Alignment = UITextAlignmentRight;
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];
				
				rd = [[TableRowData alloc] init];
				rd.title = @"Attendees";
				rd.titleColor = TOP_TITLE_COLOR;
				rd.titleFont = TOP_TITLE_FONT;
				rd.line1 = [NSString stringWithFormat:@"%0d",[[m_item eventAttendees] count]];
				rd.line1Color = TOP_DATA_COLOR;
				rd.line1Font = TOP_DATA_FONT;
				rd.line1Alignment = UITextAlignmentRight;
				rd.url = nil;
				rd.action = @selector(rowActionNone:);
				[retVal addObject:rd];
				[rd release];
			}
				break;
		}
			break;
	}
	
	// add all the user comments (when in _either_ an event, _or_ a feedback item)
	if ( eCDetailSection_UserComments == section )
	{
		NSArray *ucArray = [m_item comments];
		NSEnumerator *ucEnum = [ucArray objectEnumerator];
		CommunityComment *comment;
		while ( comment = [ucEnum nextObject] )
		{
			TableRowData *rd = [[TableRowData alloc] init];
			
			MyGovUser *user = [[myGovAppDelegate sharedUserData] userFromID:comment.m_creator];
			rd.title = [NSString stringWithFormat:@"%@ says:",[user m_username]];
			rd.titleColor = [UIColor blackColor];
			rd.titleFont = [UIFont boldSystemFontOfSize:14.0f];
			rd.line2 = comment.m_text;
			rd.line2Color = [UIColor darkGrayColor];
			rd.line2Font = [UIFont systemFontOfSize:12.0f];
			rd.url = nil;
			rd.action = @selector(rowActionNone:);
			[retVal addObject:rd];
			[rd release];
		}
	}
	
	// sort values?
	return retVal;
}


#pragma mark CommunityDetailData Private


- (void)rowActionAddComment:(NSIndexPath *)indexPath
{
	MessageData *msg = [[MessageData alloc] init];
	msg.m_transport = eMT_MyGovUserComment;
	msg.m_to = @"MyGovernment Community";
	msg.m_subject = [NSString stringWithFormat:@"Re: %@",[m_item m_title]];
	msg.m_body = @" "; //[item m_title];
	msg.m_communityThreadID = [m_item m_id];
	msg.m_appURL = [m_item m_mygovURL];
	msg.m_appURLTitle = [m_item m_mygovURLTitle];
	msg.m_webURL = [m_item m_webURL];
	msg.m_webURLTitle = [m_item m_webURLTitle];
	
	// display the message composer
	ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
	[cmvc display:msg fromParent:[[myGovAppDelegate sharedAppDelegate] topViewController]];
}


@end

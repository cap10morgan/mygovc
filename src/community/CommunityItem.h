//
//  CommunityItem.h
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//

#import <Foundation/Foundation.h>
@class CLLocation;


typedef enum
{
	eCommunity_Feedback = 0,
	eCommunity_Event,
} CommunityItemType;



@interface CommunityComment : NSObject
{
	NSString *m_owner;
	NSString *m_title;
	NSString *m_text;
}

@property (nonatomic,retain) NSString *m_owner;
@property (nonatomic,retain) NSString *m_title;
@property (nonatomic,retain) NSString *m_text;

@end


@interface CommunityItem : NSObject 
{
	CommunityItemType m_type;
	
	UIImage   *m_image;
	NSString  *m_title;
	NSDate    *m_date;
	NSString  *m_owner;
	NSString  *m_summary;
	NSString  *m_text;
	
	NSString  *m_mygovURLTitle;
	NSURL     *m_mygovURL;
	
	NSString  *m_webURLTitle;
	NSURL     *m_webURL;
	NSMutableArray *m_userComments; // array of CommunityComment items
	
	// used for events (m_type == eCommunityEvent)
	CLLocation     *m_eventLocation;
	NSDate         *m_eventDate;
	NSMutableArray *m_eventAttendees; // array of mygov users
}

@property (nonatomic) CommunityItemType  m_type;
@property (nonatomic,retain) UIImage    *m_image;
@property (nonatomic,retain) NSString   *m_title;
@property (nonatomic,retain) NSDate     *m_date;
@property (nonatomic,retain) NSString   *m_owner;
@property (nonatomic,retain) NSString   *m_summary;
@property (nonatomic,retain) NSString   *m_text;

@property (nonatomic,retain) NSString   *m_mygovURLTitle;
@property (nonatomic,retain) NSURL      *m_mygovURL;

@property (nonatomic,retain) NSString   *m_webURLTitle;
@property (nonatomic,retain) NSURL      *m_webURL;

@property (nonatomic,retain) CLLocation *m_eventLocation;
@property (nonatomic,retain) NSDate     *m_eventDate;


- (void)addComment:(NSString *)comment fromUser:(NSString *)mygovUser withTitle:(NSString *)title;
- (void)addComment:(CommunityComment *)comment;
- (NSArray *)comments;


- (void)addEventAttendee:(NSString *)mygovUser;
- (NSArray *)eventAttendees;


@end

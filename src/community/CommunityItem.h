/*
 File: CommunityItem.h
 Project: myGovernment
 Org: iPhoneFLOSS
 
 Copyright (C) 2009 Jeremy C. Andrus <jeremyandrus@iphonefloss.com>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 $Id: $
 */

#import <Foundation/Foundation.h>
@class CLLocation;


typedef enum
{
	eCommunity_InvalidItem  = 0,
	eCommunity_Chatter     = 1,
	eCommunity_Event        = 2,
} CommunityItemType;


@interface CommunityComment : NSObject
{
	NSString  *m_id;
	NSString  *m_creator; // Google UserID
	NSDate    *m_date;
	NSString  *m_communityItemID;
	NSString  *m_title;
	NSString  *m_text;
@private
	NSInteger m_localSecondsFromGMT;
}

@property (nonatomic,retain) NSString  *m_id;
@property (nonatomic,retain) NSString  *m_creator;
@property (nonatomic,retain) NSDate    *m_date;
@property (nonatomic,retain) NSString  *m_communityItemID;
@property (nonatomic,retain) NSString  *m_title;
@property (nonatomic,retain) NSString  *m_text;

- (id)initWithPlistDict:(NSDictionary *)plistDict;
- (NSDictionary *)writeToPlistDict;

@end


@interface CommunityItem : NSObject 
{
	NSString         *m_id;
	CommunityItemType m_type;
	
	UIImage   *m_image;
	NSString  *m_title;
	NSDate    *m_date;
	NSString  *m_creator; // GoogleUserID
	NSString  *m_summary;
	NSString  *m_text;
	
	NSString  *m_mygovURLTitle;
	NSURL     *m_mygovURL;
	
	NSString  *m_webURLTitle;
	NSURL     *m_webURL;
	NSMutableDictionary *m_userComments; // dictionary of CommunityComment items
	
	// used for events (m_type == eCommunityEvent)
	CLLocation     *m_eventLocation;
	NSString       *m_eventLocDescrip;
	NSDate         *m_eventDate;
	NSMutableArray *m_eventAttendees; // array of mygov users
	
@private
	NSInteger  m_localSecondsFromGMT;
}

@property (nonatomic,retain) NSString   *m_id;
@property (nonatomic) CommunityItemType  m_type;
@property (nonatomic,retain) UIImage    *m_image;
@property (nonatomic,retain) NSString   *m_title;
@property (nonatomic,retain) NSDate     *m_date;
@property (nonatomic,retain) NSString   *m_creator;
@property (nonatomic,retain) NSString   *m_summary;
@property (nonatomic,retain) NSString   *m_text;

@property (nonatomic,retain) NSString   *m_mygovURLTitle;
@property (nonatomic,retain) NSURL      *m_mygovURL;

@property (nonatomic,retain) NSString   *m_webURLTitle;
@property (nonatomic,retain) NSURL      *m_webURL;

@property (nonatomic,retain) CLLocation *m_eventLocation;
@property (nonatomic,retain) NSString   *m_eventLocDescrip;
@property (nonatomic,retain) NSDate     *m_eventDate;

- (id)initFromPlistDictionary:(NSDictionary *)dict;
- (id)initFromFile:(NSString *)fullPath;
- (id)initFromURL:(NSURL *)url;

- (void)writeItemToFile:(NSString *)fullPath;
- (NSDictionary *)writeItemToPlistDictionary;

- (void)generateUniqueItemID;

- (void)addComment:(NSString *)comment fromUser:(NSString *)mygovUser withTitle:(NSString *)title;
- (void)addComment:(CommunityComment *)comment;
- (NSArray *)comments;

- (NSComparisonResult)compareItemByDate:(CommunityItem *)that;

- (void)addEventAttendee:(NSString *)mygovUser;
- (NSArray *)eventAttendees;


@end

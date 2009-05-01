//
//  MyGovUserData.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MyGovUser : NSObject 
{
	NSInteger  m_id;
	NSString  *m_username;
	NSDate    *m_lastUpdated;
	
	NSString  *m_firstname;
	NSString  *m_middlename;
	NSString  *m_lastname;
	
	NSString  *m_email;
	UIImage   *m_avatar;
	
	NSString  *m_password;
	// XXX - more info here?!
}

@property (nonatomic) NSInteger m_id;
@property (nonatomic,retain) NSString *m_username;
@property (nonatomic,retain) NSDate   *m_lastUpdated;
@property (nonatomic,retain) NSString *m_firstname;
@property (nonatomic,retain) NSString *m_middlename;
@property (nonatomic,retain) NSString *m_lastname;
@property (nonatomic,retain) NSString *m_email;
@property (nonatomic,retain) UIImage  *m_avatar;
@property (nonatomic,retain) NSString *m_password;

+ (MyGovUser *)systemUser;

- (id)initWithPlistDict:(NSDictionary *)plistDict;
- (NSDictionary *)writeToPlistDict;

@end


@interface MyGovUserData : NSObject 
{
@private
	NSMutableDictionary *m_userData;
}

- (void)setUserInCache:(MyGovUser *)newUser;

- (MyGovUser *)userFromID:(NSInteger)userID;

@end

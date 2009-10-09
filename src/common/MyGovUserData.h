/*
 File: MyGovUserData.h
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

@interface MyGovUser : NSObject 
{
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

- (MyGovUser *)userFromUsername:(NSString *)username;

- (BOOL)usernameExistsInCache:(NSString *)username;

+ (NSString *)dataCachePath;
+ (NSString *)userAvatarPath:(NSString *)username;

@end

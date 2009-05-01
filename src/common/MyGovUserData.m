//
//  MyGovUserData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MyGovUserData.h"
#import "CommunityDataManager.h"


@interface MyGovUser (private)
	- (NSString *)getCacheFileName;
@end


@implementation MyGovUser : NSObject 

@synthesize m_id, m_username, m_lastUpdated;
@synthesize m_firstname, m_middlename, m_lastname;
@synthesize m_email, m_avatar, m_password;
	// XXX - more info here?!

static NSString *kMGUKey_ID = @"id";
static NSString *kMGUKey_Username = @"username";
static NSString *kMGUKey_LastUpdated = @"last_update";
static NSString *kMGUKey_FirstName = @"fname";
static NSString *kMGUKey_MiddleName = @"mname";
static NSString *kMGUKey_LastName = @"lname";
static NSString *kMGUKey_Avatar = @"avatar";

+ (MyGovUser *)systemUser
{
	static MyGovUser *s_systemUser = NULL;
	if ( NULL == s_systemUser )
	{
		s_systemUser = [[MyGovUser alloc] init];
		
		s_systemUser.m_id = 0;
		s_systemUser.m_lastUpdated = [NSDate date];
		s_systemUser.m_firstname = @"My";
		s_systemUser.m_lastname = @"Government";
		s_systemUser.m_username = @"anonymous";
		s_systemUser.m_avatar = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"system_avatar.png"]];
	}
	return s_systemUser;
}


- (id)initWithPlistDict:(NSDictionary *)plistDict
{
	if ( self = [super init] )
	{
		if ( nil == plistDict )
		{
			m_id = -1;
			m_lastUpdated = nil;
			m_firstname = nil;
			m_middlename = nil;
			m_lastname = nil;
			m_avatar = nil;
		}
		else
		{
			self.m_id = [[plistDict objectForKey:kMGUKey_ID] integerValue];
			
			NSDate *tmpDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:[[plistDict objectForKey:kMGUKey_LastUpdated] integerValue]];
			self.m_lastUpdated = tmpDate;
			[tmpDate release];
			
			self.m_username = [plistDict objectForKey:kMGUKey_Username];
			self.m_firstname = [plistDict objectForKey:kMGUKey_FirstName];
			self.m_middlename = [plistDict objectForKey:kMGUKey_MiddleName];
			self.m_lastname = [plistDict objectForKey:kMGUKey_LastName];
			self.m_avatar = [UIImage imageWithData:[plistDict objectForKey:kMGUKey_Avatar]];
		}
	}
	return self;
}


- (NSDictionary *)writeToPlistDict
{
	NSMutableDictionary *plistDict = [[[NSMutableDictionary alloc] init] autorelease];
	[plistDict setValue:[NSNumber numberWithInt:m_id] forKey:kMGUKey_ID];
	[plistDict setValue:[NSNumber numberWithInt:[m_lastUpdated timeIntervalSinceReferenceDate]] forKey:kMGUKey_LastUpdated];
	[plistDict setValue:m_username forKey:kMGUKey_Username];
	[plistDict setValue:m_firstname forKey:kMGUKey_FirstName];
	[plistDict setValue:m_middlename forKey:kMGUKey_MiddleName];
	[plistDict setValue:m_lastname forKey:kMGUKey_LastName];
	[plistDict setValue:UIImageJPEGRepresentation(m_avatar, 1.0) forKey:kMGUKey_Avatar];
	
	return (NSDictionary *)plistDict;
}

- (NSString *)getCacheFileName
{
	return [NSString stringWithFormat:@"%0d",m_id];
}

@end


@interface MyGovUserData (private)
	- (NSString *)dataCachePath;
@end


@implementation MyGovUserData

- (id)init
{
	if ( self = [super self] )
	{
		m_userData = [[NSMutableDictionary alloc] initWithCapacity:16];
	}
	return self;
}


- (void)dealloc
{
	[m_userData release];
	[super dealloc];
}


- (void)setUserInCache:(MyGovUser *)newUser
{
	if ( nil == newUser ) return;
	
	MyGovUser *nu = [[newUser retain] autorelease];
	
	// implicitly clear old data (allocated with autorelease)
	[m_userData setObject:nu forKey:[NSNumber numberWithInt:[newUser m_id]]];
	
	// store the new data to a local file
	NSString *fPath = [[self dataCachePath] stringByAppendingPathComponent:[nu getCacheFileName]];
	NSDictionary *userData = [nu writeToPlistDict];
	[userData writeToFile:fPath atomically:YES];
}


- (MyGovUser *)userFromID:(NSInteger)userID
{
	MyGovUser *user = [m_userData objectForKey:[NSNumber numberWithInt:userID]];
	if ( nil == user )
	{
		// not in memory - try disk
		NSString *fPath = [[self dataCachePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%0d",userID]];
		if ( [[NSFileManager defaultManager] fileExistsAtPath:fPath] )
		{
			NSDictionary *userData = [NSDictionary dictionaryWithContentsOfFile:fPath];
			if ( nil != userData )
			{
				user = [[MyGovUser alloc] initWithPlistDict:userData];
				if ( user.m_id < 0 )
				{
					[user release]; user = nil;
				}
				else
				{
					// add the user to our in-memory cache so we don't have to touch the disk again :-)
					[m_userData setObject:user forKey:[NSNumber numberWithInt:[user m_id]]];
				}
			}
		}
	}
	if ( nil == user )
	{
		// not in memory or disk - return a "system" user
		return [MyGovUser systemUser];
	}
	return user;
}


- (BOOL)userIDExistsInCache:(NSInteger)userID
{
	MyGovUser *u = [self userFromID:userID];
	if ( nil == u ) return FALSE;
	if ( u.m_id == [MyGovUser systemUser].m_id ) return FALSE;
	
	return TRUE;
}


#pragma mark MyGovUserData Private


- (NSString *)dataCachePath
{
	NSString *cachePath = [CommunityDataManager dataCachePath];
	cachePath = [cachePath stringByAppendingPathComponent:@"usercache"];
	return cachePath;
}


@end

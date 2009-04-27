//
//  MyGovUserData.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MyGovUserData.h"


@implementation MyGovUser : NSObject 

@synthesize m_id, m_username, m_lastUpdated;
@synthesize m_firstname, m_middlename, m_lastname;
@synthesize m_avatar;	
	// XXX - more info here?!
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
	MyGovUser *nu = [[newUser retain] autorelease];
	
	// implicitly clear old data (allocated with autorelease)
	[m_userData setObject:nu forKey:[NSNumber numberWithInt:[newUser m_id]]];
}


- (MyGovUser *)userFromID:(NSInteger)userID
{
	return [m_userData objectForKey:[NSNumber numberWithInt:userID]];
}



@end

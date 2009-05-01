//
//  CholorDataSource.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommunityDataSource.h"

@interface CholorDataSource : NSObject <CommunityDataSourceProtocol>
{
@private
	BOOL m_isBusy;
	
	NSString *m_username;
	NSString *m_password;
	NSInteger m_authenticated_uid;
}

+ (NSString *)postStringFromDictionary:(NSDictionary *)dict;

@end

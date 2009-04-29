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
}

+ (NSString *)postStringFromDictionary:(NSDictionary *)dict;

@end

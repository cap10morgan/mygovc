//
//  CommunityDetailData.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TableDataManager.h"

@class CommunityItem;

enum
{
	eCDetailSection_Top           = 0,
	eCDetailSection_UserComments  = 1,
};


@interface CommunityDetailData : TableDataManager 
{
@private
	CommunityItem *m_item;
}

- (void)setItem:(CommunityItem *)item;

@end

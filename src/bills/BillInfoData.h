//
//  BillInfoData.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TableDataManager.h"

@class BillContainer;


@interface BillInfoData : TableDataManager
{
	BillContainer *m_bill;
}

- (void)setBill:(BillContainer *)legislator;

@end

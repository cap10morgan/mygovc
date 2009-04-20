//
//  SpendingSummaryData.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TableDataManager.h"

@class PlaceSpendingData;
@class ContractorInfo;

@interface SpendingSummaryData : TableDataManager 
{
	PlaceSpendingData *m_placeData;
	ContractorInfo *m_contractorData;
}

- (void)setPlaceData:(PlaceSpendingData *)data;
- (void)setContractorData:(ContractorInfo *)data;

@end

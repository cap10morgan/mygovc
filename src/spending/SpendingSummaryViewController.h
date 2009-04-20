//
//  SpendingSummaryViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/19/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlaceSpendingData;
@class ContractorInfo;
@class SpendingSummaryData;

@interface SpendingSummaryViewController : UITableViewController 
{
	UITableView *m_tableView;
	
	PlaceSpendingData *m_placeData;
	ContractorInfo *m_contractorData;
	
	SpendingSummaryData *m_data;
}

@property (nonatomic,retain,setter=setPlaceData:) PlaceSpendingData *m_placeData;
@property (nonatomic,retain,setter=setContractorData:) ContractorInfo *m_contractorData;

@end

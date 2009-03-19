//
//  SpendingViewController.h
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SpendingDataManager;

typedef enum
{
	eSQMDistrict,
	eSQMState,
	eSQMContractor,
} SpendingQueryMethod;


@interface SpendingViewController : UITableViewController <UIActionSheetDelegate>
{
@private
	SpendingDataManager *m_data;
	SpendingQueryMethod m_selectedQueryMethod;
	UISegmentedControl *m_segmentCtrl;
}

@end

//
//  SpendingViewController.h
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SpendingDataManager;
@class ProgressOverlayViewController;

typedef enum
{
	eSQMDistrict,
	eSQMState,
	eSQMContractor,
	eSQMSearch,
	eSQMLocal,
} SpendingQueryMethod;


@interface SpendingViewController : UITableViewController <UIActionSheetDelegate>
{
@private
	SpendingDataManager *m_data;
	SpendingQueryMethod m_selectedQueryMethod;
	UISegmentedControl *m_segmentCtrl;
	
	int m_sortOrder;
	
	int m_actionSheetType;
	
	ProgressOverlayViewController *m_HUD;
}

- (NSString *)areaName;
- (void)handleURLParms:(NSString *)parms;


@end

//
//  CongressViewController.h
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CongressDataManager;
@class ProgressOverlayViewController;

typedef enum
{
	eCongressChamberHouse,
	eCongressChamberSenate,
	eCongressSearchResults,
} CongressChamber;


typedef enum
{
	eActionContact,
	eActionReload,
} CongressActionType;


@interface CongressViewController : UITableViewController <UIActionSheetDelegate, UISearchBarDelegate>
{	
@private
	CongressDataManager *m_data;
	CongressChamber m_selectedChamber;
	CongressActionType m_actionType;
	UISegmentedControl *m_segmentCtrl;
	
	ProgressOverlayViewController *m_HUD;
}

- (void)dataManagerCallback:(id)message;
- (void)showLegislatorDetail:(id)sender;

@end


//
//  CongressViewController.h
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CongressDataManager;
@class UIProgressHUD;


typedef enum
{
	eCongressChamberHouse,
	eCongressChamberSenate,
} CongressChamber;


@interface CongressViewController : UITableViewController <UIActionSheetDelegate>
{	
@private
	CongressDataManager *m_data;
	CongressChamber m_selectedChamber;
	UISegmentedControl *m_segmentCtrl;
	
	UIProgressHUD *m_HUD;
	NSString *m_HUDTxt;
	BOOL m_shouldKillHUD;
}

- (void)dataManagerCallback:(id)message;

@end


//
//  BillsViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BillsDataManager;
@class ProgressOverlayViewController;


@interface BillsViewController : UITableViewController <UISearchBarDelegate>
{
@private
	BillsDataManager *m_data;
	
	NSString *m_HUDTxt;
	ProgressOverlayViewController *m_HUD;
}

@end

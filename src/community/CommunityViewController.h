//
//  CommunityViewController.h
//  myGovernment
//
//  Created by Wes Morgan on 2/28/09.
//

#import <UIKit/UIKit.h>
#import "CommunityItem.h"

@class CommunityDataManager;
@class ProgressOverlayViewController;


@interface CommunityViewController : UITableViewController <UIAlertViewDelegate, UISearchBarDelegate>
{
@private
	CommunityDataManager *m_data;
	
	UISegmentedControl *m_segmentCtrl;
	CommunityItemType   m_selectedItemType;
	
	ProgressOverlayViewController *m_HUD;
}

- (void)showCommunityDetail:(id)sender;

- (NSString *)areaName;
- (NSString *)getURLStateParms;
- (void)handleURLParms:(NSString *)parms;


@end

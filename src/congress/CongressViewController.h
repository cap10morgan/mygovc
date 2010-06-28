/*
 File: CongressViewController.h
 Project: myGovernment
 Org: iPhoneFLOSS
 
 Copyright (C) 2009 Jeremy C. Andrus <jeremyandrus@iphonefloss.com>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 $Id: $
 */

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "CongressDataManager.h"
#import "LegislatorNameCell.h"
#import "LocateAlertView.h"

@class ProgressOverlayViewController;

typedef enum
{
	eActionContact,
	eActionReload,
} CongressActionType;


@interface CongressViewController : UITableViewController < UIActionSheetDelegate, UIAlertViewDelegate, UISearchBarDelegate, CLLocationManagerDelegate >
{
	IBOutlet LegislatorNameCell *m_tmpCell;
	IBOutlet LocateAlertView    *m_locateAlertView;
	
@private
	CongressDataManager *m_data;
	CongressChamber m_selectedChamber;
	CongressActionType m_actionType;
	UISegmentedControl *m_segmentCtrl;
	
	NSIndexPath *m_initialIndexPath;
	NSString *m_initialLegislatorID;
	NSString *m_initialSearchString;
	
	NSString *m_searchResultsTitle;
	
	CLLocationManager *m_locationManager;
	CLLocation *m_currentLocation;
	
	ProgressOverlayViewController *m_HUD;
	int m_alertViewFunction;
	BOOL m_hasShownNoNetworkAlert;
	
	BOOL m_outOfScope;
}

@property (nonatomic, assign) LegislatorNameCell *m_tmpCell;
@property (nonatomic, assign) LocateAlertView *m_locateAlertView;

- (void)dataManagerCallback:(id)message;
- (void)showLegislatorDetail:(id)sender;

- (NSString *)areaName;
- (NSString *)getURLStateParms;
- (void)handleURLParms:(NSString *)parms;

@end


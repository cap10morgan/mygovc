/*
 File: LegislatorViewController.h
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
#import <AddressBookUI/ABNewPersonViewController.h>
#import <AddressBookUI/ABPersonViewController.h>

@class LegislatorContainer;
@class LegislatorHeaderViewController;
@class LegislatorInfoData;

@interface LegislatorViewController : UITableViewController <ABNewPersonViewControllerDelegate, ABPersonViewControllerDelegate>
{
	UITableView *m_tableView;
	LegislatorContainer *m_legislator;
	LegislatorHeaderViewController *m_headerViewCtrl;
	
	LegislatorInfoData *m_data;
}

@property (nonatomic, retain, setter=setLegislator:) LegislatorContainer *m_legislator;

- (void)setLegislator:(LegislatorContainer *)legislator;

- (void)addLegislatorToContacts:(LegislatorContainer *)legislator withImage:(UIImage *)img;

@end

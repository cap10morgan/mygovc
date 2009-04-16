//
//  LegislatorViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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

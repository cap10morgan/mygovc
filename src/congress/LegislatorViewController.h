//
//  LegislatorViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LegislatorContainer;
@class LegislatorHeaderViewController;

@interface LegislatorViewController : UITableViewController 
{
	UITableView *m_tableView;
	LegislatorContainer *m_legislator;
	LegislatorHeaderViewController *m_headerViewCtrl;
	
	NSMutableDictionary *m_contactRows;
	NSMutableDictionary *m_committeeRows;
	NSMutableDictionary *m_streamRows;
	NSMutableDictionary *m_activityRows;
	NSArray *m_contactFields;
	NSArray *m_committeeFields;
	NSArray *m_streamFields;
	NSArray *m_activityFields;
}

@property (nonatomic, retain, setter=setLegislator:) LegislatorContainer *m_legislator;

- (void)setLegislator:(LegislatorContainer *)legislator;

@end

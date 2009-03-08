//
//  LegislatorViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LegislatorContainer;

@interface LegislatorViewController : UITableViewController 
{
	UITableView *m_tableView;
	LegislatorContainer *m_legislator;
	NSMutableDictionary *m_infoSelector;
	NSArray *m_keyNames;
}

@property (nonatomic, retain, setter=setLegislator:) LegislatorContainer *m_legislator;

- (void)setLegislator:(LegislatorContainer *)legislator;

@end

//
//  BillInfoViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BillContainer;
@class BillInfoData;

@interface BillInfoViewController : UITableViewController 
{
	UITableView *m_tableView;
	BillContainer *m_bill;
	
	BillInfoData *m_data;
}

@property (nonatomic, retain, setter=setBill:) BillContainer *m_bill;

- (void)setBill:(BillContainer *)bill;


@end

//
//  CommunityDetailViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CommunityItem;
@class CommunityDetailData;


@interface CommunityDetailViewController : UITableViewController <UIAlertViewDelegate>
{
@private
	UITableView *m_tableView;
	CommunityItem *m_item;
	
	CommunityDetailData *m_data;
	
	NSInteger m_alertSheetUsed;
}

@property (nonatomic, retain, setter=setItem:) CommunityItem *m_item;

- (void)setItem:(CommunityItem *)item;


@end

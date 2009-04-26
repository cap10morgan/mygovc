//
//  CommunityItemView.h
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//  Copyright 2009 U.S. PIRG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CommunityItem;

@interface CommunityItemTableCell : UITableViewCell 
{
@private
	CommunityItem *m_item;
}

@property (nonatomic,retain,setter=setCommunityItem:) CommunityItem *m_item;

+ (CGFloat)getCellHeightForItem:(CommunityItem *)item;

- (void)setDetailTarget:(id)target andSelector:(SEL)selector;

- (void)setCommunityItem:(CommunityItem *)newItem;

@end

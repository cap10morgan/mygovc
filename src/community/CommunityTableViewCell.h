//
//  CommunityTableViewCell.h
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//  Copyright 2009 U.S. PIRG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CommunityItem;
@class CommunityItemView;

@interface CommunityTableViewCell : UITableViewCell {
    CommunityItemView *communityItemView;
}

- (void)setCommunityItem:(CommunityItem *)newCommunityItem;
@property (nonatomic, retain) CommunityItemView *communityItemView;

@end

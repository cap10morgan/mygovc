//
//  CommunityItemView.h
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//  Copyright 2009 U.S. PIRG. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CommunityItem;

@interface CommunityItemView : UIView {
    CommunityItem *communityItem;
    BOOL highlighted;
    BOOL editing;
}

@property (nonatomic, retain) CommunityItem *communityItem;
@property (nonatomic, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, getter=isEditing) BOOL editing;

@end

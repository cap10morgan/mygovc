//
//  CommunityTableViewCell.m
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//  Copyright 2009 U.S. PIRG. All rights reserved.
//

#import "CommunityTableViewCell.h"
#import "CommunityItem.h"
#import "CommunityItemView.h"


@implementation CommunityTableViewCell

@synthesize communityItemView;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) {
        CGRect civFrame = CGRectMake(0.0, 0.0, self.contentView.bounds.size.width,
            self.contentView.bounds.size.height);
        communityItemView = [[CommunityItemView alloc] initWithFrame:civFrame];
        communityItemView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
        UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:communityItemView];
    }
    return self;
}

- (void)setCommunityItem:(CommunityItem *)newCommunityItem {
    // Pass the community item to the view
    communityItemView.communityItem = newCommunityItem;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {

    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)dealloc {
    [communityItemView release];
    [super dealloc];
}


@end

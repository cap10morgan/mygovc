//
//  LegislatorNameCell.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LegislatorContainer;

@interface LegislatorNameCell : UITableViewCell 
{
	LegislatorContainer *m_legislator;
}

@property (readonly) LegislatorContainer *m_legislator;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier detailTarget:(id)tgt detailSelector:(SEL)sel;
- (void)setInfoFromLegislator:(LegislatorContainer *)legislator;


@end

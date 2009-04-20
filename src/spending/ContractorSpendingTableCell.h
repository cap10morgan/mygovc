//
//  ContractorSpendingTableCell.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ContractorInfo;

@interface ContractorSpendingTableCell : UITableViewCell 
{
@private
	ContractorInfo *m_contractor;
}

@property (readonly) ContractorInfo *m_contractor;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)identifier detailTarget:(id)tgt detailSelector:(SEL)sel;

- (void)setContractor:(ContractorInfo *)contractor;

@end

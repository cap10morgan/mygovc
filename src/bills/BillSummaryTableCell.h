//
//  BillSummaryTableCell.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class BillContainer;

@interface BillSummaryTableCell : UITableViewCell 
{
@private
	BillContainer *m_bill;
}

@property (readonly) BillContainer *m_bill;

+ (CGFloat)getCellHeightForBill:(BillContainer *)bill;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier detailTarget:(id)tgt detailSelector:(SEL)sel;
- (void)setContentFromBill:(BillContainer *)container;


@end

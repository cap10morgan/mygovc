//
//  PlaceSpendingTableCell.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PlaceSpendingData;

@interface PlaceSpendingTableCell : UITableViewCell 
{
@private
	PlaceSpendingData *m_data;
}

@property (readonly) PlaceSpendingData * m_data;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)identifier detailTarget:(id)tgt detailSelector:(SEL)sel;

- (void)setPlaceData:(PlaceSpendingData *)data;

@end

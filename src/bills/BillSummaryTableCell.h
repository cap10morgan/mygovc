/*
 File: BillSummaryTableCell.h
 Project: myGovernment
 Org: iPhoneFLOSS
 
 Copyright (C) 2009 Jeremy C. Andrus <jeremyandrus@iphonefloss.com>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 $Id: $
 */

#import <UIKit/UIKit.h>

@class BillContainer;

@interface BillSummaryTableCell : UITableViewCell 
{
	IBOutlet UILabel  *m_billNumView;
	IBOutlet UILabel  *m_sponsorView;
	IBOutlet UILabel  *m_descripView;
	IBOutlet UILabel  *m_statusView;
	IBOutlet UILabel  *m_voteView;
	IBOutlet UIButton *m_detailButton;
@private
	BillContainer *m_bill;
	NSRange m_tableRange;
}

@property (nonatomic,retain) UILabel  *m_billNumView;
@property (nonatomic,retain) UILabel  *m_sponsorView;
@property (nonatomic,retain) UILabel  *m_descripView;
@property (nonatomic,retain) UILabel  *m_statusView;
@property (nonatomic,retain) UILabel  *m_voteView;
@property (nonatomic,retain) UIButton *m_detailButton;

@property (readonly) BillContainer *m_bill;
@property (nonatomic) NSRange m_tableRange;

+ (CGFloat)getCellHeightForBill:(BillContainer *)bill;

- (void)setDetailTarget:(id)target andSelector:(SEL)selector;

- (void)setContentFromBill:(BillContainer *)container;


@end

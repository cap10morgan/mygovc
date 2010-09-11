/*
 File: ContractorSpendingTableCell.h
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

@class ContractorInfo;

@interface ContractorSpendingTableCell : UITableViewCell 
{
	IBOutlet UILabel  *m_dollarsView;
	IBOutlet UILabel  *m_ctrView;
	IBOutlet UIButton *m_detailButton;
@private
	ContractorInfo    *m_contractor;
}

@property (nonatomic, retain) UILabel  *m_dollarsView;
@property (nonatomic, retain) UILabel  *m_ctrView;
@property (nonatomic, retain) UIButton *m_detailButton;
@property (readonly) ContractorInfo    *m_contractor;

- (void)setDetailTarget:(id)tgt withSelector:(SEL)sel;
- (void)setContractor:(ContractorInfo *)contractor;

@end

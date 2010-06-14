/*
 File: LegislatorNameCell.h
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

@class LegislatorContainer;

@interface LegislatorNameCell : UITableViewCell 
{
	IBOutlet UILabel *m_nameView;
	IBOutlet UILabel *m_partyView;
	IBOutlet UILabel *m_infoView;
	IBOutlet UIButton *m_detailButton;
	
@private
	NSRange m_tableRange;
	LegislatorContainer *m_legislator;
}

@property (retain) UILabel *m_nameView;
@property (retain) UILabel *m_partyView;
@property (retain) UILabel *m_infoView;
@property (retain) UIButton *m_detailButton;

@property (nonatomic) NSRange m_tableRange;
@property (readonly) LegislatorContainer *m_legislator;

- (void)setDetailTarget:(id)tgt withSelector:(SEL)sel;
- (void)setInfoFromLegislator:(LegislatorContainer *)legislator;

@end

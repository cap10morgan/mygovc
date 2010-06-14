/*
 File: LegislatorHeaderViewController.h
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

@interface LegislatorHeaderViewController : UIViewController
{
	LegislatorContainer *m_legislator;
	
	IBOutlet UILabel *m_name;
	IBOutlet UILabel *m_partyInfo;
	IBOutlet UIButton *m_districtInfoButton;
	IBOutlet UIImageView *m_img;
@private
	UIImage *m_largeImg;
	id m_navController;
}

@property (nonatomic, retain) UILabel *m_name;
@property (nonatomic, retain) UILabel *m_partyInfo;
@property (nonatomic, retain) UIButton *m_districtInfoButton;
@property (nonatomic, retain) UIImageView *m_img;

- (IBAction) addLegislatorToContacts:(id)sender;
- (IBAction) getLegislatorBio:(id)sender;
- (IBAction) showLegislatorDistrict:(id)sender;

- (void)setNavController:(id)controller;
- (void)setLegislator:(LegislatorContainer *)legislator;

@end

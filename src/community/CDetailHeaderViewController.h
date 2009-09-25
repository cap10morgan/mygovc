/*
 File: CDetailHeaderViewController.h
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


@class CommunityItem;

@interface CDetailHeaderViewController : UIViewController
{
	CommunityItem *m_item;
	
	IBOutlet UILabel *m_name;
	IBOutlet UILabel *m_mygovURLTitle;
	IBOutlet UILabel *m_webURLTitle;
	IBOutlet UIImageView *m_img;
	IBOutlet UILabel *m_dateLabel;
	
	IBOutlet UIButton *m_myGovURLButton;
	IBOutlet UIButton *m_webURLButton;
	
@private
	UIImage *m_largeImg;
}

@property (nonatomic, retain) UILabel *m_name;
@property (nonatomic, retain) UILabel *m_mygovURLTitle;
@property (nonatomic, retain) UILabel *m_webURLTitle;
@property (nonatomic, retain) UIImageView *m_img;
@property (nonatomic, retain) UILabel *m_dateLabel;
@property (nonatomic, retain) UIButton *m_myGovURLButton;
@property (nonatomic, retain) UIButton *m_webURLButton;

- (void)openMyGovURL;
- (void)openWebURL;

- (void)setItem:(CommunityItem *)item;

@end

//
//  LegislatorHeaderViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class LegislatorContainer;

@interface LegislatorHeaderViewController : UIViewController
{
	LegislatorContainer *m_legislator;
	
	IBOutlet UILabel *m_name;
	IBOutlet UILabel *m_partyInfo;
	IBOutlet UIImageView *m_img;
@private
	UIImage *m_largeImg;
	id m_navController;
}

@property (nonatomic, retain) UILabel *m_name;
@property (nonatomic, retain) UILabel *m_partyInfo;
@property (nonatomic, retain) UIImageView *m_img;

- (IBAction) addLegislatorToContacts:(id)sender;
- (IBAction) getLegislatorBio:(id)sender;

- (void)setNavController:(id)controller;
- (void)setLegislator:(LegislatorContainer *)legislator;

@end

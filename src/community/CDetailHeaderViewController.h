//
//  CDetailHeaderViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class CommunityItem;

@interface CDetailHeaderViewController : UIViewController
{
	CommunityItem *m_item;
	
	IBOutlet UILabel *m_name;
	IBOutlet UILabel *m_mygovURLTitle;
	IBOutlet UILabel *m_webURLTitle;
	IBOutlet UIImageView *m_img;
	
	IBOutlet UIButton *m_myGovURLButton;
	IBOutlet UIButton *m_webURLButton;
	
@private
	UIImage *m_largeImg;
}

@property (nonatomic, retain) UILabel *m_name;
@property (nonatomic, retain) UILabel *m_mygovURLTitle;
@property (nonatomic, retain) UILabel *m_webURLTitle;
@property (nonatomic, retain) UIImageView *m_img;
@property (nonatomic, retain) UIButton *m_myGovURLButton;
@property (nonatomic, retain) UIButton *m_webURLButton;

- (IBAction)openMyGovURL:(id)sender;
- (IBAction)openWebURL:(id)sender;

- (void)setItem:(CommunityItem *)item;

@end

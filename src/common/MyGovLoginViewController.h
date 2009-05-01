//
//  MyGovLoginViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ProgressOverlayViewController;


@interface MyGovLoginViewController : UIViewController <UITextFieldDelegate>
{
	IBOutlet UITextField *username;
	IBOutlet UITextField *password;
	IBOutlet UILabel     *labelPasswordVerify;
	IBOutlet UITextField *passwordVerify;
	IBOutlet UISwitch    *saveCredentials;
	IBOutlet UISwitch    *newUser;
	
@private
	id   m_notifyTarget;
	SEL  m_notifySelector;
	
	ProgressOverlayViewController *m_hud;
	
	id   m_parent;
}

@property (nonatomic,retain) IBOutlet UITextField *username;
@property (nonatomic,retain) IBOutlet UITextField *password;
@property (nonatomic,retain) IBOutlet UILabel     *labelPasswordVerify;
@property (nonatomic,retain) IBOutlet UITextField *passwordVerify;
@property (nonatomic,retain) IBOutlet UISwitch    *saveCredentials;
@property (nonatomic,retain) IBOutlet UISwitch    *newUser;

- (void)displayIn:(id)parent;

- (IBAction)switchNewUser:(id)sender;
- (IBAction)signIn:(id)sender;
- (IBAction)cancel:(id)sender;

- (void)setNotifyTarget:(id)target withSelector:(SEL)selector;


@end

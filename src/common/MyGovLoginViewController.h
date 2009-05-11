/*
 File: MyGovLoginViewController.h
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

@class ProgressOverlayViewController;


@interface MyGovLoginViewController : UIViewController <UITextFieldDelegate>
{
	IBOutlet UITextField *username;
	IBOutlet UITextField *password;
	IBOutlet UISwitch    *saveCredentials;
//	IBOutlet UILabel     *labelPasswordVerify;
//	IBOutlet UITextField *passwordVerify;
//	IBOutlet UISwitch    *newUser;
	
@private
	id   m_notifyTarget;
	SEL  m_notifySelector;
	
	ProgressOverlayViewController *m_hud;
	
	id   m_parent;
}

@property (nonatomic,retain) IBOutlet UITextField *username;
@property (nonatomic,retain) IBOutlet UITextField *password;
@property (nonatomic,retain) IBOutlet UISwitch    *saveCredentials;
//@property (nonatomic,retain) IBOutlet UILabel     *labelPasswordVerify;
//@property (nonatomic,retain) IBOutlet UITextField *passwordVerify;
//@property (nonatomic,retain) IBOutlet UISwitch    *newUser;

- (void)displayIn:(id)parent;

//- (IBAction)switchNewUser:(id)sender;
- (IBAction)signIn:(id)sender;
- (IBAction)cancel:(id)sender;
- (IBAction)createNewAccount:(id)sender;

- (void)setNotifyTarget:(id)target withSelector:(SEL)selector;


@end

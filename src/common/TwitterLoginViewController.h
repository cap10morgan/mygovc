/*
 File: TwitterLoginViewController.h
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
#import "ProgressOverlayViewController.h"

@interface TwitterLoginViewController : UIViewController <UITextFieldDelegate>
{
	IBOutlet UITextField *username;
	IBOutlet UITextField *password;
	IBOutlet UISwitch *saveCredentials;
	
@private
	BOOL loggedIn;
	id   m_notifyTarget;
	SEL  m_notifySelector;
	
	ProgressOverlayViewController *m_hud;
	
	id   m_parent;
}

@property (nonatomic,retain) IBOutlet UITextField *username;
@property (nonatomic,retain) IBOutlet UITextField *password;
@property (nonatomic,retain) IBOutlet UISwitch *saveCredentials;
@property (nonatomic,getter=isLoggedIn) BOOL loggedIn;

- (void)displayIn:(id)parent;

- (IBAction)signIn:(id)sender;
- (IBAction)cancel:(id)sender;

- (void)setNotifyTarget:(id)target withSelector:(SEL)selector;

/*
- (NSString *)getUser;
- (NSString *)getPass;
- (BOOL)shouldSaveCredentials;
*/

- (BOOL)isLoggedIn;

- (void)twitterOpFinished:(NSString *)success;

@end

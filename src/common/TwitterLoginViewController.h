//
//  TwitterLoginViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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

/*
 File: TwitterLoginViewController.m
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

#import "myGovAppDelegate.h"
#import "MGTwitterEngine.h"
#import "TwitterLoginViewController.h"


@interface TwitterLoginViewController (private)
	- (void)animate:(id)parent;
	- (void)textAnimationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context;
@end


@implementation TwitterLoginViewController

@synthesize username, password, saveCredentials, loggedIn;

// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
		// Custom initialization
		loggedIn = NO;
		m_parent = nil;
		m_notifyTarget = nil;
		m_notifySelector = nil;
		m_hud = nil;
	}
	return self;
}


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[super dealloc];
}

- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	m_hud = [[ProgressOverlayViewController alloc] initWithWindow:self.view];
	
	[username setFont:[UIFont systemFontOfSize:14.0f]];
	[password setFont:[UIFont systemFontOfSize:14.0f]];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Dismiss the keyboard when the view outside the text field is touched.
	[username resignFirstResponder];
	[password resignFirstResponder];
	
    [super touchesBegan:touches withEvent:event];
}


#pragma mark UITextFieldDelegate


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
	// When the user presses return, take focus away from the text field so that the keyboard is dismissed.
	[theTextField resignFirstResponder];
	return YES;
}


#pragma mark UITextViewDelegate


- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	[textView resignFirstResponder];
	return YES;
}


#pragma mark TwitterLoginViewControlle implementation


- (void)displayIn:(id)parent
{
	m_parent = [[parent retain] autorelease];
	[self animate:parent];
}


- (IBAction)signIn:(id)sender
{
	MGTwitterEngine *twitterEngine = [myGovAppDelegate sharedTwitterEngine];
	
	[[myGovAppDelegate sharedAppDelegate] setTwitterNotifyTarget:self];
	[twitterEngine setUsername:self.username.text password:self.password.text];
	NSString *sID = [twitterEngine checkUserCredentials];
	(void)sID;
	
	[m_hud setText:@"Logging in to Twitter..." andIndicateProgress:YES];
	[m_hud show:YES];
	
	[self.view setUserInteractionEnabled:NO];
	[self.view setNeedsDisplay];
}


- (IBAction)cancel:(id)sender
{
	[self animate:m_parent];
}


- (void)setNotifyTarget:(id)target withSelector:(SEL)selector
{
	m_notifyTarget = [[target retain] autorelease];
	m_notifySelector = selector;
}


- (void)twitterOpFinished:(NSString *)success
{
	[self.view setUserInteractionEnabled:YES];
	[m_hud show:NO];
	
	if ( [[success substringToIndex:2] isEqualToString:@"NO"] )
	{
		loggedIn = NO;
		NSString *err = [success substringFromIndex:2];
		
		// pop up an alert saying it failed!
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Sign In Error"
							  message:[NSString stringWithFormat:@"Error: [%@]\nBad username/password?",err]
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:@"OK",nil];
		[alert show];
		return;
	}
	
	loggedIn = YES;
	
	// (maybe) save the user credentials
	if ( self.saveCredentials.isOn )
	{
		[[NSUserDefaults standardUserDefaults] setObject:self.username.text forKey:@"twitter_username"];
		[[NSUserDefaults standardUserDefaults] setObject:self.password.text forKey:@"twitter_password"];
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	// remove myself from notification
	[[myGovAppDelegate sharedAppDelegate] setTwitterNotifyTarget:nil];
	
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector];
	}
	
	// dismiss the view
	[self animate:m_parent];
}


#pragma mark TwitterLoginViewController Private


- (void)animate:(id)parent
{
	UIView *topView = [parent view];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.7f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationFinished:finished:context:)];
	
	if ( [self.view superview] )
	{
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:topView cache:NO];
		[self.view removeFromSuperview];
	}
	else
	{
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlDown forView:topView cache:NO];
		[topView addSubview:self.view];
	}
	
	[UIView commitAnimations];
}


- (void)textAnimationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
}


#pragma mark UIAlertViewDelegate Methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// Do something here?!
}


@end

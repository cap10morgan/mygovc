/*
 File: MyGovLoginViewController.m
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
#import "CommunityDataManager.h"
#import "CommunityDataSource.h"
#import "MiniBrowserController.h"
#import "MyGovLoginViewController.h"
#import "MyGovUserData.h"
#import "ProgressOverlayViewController.h"


@interface MyGovLoginViewController (private)
	- (void)performAuthentication;
	- (void)animate:(id)parent;
	- (void)animationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context;
@end


@implementation MyGovLoginViewController

@synthesize username, password, saveCredentials;
//@synthesize labelPasswordVerify, passwordVerify, newUser;


// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
		// Custom initialization
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


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	m_hud = [[ProgressOverlayViewController alloc] initWithWindow:self.view];
	
	[username setFont:[UIFont systemFontOfSize:16.0f]];
	[password setFont:[UIFont systemFontOfSize:16.0f]];
	
	// hide by default 
//	[passwordVerify setHidden:YES];
//	[labelPasswordVerify setHidden:YES];
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Dismiss the keyboard when the view outside the text field is touched.
	[username resignFirstResponder];
	[password resignFirstResponder];
//	[passwordVerify resignFirstResponder];
	
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


#pragma mark MyGovLoginViewController implementation


- (void)displayIn:(id)parent
{
	m_parent = [[parent retain] autorelease];
	[self animate:parent];
}


/*
- (IBAction)switchNewUser:(id)sender
{
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:2.2f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationFinished:finished:context:)];
	
	if ( newUser.isOn )
	{
		[labelPasswordVerify setHidden:NO];
		[passwordVerify setHidden:NO];
	}
	else
	{
		[labelPasswordVerify setHidden:YES];
		[passwordVerify setHidden:YES];
	}
	
	[UIView commitAnimations];
}
*/

- (IBAction)signIn:(id)sender
{
	/*
	if ( newUser.isOn )
	{
		[m_hud setText:@"Creating MyGov Account..." andIndicateProgress:YES];
		if ( ![password.text isEqualToString:passwordVerify.text] )
		{
			UIAlertView *alert = [[UIAlertView alloc] 
								  initWithTitle:@"Password"
								  message:[NSString stringWithString:@"Please re-type your password:\nverification mis-match!"]
								  delegate:self
								  cancelButtonTitle:nil
								  otherButtonTitles:@"OK",nil];
			[alert show];
			return;
		}
	}
	else
	*/
	[m_hud setText:@"Logging in to Google Account..." andIndicateProgress:YES];
	[m_hud show:YES];
	
	[self.view setUserInteractionEnabled:NO];
	[self.view setNeedsDisplay];
	
	// run the auth in a background thread
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		selector:@selector(performAuthentication) 
																		  object:nil];
	
	// Add the operation to the internal operation queue managed by the application delegate.
	[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
	
	[theOp release];
}


- (IBAction)cancel:(id)sender
{
	[self animate:m_parent];
}


- (IBAction)createNewAccount:(id)sender
{
	NSString *googleNewAcctURLStr = @"https://www.google.com/accounts/NewAccount";
	NSURL *newAcctURL = [NSURL URLWithString:googleNewAcctURLStr];
	MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:newAcctURL];
	
	mbc.m_shouldUseParentsView = YES;
	[mbc display:self];
}


- (void)setNotifyTarget:(id)target withSelector:(SEL)selector
{
	m_notifyTarget = [[target retain] autorelease];
	m_notifySelector = selector;
}


#pragma mark MyGovLoginViewController Private


- (void)performAuthentication
{
	CommunityDataManager *cdm = [myGovAppDelegate sharedCommunityData];
	id<CommunityDataSourceProtocol> dataSource = [cdm dataSource];
	
	BOOL success;
	
	/*
	if ( newUser.isOn )
	{
		// attempt to create a new user 
		// (password/passwordVerify have already been established as equal)
		MyGovUser *userObj = [[[MyGovUser alloc] init] autorelease];
		userObj.m_username = username.text;
		userObj.m_password = password.text;
		userObj.m_email = @"default@iphonefloss.com"; // XXX - pop something up?!
		
		success = [dataSource addNewUser:userObj withDelegate:cdm];
		if ( !success )
		{
			[self.view setUserInteractionEnabled:YES];
			[m_hud show:NO];
			UIAlertView *alert = [[UIAlertView alloc] 
								  initWithTitle:@"Account Error"
								  message:[NSString stringWithString:@"Could not create your account"]
								  delegate:self
								  cancelButtonTitle:nil
								  otherButtonTitles:@"OK",nil];
			[alert show];
			return;
		}
	}
	*/
	
	// authenticate the given username/password
	success = [dataSource validateUsername:username.text andPassword:password.text withDelegate:cdm];
	
	[self.view setUserInteractionEnabled:YES];
	[m_hud show:NO];
	[self.view setNeedsDisplay];
	
	if ( !success )
	{
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Login Error"
							  message:[NSString stringWithString:@"Invalid Email/Password combo"]
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:@"OK",nil];
		[alert show];
		return;
	}
	else
	{
		if ( saveCredentials.isOn )
		{
			[[NSUserDefaults standardUserDefaults] setObject:self.username.text forKey:@"gae_username"];
			[[NSUserDefaults standardUserDefaults] setObject:self.password.text forKey:@"gae_password"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}
		
		// dismiss the view
		[self animate:m_parent];
		
		// make the callback - we're logged in!
		if ( nil != m_notifyTarget )
		{
			if ( [m_notifyTarget respondsToSelector:m_notifySelector] )
			{
				[m_notifyTarget performSelector:m_notifySelector];
			}
		}
	}
}


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


- (void)animationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
}


#pragma mark UIAlertViewDelegate Methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// Do something here?!
}


@end

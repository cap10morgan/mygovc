/*
 File: ComposeMessageViewController.m
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
#import "CommunityItem.h"
#import "ComposeMessageViewController.h"
#import "MGTwitterEngine.h"
#import "MiniBrowserController.h"
#import "ProgressOverlayViewController.h"
#import "TwitterLoginViewController.h"


@implementation MessageData

@synthesize m_transport, m_to, m_subject, m_body;
@synthesize m_appURL, m_appURLTitle, m_webURL, m_webURLTitle;
@synthesize m_communityThreadID;
@synthesize m_image;

- (id)init
{
	if ( self = [super init] )
	{
		m_transport = eMT_Invalid;
		m_to = nil;
		m_subject = nil;
		m_body = nil;
		m_appURL = nil;
		m_appURLTitle = nil;
		m_webURL = nil;
		m_webURLTitle = nil;
		m_communityThreadID = nil;
		m_image = nil;
	}
	return self;
}

@end



@implementation ComposeMessageView

@synthesize m_parentController;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	// pass this up to our parent view controller
	// which has knowledge of all the UI components that need
	// to resign their first responder status :-)
    [m_parentController touchesBegan:touches withEvent:event];
}

@end



@interface ComposeMessageViewController (private)
	- (void)keyboardWasShown:(NSNotification*)aNotification;
	- (void)keyboardWasHidden:(NSNotification*)aNotification;
	- (void)layoutUIForMessageType:(MessageTransport)type;
	- (NSString *)mygovUserAuthWithCallback:(SEL)callback;
	- (id)opMakePhoneCall;
	- (id)opSendEmail;
	- (id)opSendTwitterDM;
	- (id)opSendTweet;
	- (id)opSendMyGovComment;
	- (id)opSendMyGovReply;
	- (void)sendCommunityItemViaDataSource:(CommunityItem *)item;
	- (void)sendCommunityReplyViaDataSource:(CommunityComment *)reply;
@end


@implementation ComposeMessageViewController

@synthesize m_msgView;
@synthesize m_titleButton, m_labelTo, m_fieldTo, m_labelSubject, m_fieldSubject;
@synthesize m_labelMessage, m_fieldMessage, m_buttonMessage, m_infoButton;
@synthesize m_labelURL, m_fieldURL, m_labelURLTitle, m_fieldURLTitle;


enum
{
	eAlertType_TwitterError = 1,
	eAlertType_ChatterError,
	eAlertType_ReplyError,
	eAlertType_MyGovAuthError,
};

static ComposeMessageViewController *s_composer = NULL;

static CGFloat S_CELL_VOFFSET = 10.0f;

+ (ComposeMessageViewController *)sharedComposer
{
	if ( NULL == s_composer )
	{
		s_composer = [[ComposeMessageViewController alloc] initWithNibName:@"ComposeMessageView" bundle:nil];
		[s_composer.view setNeedsDisplay];
	}
	
	return s_composer;
}


// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
		// Custom initialization
		m_message = nil;
		m_twitterLoginView = nil;
		m_mygovLoginView = nil;
		m_hud = nil;
		m_activeTextField = nil;
		m_keyboardVisible = NO;
		m_shouldRespondToKbdEvents = YES;
		m_alertType = eAlertType_TwitterError;
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
	[m_message release];
	[super dealloc];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	// set the content size of the scroll view to be the size of the window
	[(UIScrollView *)(self.view) setContentSize:CGSizeMake(CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame))];
	
	// set ourselves up to receive touch events from the container UIView object...
	m_msgView.m_parentController = self;
	
	m_hud = [[ProgressOverlayViewController alloc] initWithWindow:self.view];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	m_keyboardVisible = NO;
	m_shouldRespondToKbdEvents = YES;
	// register to receive keyboard notifications
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardDidShowNotification object:nil];
	
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasHidden:)
												 name:UIKeyboardDidHideNotification object:nil];
	
}


- (void)viewWillDisappear:(BOOL)animated 
{
	m_shouldRespondToKbdEvents = NO;
	
	// resign keyboard notifications
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Dismiss the keyboard when the view outside the text field is touched.
	[m_fieldTo resignFirstResponder];
	[m_fieldSubject resignFirstResponder];
	[m_fieldMessage resignFirstResponder];
	[m_fieldURL resignFirstResponder];
	[m_fieldURLTitle resignFirstResponder];
    [super touchesBegan:touches withEvent:event];
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}


- (void)display:(MessageData *)data fromParent:(id)parentController;
{
	[m_message release];
	m_message = [data retain];
	if ( nil == m_message ) return;
	
	NSString *titleTxt;
	switch ( m_message.m_transport )
	{
		default:
		case eMT_MyGov:
			titleTxt = @"Comment";
			break;
		
		case eMT_MyGovUserComment:
			titleTxt = @"Reply";
			break;
			
		case eMT_SendTwitterDM:
			titleTxt = @"Twitter DM";
			break;
			
		case eMT_SendTweet:
			titleTxt = @"Tweet";
			break;
			
		case eMT_Email:
			// don't display the UI (for now) - call the application
			// email send routine
			[self opSendEmail];
			return;
		
		case eMT_PhoneCall:
			// don't display the UI - just make the phone call
			[self opMakePhoneCall];
			return;
	}
	
	m_titleButton.title = titleTxt;
	
	// setup the GUI based on transport type
	// (not all transports need to see _all_ the GUI)
	[self layoutUIForMessageType:m_message.m_transport];
	
	// XXX - This is always hidden for now :-)
	[m_infoButton setHidden:YES];
	
	[m_fieldTo setText:m_message.m_to];
	[m_fieldSubject setText:m_message.m_subject];
	[m_fieldMessage setText:m_message.m_body];
	[m_fieldURL setText:[m_message.m_webURL absoluteString]];
	[m_fieldURLTitle setText:m_message.m_webURLTitle];
	
	if ( m_message.m_transport == eMT_SendTwitterDM )
	{
		[m_fieldTo setEnabled:YES];
	}
	else
	{
		[m_fieldTo setEnabled:NO];
	}
	
	m_parentCtrl = parentController;
	[m_parentCtrl presentModalViewController:self animated:YES];
}


- (IBAction)cancelButtonPressed:(id)sender
{
	[m_parentCtrl dismissModalViewControllerAnimated:YES];
}


- (IBAction)sendButtonPressed:(id)sender
{
    [m_fieldTo resignFirstResponder];
	[m_fieldSubject resignFirstResponder];
	[m_fieldMessage resignFirstResponder];
	[m_fieldURL resignFirstResponder];
	[m_fieldURLTitle resignFirstResponder];
	
	SEL sendOp = nil;
	switch ( m_message.m_transport )
	{
		default:
		case eMT_MyGov:
			sendOp = @selector(opSendMyGovComment);
			break;
			
		case eMT_MyGovUserComment:
			sendOp = @selector(opSendMyGovReply);
			break;
			
		case eMT_SendTwitterDM:
			sendOp = @selector(opSendTwitterDM);
			break;
			
		case eMT_SendTweet:
			sendOp = @selector(opSendTweet);
			break;
			
		case eMT_Email:
			sendOp = @selector(opSendEmail);
			break;
		
		case eMT_PhoneCall:
			sendOp = nil;
			break;
	}
	
	id success = nil;
	if ( nil != sendOp )
	{
		success = [self performSelector:sendOp];
	}
	
	if ( nil != success ) [m_parentCtrl dismissModalViewControllerAnimated:YES];
}


- (IBAction)infoButtonPressed:(id)sender
{
	// XXX - animate a nice view controller which handles all the other
	// XXX - message data so that the user can have control over it
}


#pragma mark UITextFieldDelegate


- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
	m_activeTextField = textField;
	return YES;
}


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
	// When the user presses return, take focus away from the text field so that the keyboard is dismissed.
	[theTextField resignFirstResponder];
	m_activeTextField = nil;
	return YES;
}


#pragma mark UITextViewDelegate Methods 


- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
	m_activeTextField = textView;
	return YES;
}


- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	m_activeTextField = nil;
	return YES;
}


#pragma mark ComposeMessageViewController Private 


- (void)keyboardWasShown:(NSNotification*)aNotification
{
	if ( !m_shouldRespondToKbdEvents )
	{
		return;
	}
	
	if ( !m_keyboardVisible )
	{
		NSDictionary* info = [aNotification userInfo];
		
		// Get the size of the keyboard.
		NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
		CGSize keyboardSize = [aValue CGRectValue].size;
		
		// Resize the scroll view (which is the root view of the window)
		CGRect viewFrame = [self.view frame];
		viewFrame.size.height -= keyboardSize.height;
		self.view.frame = viewFrame;
	}
	
	// Scroll the active text field into view.
	CGRect textFieldRect = [m_activeTextField frame];
	[(UIScrollView *)(self.view) scrollRectToVisible:textFieldRect animated:YES];
	
	m_keyboardVisible = YES;
	
	[(UIScrollView *)(self.view) flashScrollIndicators];
}


- (void)keyboardWasHidden:(NSNotification*)aNotification
{
	if ( !m_shouldRespondToKbdEvents )
	{
		return;
	}
	
	NSDictionary* info = [aNotification userInfo];

	// Get the size of the keyboard.
	NSValue* aValue = [info objectForKey:UIKeyboardBoundsUserInfoKey];
	CGSize keyboardSize = [aValue CGRectValue].size;

	// Reset the height of the scroll view to its original value
	CGRect viewFrame = [self.view frame];
	viewFrame.size.height += keyboardSize.height;
	self.view.frame = viewFrame;

	m_keyboardVisible = NO;
}


- (void)layoutUIForMessageType:(MessageTransport)type
{
	switch ( type )
	{
		default:
		case eMT_MyGov:
		{
			// everything is shown!
			[m_labelTo setHidden:NO];
			[m_fieldTo setHidden:NO];
			[m_fieldSubject setHidden:NO];
			[m_labelSubject setHidden:NO];
			[m_infoButton setHidden:NO];
			[m_fieldURL setHidden:NO];
			[m_labelURL setHidden:NO];
			[m_fieldURLTitle setHidden:NO];
			[m_labelURLTitle setHidden:NO];
		}
			break;
		
		case eMT_MyGovUserComment:
		{
			// don't show URL, or URLTitle fields
			[m_labelTo setHidden:NO];
			[m_fieldTo setHidden:NO];
			[m_fieldSubject setHidden:NO];
			[m_fieldSubject setText:@""];
			[m_labelSubject setHidden:NO];
			[m_infoButton setHidden:NO];
			[m_fieldURL setHidden:YES];
			[m_labelURL setHidden:YES];
			[m_fieldURLTitle setHidden:YES];
			[m_labelURLTitle setHidden:YES];
		}
			break;
			
		case eMT_SendTwitterDM:
		{
			// only show To: and Message: fields
			[m_labelTo setHidden:NO];
			[m_fieldTo setHidden:NO];
			[m_fieldSubject setHidden:YES];
			[m_labelSubject setHidden:YES];
			[m_infoButton setHidden:YES];
			[m_fieldURL setHidden:YES];
			[m_labelURL setHidden:YES];
			[m_fieldURLTitle setHidden:YES];
			[m_labelURLTitle setHidden:YES];
		}
			break;
			
		case eMT_SendTweet:
		{
			// only show Message: field
			[m_labelTo setHidden:YES];
			[m_fieldTo setHidden:YES];
			[m_fieldSubject setHidden:YES];
			[m_labelSubject setHidden:YES];
			[m_infoButton setHidden:YES];
			[m_fieldURL setHidden:YES];
			[m_labelURL setHidden:YES];
			[m_fieldURLTitle setHidden:YES];
			[m_labelURLTitle setHidden:YES];
		}
			break;
		
		case eMT_Email:
		case eMT_PhoneCall:
			// nothing to do here :-)
			break;
	}
	
	// starting Y position
	CGFloat yPos = CGRectGetMaxY(m_fieldTo.frame) + S_CELL_VOFFSET;
	
	CGFloat xPos, fWidth, fHeight;
	
#define MOVE_OBJ_UP(_OBJ)  \
		xPos = CGRectGetMinX( (_OBJ).frame ); \
		fWidth = CGRectGetWidth( (_OBJ).frame); \
		fHeight = CGRectGetHeight( (_OBJ).frame); \
		(_OBJ).frame = CGRectMake(xPos, yPos, fWidth, fHeight)
	
	// subject line
	if ( !m_fieldSubject.hidden )
	{
		MOVE_OBJ_UP(m_labelSubject);
		MOVE_OBJ_UP(m_fieldSubject);
		yPos = CGRectGetMaxY(m_fieldSubject.frame) + S_CELL_VOFFSET;
	}
	
	// info button
	if ( !m_infoButton.hidden )
	{
		MOVE_OBJ_UP(m_infoButton);
		if ( m_labelMessage.hidden )
		{
			yPos = CGRectGetMaxY(m_infoButton.frame) + S_CELL_VOFFSET;
		}
	}
	
	// message label
	if ( !m_labelMessage.hidden )
	{
		MOVE_OBJ_UP(m_labelMessage);
		yPos = CGRectGetMaxY(m_labelMessage.frame) + S_CELL_VOFFSET;
	}
	
	// message field
	if ( !m_fieldMessage.hidden )
	{
		MOVE_OBJ_UP(m_fieldMessage);
		MOVE_OBJ_UP(m_buttonMessage);
		yPos = CGRectGetMaxY(m_fieldMessage.frame) + S_CELL_VOFFSET;
	}
	
	// URL field
	if ( !m_fieldURL.hidden )
	{
		MOVE_OBJ_UP(m_labelURL);
		MOVE_OBJ_UP(m_fieldURL);
		yPos = CGRectGetMaxY(m_fieldURL.frame) + S_CELL_VOFFSET;
	}
	
	// URL title field
	if ( !m_fieldURLTitle.hidden )
	{
		MOVE_OBJ_UP(m_labelURLTitle);
		MOVE_OBJ_UP(m_fieldURLTitle);
		yPos = CGRectGetMaxY(m_fieldURLTitle.frame) + S_CELL_VOFFSET;
	}
}


- (NSString *)mygovUserAuthWithCallback:(SEL)callback
{
	m_shouldRespondToKbdEvents = YES;
	
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"gae_username"];
	NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"gae_password"];
	
	CommunityDataManager *cdm = [myGovAppDelegate sharedCommunityData];
	id<CommunityDataSourceProtocol> dataSource = [cdm dataSource];
	
	NSString *userID = [cdm currentlyAuthenticatedUser];
	
	if ( nil == userID )
	{
		if ( [username length] < 1 || [password length] < 1 )
		{
			if ( nil == m_mygovLoginView )
			{
				m_mygovLoginView = [[MyGovLoginViewController alloc] initWithNibName:@"MyGovLoginView" bundle:nil];
			}
			
			[m_mygovLoginView setNotifyTarget:self withSelector:callback];
			[m_mygovLoginView displayIn:self];
			/*
			// Grab the web-based URL and throw it up in the MiniBrowser
			NSURLRequest *loginURLRequest = [cdm dataSourceLoginURLRequest];
			
			MiniBrowserController *mbc = [MiniBrowserController sharedBrowser];
			m_shouldRespondToKbdEvents = NO;
			mbc.m_shouldUseParentsView = YES;
			[mbc LoadRequest:loginURLRequest];
			[mbc display:self];
			[mbc setAuthCallback:callback];
			*/
			return nil;
		}
		else
		{
			// authenticate the given username/password
			BOOL success = [dataSource validateUsername:username andPassword:password withDelegate:cdm];
			
			if ( !success )
			{
				m_alertType = eAlertType_MyGovAuthError;
				UIAlertView *alert = [[UIAlertView alloc] 
									  initWithTitle:@"Login Error"
									  message:[NSString stringWithString:@"Invalid username/password combo"]
									  delegate:self
									  cancelButtonTitle:nil
									  otherButtonTitles:@"OK",@"Reset",nil];
				[alert show];
				return nil;
			}
		}
	}
	
	// this should be the fully-authenticated userID!
	userID = [cdm currentlyAuthenticatedUser];
	
	return userID;
}


- (id)opMakePhoneCall
{
	// make a phone call!
	NSString *telStr = [[[NSString alloc] initWithFormat:@"tel:%@",m_message.m_to] stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding];
	NSURL *telURL = [[NSURL alloc] initWithString:telStr];
	[[UIApplication sharedApplication] openURL:telURL];
	[telStr release];
	[telURL release];
	
	return self;
}


- (id)opSendEmail
{
	NSString *emailStr = [[NSString alloc] initWithFormat:@"mailto:%@?subject=%@&body=%@",
												[m_message.m_to stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding], 
												[m_message.m_subject stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding],
												([m_message.m_body length] < 1 ? @" " : [m_message.m_body stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding])
						];
	NSURL *emailURL = [[NSURL alloc] initWithString:emailStr];
	[[UIApplication sharedApplication] openURL:emailURL];
	[emailStr release];
	[emailURL release];
	
	return self;
}


- (id)opSendTwitterDM
{
	MGTwitterEngine *twitterEngine = [myGovAppDelegate sharedTwitterEngine];
	[twitterEngine retain];
	
	if ( nil == m_twitterLoginView || ![m_twitterLoginView isLoggedIn] )
	{
		NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"twitter_username"];
		NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"twitter_password"];
	
		if ( ([username length] < 1) || ([password length] < 1) )
		{
			// no login info - show login view controller
			if ( nil == m_twitterLoginView )
			{
				m_twitterLoginView = [[TwitterLoginViewController alloc] initWithNibName:@"TwitterLoginView" bundle:nil];
			}
			
			[m_twitterLoginView setNotifyTarget:self withSelector:@selector(opSendTwitterDM)];
			[m_twitterLoginView displayIn:self];
			
			return nil;
		}
		else
		{
			[twitterEngine setUsername:username password:password];
		}
	}
	
	NSString *twitterID = [m_fieldTo.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
	NSString *tweet = m_fieldMessage.text;
	if ( [tweet length] > 140 )
	{
		tweet = [tweet substringToIndex:140];
	}
	
	[m_hud setText:@"Sending Twitter DM!" andIndicateProgress:YES];
	[m_hud show:YES];
	
	[self.view setUserInteractionEnabled:NO];
	[self.view setNeedsDisplay];
	
	[[myGovAppDelegate sharedAppDelegate] setTwitterNotifyTarget:self];
	[twitterEngine sendDirectMessage:tweet to:twitterID];
	
	[twitterEngine release];
	return nil;
}


- (id)opSendTweet
{
	MGTwitterEngine *twitterEngine = [myGovAppDelegate sharedTwitterEngine];
	[twitterEngine retain];
	
	if ( nil == m_twitterLoginView || ![m_twitterLoginView isLoggedIn] )
	{
		NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"twitter_username"];
		NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"twitter_password"];
		
		if ( ([username length] < 1) || ([password length] < 1) )
		{
			// no login info - show login view controller
			if ( nil == m_twitterLoginView )
			{
				m_twitterLoginView = [[TwitterLoginViewController alloc] initWithNibName:@"TwitterLoginView" bundle:nil];
			}
			
			[m_twitterLoginView setNotifyTarget:self withSelector:@selector(opSendTweet)];
			[m_twitterLoginView displayIn:self];
			
			return nil;
		}
		else
		{
			[twitterEngine setUsername:username password:password];
		}
	}
	
	NSString *tweet = m_fieldMessage.text;
	if ( [tweet length] > 140 )
	{
		tweet = [tweet substringToIndex:140];
	}
	
	[m_hud setText:@"Sending Tweet!" andIndicateProgress:YES];
	[m_hud show:YES];
	
	[self.view setUserInteractionEnabled:NO];
	[self.view setNeedsDisplay];
	
	[[myGovAppDelegate sharedAppDelegate] setTwitterNotifyTarget:self];
	[twitterEngine sendUpdate:tweet];
	
	[twitterEngine release];
	return nil;
}


- (id)opSendMyGovComment
{
	NSString *userID = [self mygovUserAuthWithCallback:@selector(opSendMyGovComment)];
	if ( nil == userID ) return nil;
	
	// create a new community item
	CommunityItem * item = [[[CommunityItem alloc] init] autorelease];
	
	[item generateUniqueItemID];
	
	item.m_type = eCommunity_Chatter;
	item.m_creator = userID;
	item.m_title = m_fieldSubject.text;
	item.m_text = m_fieldMessage.text;
	if ( [item.m_text length] > 200 )
	{
		item.m_summary = [NSString stringWithFormat:@"%@...",[item.m_text substringToIndex:200]];
	}
	else
	{
		item.m_summary = item.m_text;
	}
	
	item.m_date = [NSDate date];
	item.m_mygovURL = m_message.m_appURL;
	item.m_mygovURLTitle = m_message.m_appURLTitle;
	if ( [m_fieldURL.text length] > 0 )
	{
		item.m_webURL = [NSURL URLWithString:m_fieldURL.text];
	}
	else
	{
		item.m_webURL = m_message.m_webURL;
	}
	item.m_webURLTitle = (([m_fieldURLTitle.text length] > 0) ? m_fieldURLTitle.text : m_message.m_webURLTitle);
	
	[m_hud setText:@"Sending your comment..." andIndicateProgress:YES];
	[m_hud show:YES];
	
	[self.view setUserInteractionEnabled:NO];
	[self.view setNeedsDisplay];
	
	// send the out the new comment via a worker thread
	// (as per the CommunityDataSourceProtocol contract)
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		selector:@selector(sendCommunityItemViaDataSource:) 
																		  object:item];
	
	// Add the operation to the internal operation queue managed by the application delegate.
	[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
	
	[theOp release];
	
	// don't return from the modal dialog until things settle down a bt
	return nil;
}


- (id)opSendMyGovReply
{
	NSString *userID = [self mygovUserAuthWithCallback:@selector(opSendMyGovReply)];
	if ( nil == userID ) return nil;
	
	CommunityComment *reply = [[CommunityComment alloc] init];
	reply.m_id = @"mygov";
	reply.m_creator = userID;
	reply.m_title = m_fieldSubject.text;
	reply.m_text = m_fieldMessage.text;
	reply.m_communityItemID = m_message.m_communityThreadID;
	
	[m_hud setText:@"Sending your reply..." andIndicateProgress:YES];
	[m_hud show:YES];
	
	[self.view setUserInteractionEnabled:NO];
	[self.view setNeedsDisplay];
	
	// send the out the new comment via a worker thread
	// (as per the CommunityDataSourceProtocol contract)
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		selector:@selector(sendCommunityReplyViaDataSource:) 
																		  object:reply];
	
	// Add the operation to the internal operation queue managed by the application delegate.
	[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
	
	[theOp release];
	
	return nil;
}


- (void)twitterOpFinished:(NSString *)success
{
	[self.view setUserInteractionEnabled:YES];
	[m_hud show:NO];
	
	if ( [[success substringToIndex:2] isEqualToString:@"NO"] )
	{
		NSString *err = [success substringFromIndex:2];
		
		// pop up an alert saying it failed!
		m_alertType = eAlertType_TwitterError;
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Twitter DM Error"
							  message:[NSString stringWithFormat:@"Error: [%@]\nIs %@ following you?",err, m_fieldTo.text]
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:@"OK",@"Reset",nil];
		[alert show];
		return;
	}
	
	[self dismissModalViewControllerAnimated:YES];
}


// This runs in an NSOperation worker thread
- (void)sendCommunityItemViaDataSource:(CommunityItem *)item
{
	CommunityDataManager *cdm = [myGovAppDelegate sharedCommunityData];
	id<CommunityDataSourceProtocol> dataSource = [cdm dataSource];
	
	// this is the blocking call to the network submission...
	BOOL success = [dataSource submitCommunityItem:item withDelegate:nil];
	
	[self.view setUserInteractionEnabled:YES];
	[m_hud show:NO];
	
	if ( success )
	{
		// Add the event manually to our in-memory collection!
		//[cdm communityDataSource:dataSource newCommunityItemArrived:item];
		
		// re-load the community data to grab the new item
		[cdm loadData];
		
		[self dismissModalViewControllerAnimated:YES];
	}
	else
	{
		// ask the use what to do - couldn't send a message!
		m_alertType = eAlertType_ChatterError;
		UIAlertView *alert = [[UIAlertView alloc] 
									initWithTitle:@"Chatter Error"
									message:[NSString stringWithString:@"An error occurred while sending your comment."]
									delegate:self
									cancelButtonTitle:@"Cancel"
									otherButtonTitles:@"Retry",nil];
		[alert show];
	}
}


- (void)sendCommunityReplyViaDataSource:(CommunityComment *)reply
{
	CommunityDataManager *cdm = [myGovAppDelegate sharedCommunityData];
	id<CommunityDataSourceProtocol> dataSource = [cdm dataSource];
	
	// this is the blocking call to the network submission...
	BOOL success = [dataSource submitCommunityComment:reply withDelegate:nil];
	
	[self.view setUserInteractionEnabled:YES];
	[m_hud show:NO];
	
	if ( success )
	{
		// add the comment to our in-memory structure :-)
		//CommunityItem *ci = [[myGovAppDelegate sharedCommunityData] itemWithId:[reply.m_communityItemID integerValue]];
		//[ci addComment:reply];
		//[cdm communityDataSource:dataSource newCommunityItemArrived:ci];
		
		[cdm loadData];
		
		[self dismissModalViewControllerAnimated:YES];
	}
	else
	{
		// ask the use what to do - couldn't send a message!
		m_alertType = eAlertType_ReplyError;
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Reply Error"
							  message:[NSString stringWithString:@"An error occurred while sending your comment."]
							  delegate:self
							  cancelButtonTitle:@"Cancel"
							  otherButtonTitles:@"Retry",nil];
		[alert show];
	}
}


#pragma mark UIAlertViewDelegate Methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	switch ( m_alertType )
	{
		case eAlertType_TwitterError:
			switch ( buttonIndex )
			{
				case 0:
					// retry
					break;
					
				case 1:
					// reset credentials!
					[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"twitter_username"];
					[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"twitter_password"];
					[[NSUserDefaults standardUserDefaults] synchronize];
					break;
			}
			break;
		
		case eAlertType_ChatterError:
			switch ( buttonIndex )
			{
				case 1:
					// retry
					[self opSendMyGovComment];
					break;
					
				case 0:
					// cancel!
					[self dismissModalViewControllerAnimated:YES];
					break;
			}
			break;
		
		case eAlertType_ReplyError:
			switch ( buttonIndex )
			{
				case 1:
					// retry
					[self opSendMyGovReply];
					break;
					
				case 0:
					// cancel!
					[self dismissModalViewControllerAnimated:YES];
					break;
			}
			break;
		case eAlertType_MyGovAuthError:
			switch ( buttonIndex )
			{
				default:
				case 1:
					break;
				case 2:
					// reset credentials!
					[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"twitter_username"];
					[[NSUserDefaults standardUserDefaults] setObject:@"" forKey:@"twitter_password"];
					[[NSUserDefaults standardUserDefaults] synchronize];
					break;
			}
			break;
	}
}


@end

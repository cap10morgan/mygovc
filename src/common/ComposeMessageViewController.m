//
//  ComposeMessageViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"
#import "CommunityDataManager.h"
#import "CommunityDataSource.h"
#import "CommunityItem.h"
#import "ComposeMessageViewController.h"
#import "MGTwitterEngine.h"
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


@interface ComposeMessageViewController (private)
	- (id)opMakePhoneCall;
	- (id)opSendEmail;
	- (id)opSendTweet;
	- (id)opSendMyGovComment;
	- (void)sendCommunityItemViaDataSource:(CommunityItem *)item;
@end


@implementation ComposeMessageViewController

@synthesize m_titleButton, m_fieldTo, m_labelSubject, m_fieldSubject;
@synthesize m_fieldMessage, m_infoButton;


static ComposeMessageViewController *s_composer = NULL;


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
	[m_message release];
	[super dealloc];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	m_hud = [[ProgressOverlayViewController alloc] initWithWindow:self.view];
}


- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    // Dismiss the keyboard when the view outside the text field is touched.
	[m_fieldMessage resignFirstResponder];
	[m_fieldTo resignFirstResponder];
	[m_fieldSubject resignFirstResponder];
    [super touchesBegan:touches withEvent:event];
}


#pragma mark UITextFieldDelegate


- (BOOL)textFieldShouldReturn:(UITextField *)theTextField 
{
	// When the user presses return, take focus away from the text field so that the keyboard is dismissed.
	[theTextField resignFirstResponder];
	return YES;
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
			[m_fieldSubject setHidden:NO];
			[m_labelSubject setHidden:NO];
			[m_infoButton setHidden:NO];
			break;
		
		case eMT_Twitter:
			titleTxt = @"Tweet";
			[m_fieldSubject setHidden:YES];
			[m_labelSubject setHidden:YES];
			[m_infoButton setHidden:YES];
			break;
			
		case eMT_Email:
			titleTxt = @"Email";
			[m_fieldSubject setHidden:NO];
			[m_labelSubject setHidden:NO];
			// don't display the UI (for now) - call the application
			// email send routine
			[self opSendEmail];
			return;
		
		case eMT_PhoneCall:
			titleTxt = @"PhoneCall";
			[m_fieldSubject setHidden:YES];
			[m_labelSubject setHidden:YES];
			// don't display the UI - just make the phone call
			[self opMakePhoneCall];
			return;
	}
	
	m_titleButton.title = titleTxt;
	
	[m_fieldTo setText:m_message.m_to];
	[m_fieldSubject setText:m_message.m_subject];
	[m_fieldMessage setText:m_message.m_body];
	
	[m_fieldTo setEnabled:NO];
	
	m_parentCtrl = parentController;
	[m_parentCtrl presentModalViewController:self animated:YES];
}


- (IBAction)cancelButtonPressed:(id)sender
{
	[m_parentCtrl dismissModalViewControllerAnimated:YES];
}


- (IBAction)sendButtonPressed:(id)sender
{
	[m_fieldMessage resignFirstResponder];
    [m_fieldTo resignFirstResponder];
	[m_fieldSubject resignFirstResponder];
		
	SEL sendOp = nil;
	NSString *transportDescrip;
	switch ( m_message.m_transport )
	{
		default:
		case eMT_MyGov:
			transportDescrip = @"MyGov Comment";
			sendOp = @selector(opSendMyGovComment);
			break;
			
		case eMT_Twitter:
			transportDescrip = @"Tweet";
			sendOp = @selector(opSendTweet);
			break;
			
		case eMT_Email:
			transportDescrip = @"Email";
			sendOp = @selector(opSendEmail);
			break;
		
		case eMT_PhoneCall:
			transportDescrip = @"Phone Call";
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


#pragma mark UITextViewDelegate Methods 
	
- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	return YES;
}


#pragma mark ComposeMessageViewController Private 

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
	
	NSString *twitterID = [m_fieldTo.text stringByReplacingOccurrencesOfString:@"@" withString:@""];
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
	[twitterEngine sendDirectMessage:tweet to:twitterID];
	
	[twitterEngine release];
	return nil;
}


- (id)opSendMyGovComment
{
	NSInteger userID = 0;
	NSString *username = [[NSUserDefaults standardUserDefaults] objectForKey:@"mygov_username"];
	NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:@"mygov_password"];
	
	if ( [username length] < 1 || [password length] < 1 )
	{
		// XXX - the user should be logged in - take care of that right here!
		// XXX - get the userID!
	}
	
	// create a new community item
	CommunityItem * item = [[[CommunityItem alloc] init] autorelease];
	
	[item generateUniqueItemID];
	
	item.m_type = eCommunity_Feedback;
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
	item.m_webURL = m_message.m_webURL;
	item.m_webURLTitle = m_message.m_webURLTitle;
	
	// data is available - read disk data into memory (via a worker thread)
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		selector:@selector(sendCommunityItemViaDataSource:) 
																		  object:item];
	
	// Add the operation to the internal operation queue managed by the application delegate.
	[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
	
	[theOp release];
	
	// don't return from the modal dialog until things settle down a bt
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
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Tweet Error"
							  message:[NSString stringWithFormat:@"Error: %@",err]
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
	id<CommunityDataSourceProtocol> dataSource = [[myGovAppDelegate sharedCommunityData] dataSource];
	
	// this is the blocking call to the network submission...
	BOOL success = [dataSource submitCommunityItem:item withDelegate:nil];
	
	if ( success )
	{
		[self dismissModalViewControllerAnimated:YES];
	}
	else
	{
		// XXX - ask the use what to do - couldn't send a message!
		[self dismissModalViewControllerAnimated:YES];
	}
}


#pragma mark UIAlertViewDelegate Methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
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
}


@end

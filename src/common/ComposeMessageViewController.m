//
//  ComposeMessageViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ComposeMessageViewController.h"
#import "ProgressOverlayViewController.h"

@implementation MessageData

@synthesize m_transport, m_to, m_subject, m_body;

@end


@interface ComposeMessageViewController (private)
	- (void)opMakePhoneCall;
	- (void)opSendEmail;
	- (void)opSendTweet;
	- (void)opSendMyGovComment;
@end


@implementation ComposeMessageViewController

@synthesize m_titleButton, m_fieldTo, m_labelSubject, m_fieldSubject, m_fieldMessage;


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
			break;
		
		case eMT_Twitter:
			titleTxt = @"Tweet";
			[m_fieldSubject setHidden:YES];
			[m_labelSubject setHidden:YES];
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
	ProgressOverlayViewController *hud;
	hud = [[ProgressOverlayViewController alloc] initWithWindow:self.view];
	
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
	
	if ( nil != sendOp )
	{
		NSString *msg = [[[NSString alloc] initWithFormat:@"Sending %@...",transportDescrip] autorelease];
		[hud setText:msg andIndicateProgress:YES];
		[hud show:YES];
		
		[self performSelector:sendOp];
		
		[msg release];
	}
	
	[hud show:NO];
	[hud release];
	
	// XXX - warn about errors here!
	
	[m_parentCtrl dismissModalViewControllerAnimated:YES];
}


#pragma mark UITextViewDelegate Methods 
	
- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	return YES;
}


#pragma mark ComposeMessageViewController Private 

- (void)opMakePhoneCall
{
	// make a phone call!
	NSString *telStr = [[[NSString alloc] initWithFormat:@"tel:%@",m_message.m_to] stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding];
	NSURL *telURL = [[NSURL alloc] initWithString:telStr];
	[[UIApplication sharedApplication] openURL:telURL];
	[telStr release];
	[telURL release];
}


- (void)opSendEmail
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
}


- (void)opSendTweet
{
	// XXX - use twitter engine!
}


- (void)opSendMyGovComment
{
	// XXX - fill me in!!
	[NSThread sleepForTimeInterval:5.0f];
}

@end

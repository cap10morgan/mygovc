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



@implementation ComposeMessageViewController

@synthesize m_titleButton, m_fieldTo, m_fieldSubject, m_fieldMessage;


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
			break;
		
		case eMT_Twitter:
			titleTxt = @"Tweet";
			break;
			
		case eMT_Email:
			titleTxt = @"Email";
			break;
	}
	
	m_titleButton.title = titleTxt;
	
	[m_fieldTo setText:m_message.m_to];
	[m_fieldSubject setText:m_message.m_subject];
	[m_fieldMessage setText:m_message.m_body];
	
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
	NSString *transportType;
	switch ( m_message.m_transport )
	{
		default:
		case eMT_MyGov:
			transportType = @"MyGov Comment";
			sendOp = nil;
			break;
			
		case eMT_Twitter:
			transportType = @"Tweet";
			sendOp = nil;
			break;
			
		case eMT_Email:
			transportType = @"Email";
			sendOp = nil;
			break;
	}
	
	NSString *msg = [[[NSString alloc] initWithFormat:@"Sending %@...",transportType] autorelease];
	[hud setText:msg andIndicateProgress:YES];
	[hud show:YES];
	
	// XXX - do the sending here!
	if ( nil != sendOp )
	{
		[self performSelector:sendOp];
	}
	
	[hud show:NO];
	[hud release];
	[msg release];
	
	// XXX - warn about errors here!
	
	[m_parentCtrl dismissModalViewControllerAnimated:YES];
}

	
#pragma mark UITextViewDelegate Methods 
	
- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
	return YES;
}


@end

//
//  LegislatorHeaderViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LegislatorHeaderViewController.h"
#import "LegislatorContainer.h"

@interface LegislatorHeaderViewController (private)
	- (void)imageDownloadComplete:(UIImage *)img;
@end

@implementation LegislatorHeaderViewController

@synthesize m_name;
@synthesize m_partyInfo;
@synthesize m_img;

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[m_legislator release];
	[super dealloc];
}


/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	if ( self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] ) 
	{
		m_legislator = nil;
	}
	return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView 
{
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	m_legislator = nil;
	[super viewDidLoad];
}



// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark LegislatorHeaderViewController interface 


- (IBAction) addLegislatorToContacts:(id)sender
{
	if ( nil == m_legislator ) return;
	
	// XXX - add legislator to contacts
	// XXX - maybe pop-up a UIActionSheet to confirm?
}


- (IBAction) getLegislatorBio:(id)sender
{
	if ( nil == m_legislator ) return;
	
	// XXX - display bio information as retrieved from: [...]
}


- (void)setLegislator:(LegislatorContainer *)legislator
{
	[m_legislator release];
	m_legislator = [legislator retain];
	
	[m_legislator setImageCallback:@selector(imageDownloadComplete:) onObject:self];
	
	// set legislator name 
	NSString *fname = [m_legislator firstname];
	NSString *mname = [m_legislator middlename];
	NSString *lname = [m_legislator lastname];
	NSString *nm = [[NSString alloc] initWithFormat:@"%@. %@ %@%@%@",[m_legislator title],fname,(mname ? mname : @""),(mname ? @" " : @""),lname];
	m_name.text = nm;
	[nm release];
	
	// set legislator party info
	NSString *party = [m_legislator party];
	NSString *state = [m_legislator state];
	NSString *district = [[[NSString alloc] initWithFormat:@" District %@",[m_legislator district]] autorelease];
	NSString *partyTxt = [[NSString alloc] initWithFormat:@"(%@) %@%@",party,state,([[m_legislator title] isEqualToString:@"Rep"] ? district : @"")];
	m_partyInfo.text = partyTxt;
	if ( [party isEqualToString:@"R"] )
	{
		m_partyInfo.textColor = [UIColor redColor];
	}
	else if ( [party isEqualToString:@"D"] )
	{
		m_partyInfo.textColor = [UIColor blueColor];
	}
	else
	{
		m_partyInfo.textColor = [UIColor whiteColor];
	}
	[partyTxt release];
	
	// set legislator photo
	UIImage *img = [m_legislator getImageAndBlock:NO];
	if ( nil == img )
	{
		// overlay a UIActivityIndicatorView on the image to
		// tell the user we're working on it!
		UIActivityIndicatorView *aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		aiView.hidesWhenStopped = YES;
		[aiView setFrame:CGRectMake(0.0f, 0.0f, 50.0f, 50.0f)];
		[aiView setCenter:CGPointMake(50.0f, 60.0f)];
		[aiView setTag:999];
		[m_img addSubview:aiView];
		[aiView startAnimating];
		[aiView release];
	}
	else
	{
		[m_img setImage:img];
	}
}


- (void)imageDownloadComplete:(UIImage *)img
{
	UIActivityIndicatorView *aiView = (UIActivityIndicatorView *)[m_img viewWithTag:999];
	if ( nil != aiView )
	{
		[aiView stopAnimating];
		[aiView removeFromSuperview];
	}
	
	if ( nil != img ) [m_img setImage:img];
}


@end

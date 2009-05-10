//
//  LegislatorHeaderViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/9/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"

#import "DataProviders.h"
#import "LegislatorContainer.h"
#import "LegislatorHeaderViewController.h"
#import "LegislatorViewController.h"
#import "MiniBrowserController.h"
#import "StateAbbreviations.h"

@interface LegislatorHeaderViewController (private)
	- (void)imageDownloadComplete:(UIImage *)img;
	- (void)startLargeImageDownload:(id)sender;
	- (void)largeImageDownloadComplete:(UIImage *)img;
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
	[m_navController release];
	[m_largeImg release];
	[super dealloc];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	m_legislator = nil;
	m_navController = nil;
	m_largeImg = nil;
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
	if ( nil == m_navController ) return;
	
	// try to use the large image if it's available...
	[m_navController addLegislatorToContacts:m_legislator withImage:(nil != m_largeImg ? m_largeImg : m_img.image)];
}


- (IBAction) getLegislatorBio:(id)sender
{
	if ( nil == m_legislator ) return;
	if ( nil == m_navController ) return;
	
	NSURL *bioguideURL = [NSURL URLWithString:[DataProviders Bioguide_LegislatorBioURL:m_legislator]];
	
	MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:bioguideURL];
	[mbc display:m_navController];
}


- (void)setNavController:(id)controller
{
	[m_navController release];
	m_navController = [controller retain];
}


- (void)setLegislator:(LegislatorContainer *)legislator
{
	[m_legislator release];
	m_legislator = [legislator retain];
	
	[m_legislator setCallbackObject:self];
	
	// set legislator name 
	NSString *nickname = [m_legislator nickname];
	NSString *fname = [m_legislator firstname];
	NSString *mname = ([nickname length] > 0 ? @"" : [m_legislator middlename]);
	NSString *lname = [m_legislator lastname];
	NSString *nm = [[NSString alloc] initWithFormat:@"%@. %@ %@%@%@",
									[m_legislator title],
									([nickname length] > 0 ? nickname : fname),
									(mname ? mname : @""),
									(mname ? @" " : @""),lname
					];
	m_name.text = nm;
	[nm release];
	
	// set legislator party info
	NSString *party = [m_legislator party];
	NSString *state = [StateAbbreviations nameFromAbbr:[m_legislator state]];
	NSString *district = [[NSString alloc] initWithFormat:@" %@",([[m_legislator district] isEqualToString:@"0"] ? @"At-Large" : [m_legislator district])];
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
	[district release];
	[partyTxt release];
	
	// set legislator photo
	UIImage *img = [m_legislator getImage:eLegislatorImage_Medium andBlock:NO withCallbackOrNil:@selector(imageDownloadComplete:)];
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
		// must have loaded from disk :-)
		[m_img setImage:img];
		
		// start a large image download (for contact adding)
		[m_largeImg release];
		m_largeImg = [m_legislator getImage:eLegislatorImage_Large andBlock:NO withCallbackOrNil:@selector(largeImageDownloadComplete:)];
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
	
	// start a large image download, but not from the callback!
	// start image download
	// data is available - read disk data into memory (via a worker thread)
	NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																  selector:@selector(startLargeImageDownload:) object:self];
	
	// Add the operation to the internal operation queue managed by the application delegate.
	[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
	
	[theOp release];
}


- (void)startLargeImageDownload:(id)sender
{
	if ( sender != self ) return;
	
	// wait until the previous image has completely downloaded
	static const int MAX_SLEEPS = 300;
	static const CGFloat SLEEP_INTERVAL = 0.1f;
	int numSleeps = 0;
	while ( [m_legislator isDownloadingImage] && (numSleeps <= MAX_SLEEPS) )
	{
		[NSThread sleepForTimeInterval:SLEEP_INTERVAL];
		++numSleeps;
	}
	
	// start a large image download (for contact adding)
	[m_largeImg release];
	m_largeImg = [m_legislator getImage:eLegislatorImage_Large andBlock:NO withCallbackOrNil:@selector(largeImageDownloadComplete:)];
}


- (void)largeImageDownloadComplete:(UIImage *)img
{
	if ( nil != img ) m_largeImg = [img retain];
}

@end

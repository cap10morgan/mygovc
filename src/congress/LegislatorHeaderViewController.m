/*
 File: LegislatorHeaderViewController.m
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

#import "DataProviders.h"
#import "LegislatorContainer.h"
#import "LegislatorHeaderViewController.h"
#import "LegislatorDetailViewController.h"
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
@synthesize m_districtInfoButton;
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
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	MYGOV_SHOULD_SUPPORT_ROTATION(toInterfaceOrientation);
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


- (IBAction) showLegislatorDistrict:(id)sender
{
	if ( nil == m_legislator ) return;
	if ( nil == m_navController ) return;
	
	NSString *state = [m_legislator state];
	NSInteger district = [[m_legislator district] intValue];
	
	NSURL *districtURL = [NSURL URLWithString:[DataProviders Govtrack_DistrictMapURL:state forDistrict:district]];
	
	MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:districtURL];
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
	
	// for image downloading notification
	[m_legislator setCallbackObject:self];
	
	m_name.text = [m_legislator shortName];
	
	// set legislator party info
	NSString *party = [m_legislator party];
	NSString *state = [StateAbbreviations nameFromAbbr:[m_legislator state]];
	NSString *district = [[NSString alloc] initWithFormat:@" %@",([[m_legislator district] isEqualToString:@"0"] ? @"At-Large" : [m_legislator district])];
	NSString *partyTxt;
	if ( [[m_legislator title] isEqualToString:@"Rep"] )
	{
		partyTxt = [[NSString alloc] initWithFormat:@"(%@) %@%@",party,state,district];
		[m_districtInfoButton setHidden:FALSE];
	}
	else 
	{
		partyTxt = [[NSString alloc] initWithFormat:@"(%@) %@",party,state];
		[m_districtInfoButton setHidden:TRUE];
	}

	m_partyInfo.text = partyTxt;
	m_partyInfo.textColor = [LegislatorContainer partyColor:party];
	
	[district release];
	[partyTxt release];
	
	// set legislator photo
	UIImage *img = [m_legislator getImage:eLegislatorImage_Medium andBlock:NO withCallbackOrNil:@selector(imageDownloadComplete:)];
	if ( nil == img )
	{
		// XXX - notify the user of the background network activity
		
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
	[myGovAppDelegate networkNoLongerInUse];
	
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
	static const int MAX_SLEEPS = 500;
	static const CGFloat SLEEP_INTERVAL = 0.1f;
	int numSleeps = 0;
	while ( [m_legislator isDownloadingImage] && (numSleeps <= MAX_SLEEPS) )
	{
		[NSThread sleepForTimeInterval:SLEEP_INTERVAL];
		++numSleeps;
	}
	
	// start a large image download (for contact adding)
	[m_largeImg release];
	[myGovAppDelegate networkIsAvailable:YES];
	m_largeImg = [m_legislator getImage:eLegislatorImage_Large andBlock:NO withCallbackOrNil:@selector(largeImageDownloadComplete:)];
	
	if ( nil != m_largeImg ) [myGovAppDelegate networkNoLongerInUse];
}


- (void)largeImageDownloadComplete:(UIImage *)img
{
	[myGovAppDelegate networkNoLongerInUse];
	if ( nil != img ) m_largeImg = [img retain];
}

@end

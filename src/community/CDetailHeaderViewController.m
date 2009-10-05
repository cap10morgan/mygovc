/*
 File: CDetailHeaderViewController.m
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
#import "CDetailHeaderViewController.h"
#import "CommunityItem.h"
#import "MiniBrowserController.h"
#import "MyGovUserData.h"

@implementation CDetailHeaderViewController

@synthesize m_name;
@synthesize m_mygovURLTitle;
@synthesize m_webURLTitle;
@synthesize m_img;
@synthesize m_dateLabel;
@synthesize m_myGovURLButton, m_webURLButton;

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[m_item release];
	[super dealloc];
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
	if ( self = [super initWithNibName:nibName bundle:nibBundle] )
	{
		m_item = nil;
		m_largeImg = nil;
	}
	return self;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	m_item = nil;
	[super viewDidLoad];
	
	// adjust the header label parameters
	m_name.font = [UIFont boldSystemFontOfSize:16.0f];
	m_name.numberOfLines = 2;
	m_name.lineBreakMode = UILineBreakModeWordWrap;
	
	m_mygovURLTitle.font = [UIFont systemFontOfSize:14.0f];
	m_webURLTitle.font = [UIFont systemFontOfSize:14.0f];
	
	[m_myGovURLButton addTarget:self action:@selector(openMyGovURL) forControlEvents:UIControlEventTouchUpInside];
	[m_webURLButton addTarget:self action:@selector(openWebURL) forControlEvents:UIControlEventTouchUpInside];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}


#pragma mark CDetailHeaderViewController interface 


- (void)openMyGovURL
{
	if ( nil == m_item ) return;
	/*
	NSString *urlStr = [NSString stringWithFormat:kBioguideURLFmt,[m_item bioguide_id]];
	
	MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:[NSURL URLWithString:urlStr]];
	[mbc display:m_navController];
	 */
	[[UIApplication sharedApplication] openURL:m_item.m_mygovURL];
}


- (void)openWebURL
{
	if ( nil == m_item ) return;
	
	MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:m_item.m_webURL];
	[mbc display:[[myGovAppDelegate sharedAppDelegate] topViewController]];
}


- (void)setItem:(CommunityItem *)item
{
	[m_item release];
	m_item = [item retain];
	
	m_name.text = m_item.m_title;
	m_mygovURLTitle.text = m_item.m_mygovURLTitle;
	m_webURLTitle.text = m_item.m_webURLTitle;
	
	if ( m_item.m_type == eCommunity_Event )
	{
		m_dateLabel.text = @"Details:";
	}
	else
	{
		NSDateFormatter *dateFmt = [[[NSDateFormatter alloc] init] autorelease];
		[dateFmt setDateFormat:@"yyyy-MM-dd 'at' HH:mm"];
		
		m_dateLabel.text = [NSString stringWithFormat:@"On %@, %@ said:", 
										[dateFmt stringFromDate:m_item.m_date],
										[[[myGovAppDelegate sharedUserData] userFromUsername:m_item.m_creator] m_username]
							];
	}
	
	if ( nil != m_item.m_image )
	{
		m_img.image = m_item.m_image;
	}
	else
	{
		MyGovUser *creator = [[myGovAppDelegate sharedUserData] userFromUsername:m_item.m_creator];
		if ( nil != [creator m_avatar] )
		{
			m_img.image = creator.m_avatar;
		}
	}
	
	[m_myGovURLButton setHidden:NO];
	if ( nil == m_item.m_mygovURL )
	{
		// hide detail disclosure button!
		[m_myGovURLButton setHidden:YES];
	}
	
	[m_webURLButton setHidden:NO];
	if ( nil == m_item.m_webURL )
	{
		// hide detail disclosure button!
		[m_webURLButton setHidden:YES];
	}
}



@end

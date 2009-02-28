//
//  SpendingViewController.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SpendingViewController.h"

@interface SpendingViewController (private)
	- (void)queryMethodSwitch: (id)sender;
@end

@implementation SpendingViewController

UISegmentedControl *m_segmentCtrl;


- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
    [super dealloc];
}


- (void)queryMethodSwitch: (id)sender
{
	switch ( [sender selectedSegmentIndex] )
	{
		default:
		case 0:
			// This is "District"
			break;
			
		case 1:
			// This is "State"
			break;
			
		case 2:
			// This is "Contractor"
			break;
	}
}


- (void)viewDidLoad
{
	// Create a new segment control and place it in 
	// the NavigationController's title area
	NSArray *buttonNames = [NSArray arrayWithObjects:@"District", @"State", @"Contractor", nil];
	m_segmentCtrl = [[UISegmentedControl alloc] initWithItems:buttonNames];
	
	// default styles
	m_segmentCtrl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	m_segmentCtrl.segmentedControlStyle = UISegmentedControlStyleBar;
	m_segmentCtrl.selectedSegmentIndex = 0; // Default to "District"
	m_segmentCtrl.frame = CGRectMake(0,0,230,30);
	// saturation of 0.0 means black/white
	m_segmentCtrl.tintColor = [[UIColor alloc] initWithHue:0.0 saturation:0.0 brightness:0.45 alpha:1.0];
	
	// add ourself as the target
	[m_segmentCtrl addTarget:self action:@selector(queryMethodSwitch:) forControlEvents:UIControlEventValueChanged];
	
	// add the buttons to the navigation bar
	self.navigationItem.titleView = m_segmentCtrl;
	[m_segmentCtrl release];
	
	// XXX - Add a "location" button
	
	[super viewDidLoad];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return YES;
}


@end

//
//  SpendingViewController.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import "myGovAppDelegate.h"

#import "SpendingViewController.h"
#import "SpendingDataManager.h"
#import "StateAbbreviations.h"


@interface SpendingViewController (private)
	- (void)queryMethodSwitch:(id)sender;
	- (void)sortSpendingData;
	- (void)findLocalSpenders:(id)sender;
@end

@implementation SpendingViewController


static id s_alphabet[26] = 
{
	@"A",@"B",@"C",@"D",@"E",@"F",@"G",@"H",@"I",
	@"J",@"K",@"L",@"M",@"N",@"O",@"P",@"Q",@"R",
	@"S",@"T",@"U",@"V",@"W",@"X",@"Y",@"Z"
};


- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[m_data release];
    [super dealloc];
}


- (void)viewDidLoad
{
	m_data = [[myGovAppDelegate sharedSpendingData] retain];
	
	self.title = @"Spending";
	
	self.tableView.rowHeight = 50.0f;
	
	// Create a new segment control and place it in 
	// the NavigationController's title area
	NSArray *buttonNames = [NSArray arrayWithObjects:@"District", @"State", @"Contractor", nil];
	m_segmentCtrl = [[UISegmentedControl alloc] initWithItems:buttonNames];
	
	// default styles
	m_segmentCtrl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	m_segmentCtrl.segmentedControlStyle = UISegmentedControlStyleBar;
	m_segmentCtrl.selectedSegmentIndex = 0; // Default to "District"
	m_selectedQueryMethod = eSQMDistrict;
	m_segmentCtrl.frame = CGRectMake(0,0,230,30);
	// saturation of 0.0 means black/white
	m_segmentCtrl.tintColor = [[UIColor alloc] initWithHue:0.0 saturation:0.0 brightness:0.45 alpha:1.0];
	
	// add ourself as the target
	[m_segmentCtrl addTarget:self action:@selector(queryMethodSwitch:) forControlEvents:UIControlEventValueChanged];
	
	// add the buttons to the navigation bar
	self.navigationItem.titleView = m_segmentCtrl;
	[m_segmentCtrl release];
	
	// 
	// Add an "organize button which will present the user with a method of
	// sorting the displayed data
	// 
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
											   initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize 
											   target:self 
											   action:@selector(sortSpendingData)] autorelease];
	
	
	// 
	// Add a "location" button which will be used to find senators/representatives
	// which represent a users current district
	// 
	UIImage *locImg = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"location_overlay.png"]];
	UIBarButtonItem *locBarButton = [[[UIBarButtonItem alloc] 
									  initWithImage:locImg 
									  style:UIBarButtonItemStylePlain 
									  target:self 
									  action:@selector(findLocalSpenders:)] autorelease];
	self.navigationItem.leftBarButtonItem = locBarButton;
	self.navigationItem.leftBarButtonItem.width = self.navigationItem.rightBarButtonItem.width;
	
	[super viewDidLoad];
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return YES;
}


#pragma mark SpendingViewController Private 


- (void)queryMethodSwitch: (id)sender
{
	switch ( [sender selectedSegmentIndex] )
	{
		default:
		case 0:
			// This is "District"
			m_selectedQueryMethod = eSQMDistrict;
			break;
			
		case 1:
			// This is "State"
			m_selectedQueryMethod = eSQMState;
			break;
			
		case 2:
			// This is "Contractor"
			m_selectedQueryMethod = eSQMContractor;
			break;
	}
	if ( [m_data isDataAvailable] )
	{
		[self.tableView reloadData];
		NSUInteger idx[2] = {0,0};
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
	}
}


- (void)sortSpendingData
{
}


- (void)findLocalSpenders:(id)sender
{
}


#pragma mark UIActionSheetDelegate methods


// action sheet callback: maybe start a re-download on congress data
- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch ( buttonIndex )
	{
		case 0:
			// XXX 
		case 1:
			// XXX 
		case 2:
			// XXX
		default:
			break;
	}
}


#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if ( m_selectedQueryMethod == eSQMContractor )
	{
		return 26; // XXX - get number of categories from SpendingDataManager...
	}
	else if ( m_selectedQueryMethod == eSQMState )
	{
		return 1; // 1 row per state
	}
	else
	{
		// 1 row per district, organized into states
		return [[StateAbbreviations abbrList] count];
	}
}


- (NSArray *)sectionIndexTitlesForTableView: (UITableView *)tableView
{
	if ( [m_data isDataAvailable] )
	{
		if ( m_selectedQueryMethod == eSQMContractor )
		{
			// XXX - get categories from SpendingDataManager...
			return [NSArray arrayWithObjects:s_alphabet count:26];
		}
		else if ( m_selectedQueryMethod == eSQMState )
		{
			return nil; // no categories
		}
		else
		{
			return [StateAbbreviations abbrTableIndexList];
		}
	}
	else
	{
		return nil;
	}
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ( [m_data isDataAvailable] )
	{
		if ( m_selectedQueryMethod == eSQMContractor )
		{
			if ( section < 26 ) return s_alphabet[section];
			return nil;
		}
		else if ( m_selectedQueryMethod == eSQMState )
		{
			return nil;
		}
		else
		{
			// get full state name
			return [[StateAbbreviations nameList] objectAtIndex:section];
		}
	}
	else
	{
		return nil;
	}
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if ( [m_data isDataAvailable] )
	{
		//NSString *state = [[StateAbbreviations abbrList] objectAtIndex:section];
		switch (m_selectedQueryMethod) 
		{
			default:
			case eSQMDistrict:
				return 1; // get number from SpendingDataManager
			case eSQMState:
				return [[StateAbbreviations abbrList] count];
			case eSQMContractor:
				return 1; // get number from SpendingDataManager
		}
	}
	else
	{
		return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
	static NSString *CellIdentifier = @"SpendingCell";
	
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if ( cell == nil ) 
	{
		cell = [[UITableViewCell alloc] initWithFrame:CGRectZero];
	}
	
	if ( ![m_data isDataAvailable] )
	{
		cell.text = @"waiting...";
		return cell;
	}
	
	// setup custom cell!
	// XXX - do this :-)
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// XXX - do something !
}


@end

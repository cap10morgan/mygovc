//
//  SpendingViewController.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import "myGovAppDelegate.h"

#import "CongressDataManager.h"
#import "LegislatorContainer.h"
#import "PlaceSpendingData.h"
#import "PlaceSpendingTableCell.h"
#import "ProgressOverlayViewController.h"
#import "SpendingDataManager.h"
#import "SpendingViewController.h"
#import "StateAbbreviations.h"


@interface SpendingViewController (private)
	- (void)dataManagerCallback:(id)sender;
	- (void)queryMethodSwitch:(id)sender;
	- (void)sortSpendingData;
	- (void)findLocalSpenders:(id)sender;
	- (void) deselectRow:(id)sender;
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
	[m_HUD release];
    [super dealloc];
}


- (void)viewDidLoad
{
	m_data = [[myGovAppDelegate sharedSpendingData] retain];
	
	self.title = @"Spending";
	
	self.tableView.rowHeight = 40.0f;
	
	m_HUD = [[ProgressOverlayViewController alloc] initWithWindow:self.tableView];
	[m_HUD show:NO];
	[m_HUD setText:@"Waiting for data..." andIndicateProgress:YES];
	
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


- (void)viewWillAppear:(BOOL)animated 
{
	[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
	
	if ( ![m_data isDataAvailable] )
	{
		self.tableView.userInteractionEnabled = NO;
	}
	
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated 
{
	if ( [m_data isDataAvailable] )
	{
		self.tableView.userInteractionEnabled = YES;
	}
	else
	{
		[m_HUD show:YES]; // with whatever text is there...
		[m_HUD setText:m_HUD.m_label.text andIndicateProgress:YES];
	}
	
	// de-select the currently selected row
	// (so the user can go back to the same district/state/contractor)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
	
	[super viewDidAppear:animated];
}


/*
- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
}
*/

/*
- (void)viewDidDisappear:(BOOL)animated 
{
	[super viewDidDisappear:animated];
}
*/


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Return YES for supported orientations
    return YES;
}


#pragma mark SpendingViewController Private 


- (void)dataManagerCallback:(id)sender
{
	NSLog( @"SpendingViewController: dataManagerCallback!" );
	if ( [m_data isDataAvailable] )
	{
		[self.tableView reloadData];
		[m_HUD show:NO];
		self.tableView.userInteractionEnabled = YES;
	}
	else
	{
		// something interesting must have happened,
		// update the user with some progress
		self.tableView.userInteractionEnabled = NO;
		[m_HUD show:YES];
		[m_HUD setText:[NSString stringWithString:@"Waiting for data..."] andIndicateProgress:YES];
	}
}


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


- (void) deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same row)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
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
		NSString *state = [[StateAbbreviations abbrList] objectAtIndex:section];
		switch (m_selectedQueryMethod) 
		{
			default:
			case eSQMDistrict:
				return [m_data numDistrictsInState:state];
			case eSQMState:
				return [[StateAbbreviations abbrList] count]; // one row per state
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
	static NSString *PlaceCellIdentifier = @"PlaceSpendingCell";
	static NSString *CtorCellIdendifier = @"ContractorCell";
	
	UITableViewCell *tcell;
	if ( eSQMContractor == m_selectedQueryMethod )
	{
		tcell = [tableView dequeueReusableCellWithIdentifier:CtorCellIdendifier];
		if ( tcell == nil )
		{
			tcell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CtorCellIdendifier] autorelease];
		}
		//tcell.text = @"?!?";
	}
	else
	{
		PlaceSpendingTableCell *cell = (PlaceSpendingTableCell *)[tableView dequeueReusableCellWithIdentifier:PlaceCellIdentifier];
		if ( cell == nil ) 
		{
			cell = [[[PlaceSpendingTableCell alloc] initWithFrame:CGRectZero reuseIdentifier:PlaceCellIdentifier detailTarget:self detailSelector:nil] autorelease];
		}
	
		PlaceSpendingData *psd;
		if ( eSQMState == m_selectedQueryMethod )
		{
			NSString *state = [[StateAbbreviations abbrList] objectAtIndex:indexPath.row];
			psd = [m_data getStateData:state andWaitForDownload:NO];
		}
		else if ( eSQMDistrict == m_selectedQueryMethod )
		{
			NSString *state = [[StateAbbreviations abbrList] objectAtIndex:indexPath.section];
			NSString *districtStr = [NSString stringWithFormat:@"%@%.2d",state,([m_data numDistrictsInState:state] > 1 ? (indexPath.row + 1) : indexPath.row)];
			psd = [m_data getDistrictData:districtStr andWaitForDownload:NO];
		}
		
		[cell setPlaceData:psd];
		tcell = (UITableViewCell *)cell;
	}
	
	return tcell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// XXX - do something !
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
}


@end

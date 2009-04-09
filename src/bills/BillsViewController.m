//
//  BillsViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"
#import "BillsViewController.h"
#import "BillContainer.h"
#import "BillsDataManager.h"
#import "BillSummaryTableCell.h"
#import "MiniBrowserController.h"
#import "ProgressOverlayViewController.h"


@interface BillsViewController (private)
	- (void)dataManagerCallback:(id)sender;
	- (void)congressSwitch: (id)sender;
	- (void) deselectRow:(id)sender;
@end



@implementation BillsViewController

enum
{
	eTAG_ACTIVITY = 999,
};


- (void)dealloc 
{
	[m_data release];
	[super dealloc];
}


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)viewDidLoad 
{
	m_data = [[myGovAppDelegate sharedBillsData] retain];
	
	m_HUD = [[ProgressOverlayViewController alloc] initWithWindow:self.tableView];
	m_HUDTxt = [[[NSString alloc] initWithString:@"Waiting for data..."] autorelease];
	[m_HUD show:NO];
	[m_HUD setText:m_HUDTxt andIndicateProgress:YES];
	
	// create a search bar which will be used as our table's header view
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 50.0f)];
	searchBar.delegate = self;
	searchBar.prompt = @"";
	searchBar.placeholder = @"Search for a bill...";
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	searchBar.barStyle = UIBarStyleBlackOpaque;
	searchBar.showsCancelButton = YES;
	
	self.tableView.tableHeaderView = searchBar;
	self.tableView.tableHeaderView.userInteractionEnabled = YES;
	
	// Create a new segment control and place it in 
	// the NavigationController's title area
	NSArray *buttonNames = [NSArray arrayWithObjects:@"House", @"Senate", nil];
	m_segmentCtrl = [[UISegmentedControl alloc] initWithItems:buttonNames];
	
	// default styles
	m_segmentCtrl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	m_segmentCtrl.segmentedControlStyle = UISegmentedControlStyleBar;
	m_segmentCtrl.selectedSegmentIndex = 0; // Default to the "House"
	m_selectedChamber = eCongressChamberHouse;
	m_segmentCtrl.frame = CGRectMake(0,0,200,30);
	// saturation of 0.0 means black/white
	m_segmentCtrl.tintColor = [UIColor darkGrayColor];
	
	// add ourself as the target
	[m_segmentCtrl addTarget:self action:@selector(congressSwitch:) forControlEvents:UIControlEventValueChanged];
	
	// add the buttons to the navigation bar
	self.navigationItem.titleView = m_segmentCtrl;
	[m_segmentCtrl release];
	
	
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated 
{
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
	
	[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
	
	if ( ![m_data isDataAvailable] )
	{
		self.tableView.userInteractionEnabled = NO;
	}
	else
	{
		self.tableView.userInteractionEnabled = YES;
	}
	
	[super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated
{
	if ( ![m_data isDataAvailable] )
	{
		if ( ![m_data isBusy] )
		{
			[m_data beginBillSummaryDownload];
		}
		[m_HUD show:YES];
	}
	else
	{
		[m_HUD show:NO];
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


#pragma mark BillsViewController Private


- (void)dataManagerCallback:(id)sender
{
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
		[m_HUD setText:m_HUDTxt andIndicateProgress:YES];
	}
}


- (void)congressSwitch: (id)sender
{
	switch ( [sender selectedSegmentIndex] )
	{
		default:
		case 0:
			// This is the House!
			m_selectedChamber = eCongressChamberHouse;
			break;
			
		case 1:
			// This is the Senate!
			m_selectedChamber = eCongressChamberSenate;
			break;
	}
	if ( [m_data isDataAvailable] ) 
	{
		[self.tableView reloadData];
		NSUInteger idx[2] = {0,0};
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
		self.tableView.userInteractionEnabled = YES;
	}
}


- (void) deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same row)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


#pragma mark UISearchBarDelegate methods


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
	
	// XXX - fill this in!!!
	
	[self.tableView reloadData];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	
	// XXX - fill this in!!!
	
	[self.tableView reloadData];
}


#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if ( ![m_data isDataAvailable] ) return 1;
	
	switch ( m_selectedChamber )
	{
		default:
		case eCongressChamberHouse:
			return [m_data houseBillSections];
			
		case eCongressChamberSenate:
			return [m_data senateBillSections];
	}
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if ( ![m_data isDataAvailable] ) return 0;

	switch ( m_selectedChamber )
	{
		default:
		case eCongressChamberHouse:
			return [m_data houseBillsInSection:section];
			
		case eCongressChamberSenate:
			return [m_data senateBillsInSection:section];
	}
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( ![m_data isDataAvailable] ) return 20.0f;
	
	BillContainer *bc = nil;
	switch ( m_selectedChamber )
	{
		default:
		case eCongressChamberHouse:
			bc = [m_data houseBillAtIndexPath:indexPath];
			break;
		case eCongressChamberSenate:
			bc = [m_data senateBillAtIndexPath:indexPath];
			break;
	}
	return [BillSummaryTableCell getCellHeightForBill:bc];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ( ![m_data isDataAvailable] ) return nil;
	
	switch ( m_selectedChamber )
	{
		default:
		case eCongressChamberHouse:
			return [m_data houseSectionTitle:section];
		case eCongressChamberSenate:
			return [m_data senateSectionTitle:section];
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	static NSString *CellIdentifier = @"BillCell";
    
	BillSummaryTableCell *cell = (BillSummaryTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if ( nil == cell )
	{
		cell = [[[BillSummaryTableCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
	
	BillContainer *bc = nil;
	if ( [m_data isDataAvailable] ) 
	{
		switch ( m_selectedChamber )
		{
			default:
			case eCongressChamberHouse:
				bc = [m_data houseBillAtIndexPath:indexPath];
				break;
			case eCongressChamberSenate:
				bc = [m_data senateBillAtIndexPath:indexPath];
				break;
		}
	}
	[cell setContentFromBill:bc];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	BillContainer *bill = nil;
	if ( [m_data isDataAvailable] ) 
	{
		switch ( m_selectedChamber )
		{
			default:
			case eCongressChamberHouse:
				bill = [m_data houseBillAtIndexPath:indexPath];
				break;
			case eCongressChamberSenate:
				bill = [m_data senateBillAtIndexPath:indexPath];
				break;
		}
	}
	
	if ( nil != bill )
	{
		// get the URL for the full-text of the bill and load-up 
		// our mini web browser to view it!
		MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:[bill getFullTextURL]];
		mbc.title = @"loading...";
		[self.navigationController pushViewController:mbc animated:YES];
	}
	
	//[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
}


@end


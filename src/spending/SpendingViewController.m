//
//  SpendingViewController.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import "myGovAppDelegate.h"

#import "ComposeMessageViewController.h"
#import "CongressDataManager.h"
#import "ContractorSpendingData.h"
#import "ContractorSpendingTableCell.h"
#import "LegislatorContainer.h"
#import "PlaceSpendingData.h"
#import "PlaceSpendingTableCell.h"
#import "ProgressOverlayViewController.h"
#import "SpendingDataManager.h"
#import "SpendingSummaryViewController.h"
#import "SpendingViewController.h"
#import "StateAbbreviations.h"


@interface SpendingViewController (private)
	- (PlaceSpendingData *)getDataForIndexPath:(NSIndexPath *)indexPath;
	- (void)dataManagerCallback:(id)msg;
	- (void)queryMethodSwitch:(id)sender;
	- (void)sortSpendingData;
	- (void)findLocalSpenders:(id)sender;
	- (void)deselectRow:(id)sender;
	- (void)showPlaceDetail:(id)sender;
	- (void)showContractorDetail:(id)sender;
@end

@implementation SpendingViewController

typedef enum
{
	eAST_ContractorSort   = 0,
	eAST_PlaceAction      = 1,
	eAST_ContractorAction = 2,
} ActionSheetType;


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
	
	self.tableView.rowHeight = 50.0f;
	
	m_sortOrder = eSpendingSortDollars;
	m_actionSheetType = eAST_ContractorSort;
	
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
	// Add a "location" button which will be used to find senators/representatives
	// which represent a users current district
	// 
	/*
	UIImage *locImg = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"location_overlay.png"]];
	UIBarButtonItem *locBarButton = [[[UIBarButtonItem alloc] 
									  initWithImage:locImg 
									  style:UIBarButtonItemStylePlain 
									  target:self 
									  action:@selector(findLocalSpenders:)] autorelease];
	self.navigationItem.leftBarButtonItem = locBarButton;
	self.navigationItem.leftBarButtonItem.width = self.navigationItem.rightBarButtonItem.width;
	*/
	
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated 
{
	[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
	
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
		[m_HUD setText:[m_HUD currentText] andIndicateProgress:YES];
		self.tableView.userInteractionEnabled = NO;
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


- (NSString *)areaName
{
	return @"spending";
}


- (void)handleURLParms:(NSString *)parms
{
	// XXX - do something to handle URL parameters!
}


#pragma mark SpendingViewController Private 


- (PlaceSpendingData *)getDataForIndexPath:(NSIndexPath *)indexPath
{
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
	return psd;
}


- (void)dataManagerCallback:(id)msg
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
	BOOL showOrganizerButton = NO;
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
			showOrganizerButton = YES;
			break;
	}
	
	if ( showOrganizerButton )
	{
		// 
		// Add an "organize button which will present the user with a method of
		// sorting the displayed data
		// 
		self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] 
												   initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize 
												   target:self 
												   action:@selector(sortSpendingData)] autorelease];
	}
	else
	{
		self.navigationItem.leftBarButtonItem = nil;
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
	if ( m_selectedQueryMethod != eSQMContractor )
	{
		// XXX - sorting not supported on other query types
		return;
	}
	
	NSMutableString *sortByName = [[NSMutableString alloc] initWithString:@"Sort By Name"];
	NSMutableString *sortByDollars = [[NSMutableString alloc] initWithString:@"Sort By Dollars"];
	
	switch ( m_sortOrder )
	{
		default:
		case eSpendingSortDollars:
			[sortByDollars appendString:@" (*)"];
			break;
		case eSpendingSortContractor:
			[sortByName appendString:@" (*)"];
			break;
	}
	
	UIActionSheet *sortAlert =
	[[UIActionSheet alloc] initWithTitle:@"Sort Spending Data"
						   delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
						   otherButtonTitles:sortByDollars,sortByName,nil,nil,nil];
	
	// use the same style as the nav bar
	sortAlert.actionSheetStyle = self.navigationController.navigationBar.barStyle;
	
	m_actionSheetType = eAST_ContractorSort;
	[sortAlert showInView:self.view];
	[sortAlert release];
}


- (void)findLocalSpenders:(id)sender
{
}


- (void)deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same row)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


- (void)showPlaceDetail:(id)sender
{
	UIButton *button = (UIButton *)sender;
	if ( nil == button ) return;
	
	PlaceSpendingTableCell *tcell = (PlaceSpendingTableCell *)[button superview];
	if ( nil == tcell ) return;
	
	PlaceSpendingData *psd = [tcell m_data];
	SpendingSummaryViewController *summaryViewCtrl = [[SpendingSummaryViewController alloc] init];
	[summaryViewCtrl setPlaceData:psd];
	[self.navigationController pushViewController:summaryViewCtrl animated:YES];
	[summaryViewCtrl release];
}


- (void)showContractorDetail:(id)sender
{
	UIButton *button = (UIButton *)sender;
	if ( nil == button ) return;
	
	ContractorSpendingTableCell *tcell = (ContractorSpendingTableCell *)[button superview];
	if ( nil == tcell ) return;
	
	ContractorInfo *ci = [tcell m_contractor];
	
	SpendingSummaryViewController *summaryViewCtrl = [[SpendingSummaryViewController alloc] init];
	[summaryViewCtrl setContractorData:ci];
	[self.navigationController pushViewController:summaryViewCtrl animated:YES];
	[summaryViewCtrl release];
}


#pragma mark UIActionSheetDelegate methods


// action sheet callback: choose a sort method for spending data!
- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch ( m_actionSheetType )
	{
		case eAST_ContractorSort:
		{
			switch ( buttonIndex )
			{
				// sort by dollars
				case 0:
					m_sortOrder = eSpendingSortDollars;
					break;
				// sort by name
				case 1:
					m_sortOrder = eSpendingSortContractor;
					break;
				case 2:
					// XXX
				default:
					break;
			}
			// reload table data
			if ( [m_data isDataAvailable] )
			{
				[self.tableView reloadData];
				NSUInteger idx[2] = {0,0};
				[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
			}
		}
			break;
		case eAST_PlaceAction:
		{
			BOOL shouldComment = NO;
			PlaceSpendingData *psd = [self getDataForIndexPath:[self.tableView indexPathForSelectedRow]];
			NSArray *plArray = [psd placeLegislators:YES];
			NSString *legName = [psd m_place];
			NSURL *appUrl = [NSURL URLWithString:[NSString stringWithFormat:@"mygov://spending/%@",[psd m_place]]];
			switch ( buttonIndex )
			{
				case 0:
					if ( [plArray count] < 1 ) shouldComment = YES;
					else
					{
						LegislatorContainer *lc = [plArray objectAtIndex:0];
						legName = [lc shortName];
						NSString *urlStr = [NSString stringWithFormat:@"mygov://congress/%@",[lc bioguide_id]];
						appUrl = [NSURL URLWithString:urlStr];
					}
					break;
				case 1:
					if ( [plArray count] < 2 ) shouldComment = YES;
					else
					{
						LegislatorContainer *lc = [plArray objectAtIndex:1];
						legName = [lc shortName];
						NSString *urlStr = [NSString stringWithFormat:@"mygov://congress/%@",[lc bioguide_id]];
						appUrl = [NSURL URLWithString:urlStr];
					}
					break;
				case 2:
					if ( [plArray count] < 3 ) shouldComment = YES;
					else
					{
						LegislatorContainer *lc = [plArray objectAtIndex:2];
						legName = [lc shortName];
						NSString *urlStr = [NSString stringWithFormat:@"mygov://congress/%@",[lc bioguide_id]];
						appUrl = [NSURL URLWithString:urlStr];
					}
					break;
				case 3:
					shouldComment = YES;
					appUrl = [NSURL URLWithString:[NSString stringWithFormat:@"mygov://spending/place/%@",[psd m_place]]];
					break;
				default:
					break;
			}
			
			if ( shouldComment )
			{
				MessageData *msg = [[MessageData alloc] init];
				msg.m_transport = eMT_MyGov;
				msg.m_to = @"MyGovernment Community";
				msg.m_subject = [NSString stringWithFormat:@"Spending: %@",legName];
				msg.m_appURL = appUrl;
				msg.m_appURLTitle = legName;
				msg.m_webURL = [psd getTransactionListURL];
				msg.m_webURLTitle = @"USASpending.gov";  
				ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
				[cmvc display:msg fromParent:self];
				[msg release];
			}
			else if ( nil != appUrl )
			{
				[[UIApplication sharedApplication] openURL:appUrl];
			}
		}
			break;
		case eAST_ContractorAction:
		{
			BOOL shouldComment = NO;
			switch ( buttonIndex )
			{
				case 0:
					shouldComment = YES;
					break;
				default:
					break;
			}
			if ( shouldComment )
			{
				ContractorInfo *ci = [m_data contractorData:[self.tableView indexPathForSelectedRow].row whenSortedBy:m_sortOrder];
				
				// only 1 action here - comment!
				// 
				MessageData *msg = [[MessageData alloc] init];
				msg.m_transport = eMT_MyGov;
				msg.m_to = @"MyGovernment Community";
				msg.m_subject = [NSString stringWithFormat:@"Spending: %@",ci.m_parentCompany];
				msg.m_appURL = [NSURL URLWithString:[NSString stringWithFormat:@"mygov://spending/contractor/%0d",ci.m_parentDUNS]];
				msg.m_appURLTitle = ci.m_parentCompany;
				ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
				[cmvc display:msg fromParent:self];
				[msg release];
			}
		}
			break;
	}
	
	// deselect the row
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
}


#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if ( m_selectedQueryMethod == eSQMContractor )
	{
		return 1; // XXX - get number of categories from SpendingDataManager?
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
			//return [NSArray arrayWithObjects:s_alphabet count:26];
			return nil; 
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
			//if ( section < 26 ) return s_alphabet[section];
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
			{
				NSInteger cnt = [[m_data topContractorsSortedBy:m_sortOrder] count];
				return (cnt > 0 ? cnt : 1); // get number from SpendingDataManager
			}
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
		ContractorSpendingTableCell *cell = (ContractorSpendingTableCell *)[tableView dequeueReusableCellWithIdentifier:CtorCellIdendifier];
		if ( cell == nil )
		{
			cell = [[[ContractorSpendingTableCell alloc] initWithFrame:CGRectZero reuseIdentifier:CtorCellIdendifier detailTarget:self detailSelector:@selector(showContractorDetail:)] autorelease];
		}
		
		ContractorInfo *ctrInfo = [m_data contractorData:indexPath.row whenSortedBy:m_sortOrder];
		[cell setContractor:ctrInfo];
		tcell = (UITableViewCell *)cell;
	}
	else
	{
		PlaceSpendingTableCell *cell = (PlaceSpendingTableCell *)[tableView dequeueReusableCellWithIdentifier:PlaceCellIdentifier];
		if ( cell == nil ) 
		{
			cell = [[[PlaceSpendingTableCell alloc] initWithFrame:CGRectZero reuseIdentifier:PlaceCellIdentifier detailTarget:self detailSelector:@selector(showPlaceDetail:)] autorelease];
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
	switch ( m_selectedQueryMethod )
	{
		case eSQMDistrict:
		case eSQMState:
		{
			PlaceSpendingData *psd = [self getDataForIndexPath:indexPath];
			NSString *buttonName[4] = { nil, nil, nil, nil };
			{
				NSArray *plArray = [psd placeLegislators:YES];
				NSEnumerator *plEnum = [plArray objectEnumerator];
				id legislator;
				int ii = 0;
				while ( legislator = [plEnum nextObject] )
				{
					buttonName[ii++] = [legislator shortName];
				}
				buttonName[ii++] = @"Comment!";
			}
			// pop up an alert asking the user what action to perform
			UIActionSheet *contactAlert =
			[[UIActionSheet alloc] initWithTitle:psd.m_place
										delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
							   otherButtonTitles:buttonName[0],buttonName[1],buttonName[2],buttonName[3],nil];
			
			// use the same style as the nav bar
			contactAlert.actionSheetStyle = self.navigationController.navigationBar.barStyle;
			
			m_actionSheetType = eAST_PlaceAction;
			[contactAlert showInView:self.view];
			[contactAlert release];
		}
			break;
		case eSQMContractor:
		{
			ContractorInfo *ci = [m_data contractorData:indexPath.row whenSortedBy:m_sortOrder];
			
			// pop up an alert asking the user what action to perform
			UIActionSheet *contactAlert =
			[[UIActionSheet alloc] initWithTitle:ci.m_parentCompany
										delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
							   otherButtonTitles:@"Comment!",nil,nil,nil,nil];
			
			// use the same style as the nav bar
			contactAlert.actionSheetStyle = self.navigationController.navigationBar.barStyle;
			
			m_actionSheetType = eAST_ContractorAction;
			[contactAlert showInView:self.view];
			[contactAlert release];
		}
			break;
		default:
			[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
			break;
	}
}


@end

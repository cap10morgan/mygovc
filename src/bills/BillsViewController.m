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
#import "BillInfoViewController.h"
#import "BillSummaryTableCell.h"
#import "ComposeMessageViewController.h"
#import "LegislatorContainer.h"
#import "MiniBrowserController.h"
#import "ProgressOverlayViewController.h"


@interface BillsViewController (private)
	- (BillContainer *)billAtIndexPath:(NSIndexPath *)indexPath;
	- (void)reloadBillData;
	- (void)dataManagerCallback:(id)sender;
	- (void)shadowDataCallback:(id)sender;
	- (void)congressSwitch: (id)sender;
	- (void)deselectRow:(id)sender;
	- (void)setRefreshButtonInNavBar;
	- (void)setActivityViewInNavBar;
	- (void)searchForBills:(id)searchBar;
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
	[m_HUD show:NO];
	if ( ![m_data isDataAvailable] )
	{
		if ( ![m_data isBusy] )
		{
			[m_HUD setText:@"Waiting for data..." andIndicateProgress:YES];
		}
		else
		{
			[m_HUD setText:[m_data currentStatusMessage] andIndicateProgress:YES];
		}
	}
	
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
	
	// 
	// Add a "refresh" button which will wipe out the on-device cache and 
	// re-download congressional bill data 
	// 
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
											   initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
											   target:self 
											   action:@selector(reloadBillData)];
	
	
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
	
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
}


- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if ( ![m_data isDataAvailable] )
	{
		if ( ![m_data isBusy] )
		{
			[m_data loadData];
		}
		[m_HUD show:YES];
		[m_HUD setText:[m_data currentStatusMessage] andIndicateProgress:YES];
	}
	else
	{
		[m_HUD show:NO];
	}
	
	[self.tableView setNeedsDisplay];
	
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


- (void)showBillDetail:(id)sender
{
	UIButton *button = (UIButton *)sender;
	if ( nil == button ) return;
	
	BillSummaryTableCell *tcell = (BillSummaryTableCell *)[button superview];
	if ( nil == tcell ) return;
	
	BillInfoViewController *biView = [[BillInfoViewController alloc] init];
	[biView setBill:[tcell m_bill]];
	[self.navigationController pushViewController:biView animated:YES];
	[biView release];
}


- (NSString *)areaName
{
	return @"bills";
}


- (NSString *)getURLStateParms
{
	NSMutableString *state = [[NSMutableString alloc] init];
	
	// current selected chamber
	switch ( m_selectedChamber )
	{
		default:
		case eCongressChamberHouse:
			[state appendString:@"house"];
			break;
		case eCongressChamberSenate:
			[state appendString:@"senate"];
			break;
		case eCongressSearchResults:
			[state appendString:@"search"];
			[state appendString:[NSString stringWithFormat:@":%@",[m_data currentSearchString]]];
			break;
		case eCongressCommittee:
			[state appendString:@"committee"];
			break;
	}
	
	// current selected table row ?!
	{
		NSArray *cells = [self.tableView visibleCells];
		if ( [cells count] > 0 )
		{
			id cell = [cells objectAtIndex:0];
			if ( [cell respondsToSelector:@selector(m_tableRange)] )
			{
				NSRange range = (NSRange)[cell m_tableRange];
				[state appendFormat:@":%d:%d",range.location,range.length];
			}
			else
			{
				[state appendString:@":0:0"];
			}
		}
		else
		{
			[state appendString:@":0:0"];
		}
	}
	
	// Are we looking at a legislator?
	id topView = self.navigationController.visibleViewController;
	if ( [topView respondsToSelector:@selector(m_bill)] )
	{
		// grab the legislator currently being viewed
		BillContainer *bill = [topView performSelector:@selector(m_bill)];
		[state appendFormat:@":%d",[bill m_number]];
	}
	
	return state;
}


- (void)handleURLParms:(NSString *)parms
{
	// XXX - do something to handle URL parameters!
}


#pragma mark BillsViewController Private


- (BillContainer *)billAtIndexPath:(NSIndexPath *)indexPath
{
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
			case eCongressSearchResults:
				bc = [m_data searchResultAtIndexPath:indexPath];
		}
	}
	return bc;
}


- (void)reloadBillData
{
	[m_shadowData release];
	
	// we want this to happen in the background, 
	// so here's what we'll do:
	// 
	// Make a completely new copy of our bill data object, and tell it 
	// to download the data. When it's done, we'll release the old data
	// object, replace it with the new one and reload our table data!
	// 
	
	// set an activity button in the navbar to indicate progress
	// (and also prevent this from happening again until we're ready)
	[self setActivityViewInNavBar];
	
	// allocate a new data manager
	m_shadowData = [[BillsDataManager alloc] init];
	
	// hook it up to our shadow callback
	[m_shadowData setNotifyTarget:self withSelector:@selector(shadowDataCallback:)];
	
	// start downloading and let the callback handle the data-swap-and-reload
	[m_shadowData loadDataByDownload];
}


- (void)dataManagerCallback:(id)msg
{
	if ( [m_data isDataAvailable] )
	{
		self.tableView.userInteractionEnabled = YES;
		[m_HUD show:NO];
		
		[self.tableView reloadData];
	}
	else
	{
		// something interesting must have happened,
		// update the user with some progress
		self.tableView.userInteractionEnabled = NO;
		[m_HUD show:YES];
		[m_HUD setText:msg andIndicateProgress:YES];
	}
}


- (void)shadowDataCallback:(id)sender
{
	if ( nil == m_shadowData ) return; // how did that happen?
	
	if ( [m_shadowData isDataAvailable] )
	{
		// 
		// the download is complete, and we're ready for a switch:
		// we have to be a bit careful about this:
		// 
		
		// no user input messing us up...
		self.tableView.userInteractionEnabled = NO;
		
		// replace the global data instance
		[myGovAppDelegate replaceSharedBillsData:m_shadowData];
		[m_shadowData release]; m_shadowData = nil;
		
		// replace our copy of the data
		[m_data release];
		m_data = [[myGovAppDelegate sharedBillsData] retain];
		[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
		
		// set the reload button back to a button
		[self setRefreshButtonInNavBar];
		
		// reload the table data and re-enable user interaction
		[self.tableView reloadData];
		self.tableView.userInteractionEnabled = YES;
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


- (void)setRefreshButtonInNavBar
{
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
													  initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
													  target:self 
													  action:@selector(reloadBillData)];
}


- (void)setActivityViewInNavBar
{
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 32.0f)];
	UIActivityIndicatorView *aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	//aiView.hidesWhenStopped = YES;
	[aiView setFrame:CGRectMake(12.0f, 6.0f, 20.0f, 20.0f)];
	[view addSubview:aiView];
	[aiView startAnimating];
	
	UIBarButtonItem *actBarButton = [[UIBarButtonItem alloc] 
									 initWithBarButtonSystemItem:UIBarButtonSystemItemStop
									 target:nil action:nil];
	actBarButton.customView = view;
	actBarButton.style = UIBarButtonItemStyleBordered;
	actBarButton.target = nil;
	self.navigationItem.rightBarButtonItem = actBarButton;
	
	[self.navigationController.navigationBar setNeedsDisplay];
	
	[view release];
	[aiView release];
	[actBarButton release];
}


- (void)searchForBills:(id)searchBar
{
	NSString *srchTxt = ((UISearchBar *)searchBar).text;
	if ( [srchTxt length] > 0 )
	{
		// the blocking call which does all the searching!
		[m_data searchForBillsLike:srchTxt];
		
		[m_HUD show:NO];
		[self.tableView setUserInteractionEnabled:YES];
		
		if ( [m_data numSearchResults] > 0 )
		{
			m_selectedChamber = eCongressSearchResults;
		}
		else
		{
			// Search results!
			UIAlertView *alert = [[UIAlertView alloc] 
										  initWithTitle:@"Not Found"
										  message:[NSString stringWithString:@"Sorry, no bills were found which matched your search string. Did you spell it right?"]
										  delegate:self
										  cancelButtonTitle:nil
										  otherButtonTitles:@"OK",nil];
			[alert show];
		}
		
		[self.tableView reloadData];
	}
}


#pragma mark UISearchBarDelegate methods


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
	
	NSString *srchTxt = searchBar.text;
	if ( [srchTxt length] > 0 )
	{
		[m_HUD setText:@"Searching Bills..." andIndicateProgress:YES];
		[m_HUD show:YES];
		[self.tableView setUserInteractionEnabled:NO];
		
		// kick off the search in a thread
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
															selector:@selector(searchForBills:) object:searchBar];
		
		// Add the operation to the internal operation queue managed by the application delegate.
		[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
		
		[theOp release];
		
		[self.tableView setNeedsDisplay];
	}
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	
	if ( eCongressSearchResults ==  m_selectedChamber )
	{
		// switch back (resets scroll position)
		[self congressSwitch:m_segmentCtrl];
	}
	else
	{
		[self.tableView reloadData];
	}
}


#pragma mark UIActionSheetDelegate methods


// action sheet callback: maybe start a re-download on congress data
- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	BillContainer *bill = [self billAtIndexPath:[self.tableView indexPathForSelectedRow]];
	if ( nil == bill )
	{
		goto deselect_and_return;
	}
	
	// use currently selected legislator to perfom the following action:
	switch ( buttonIndex )
	{
		// Sponsor Info
		case 0:
		{
			// put together an in-app URL and open it!
			NSString *urlStr = [NSString stringWithFormat:@"mygov://congress/%@",
											[[bill sponsor] bioguide_id]
								];
			NSURL *url = [NSURL URLWithString:urlStr];
			[[UIApplication sharedApplication] openURL:url];
		}
			break;
			
		// Full Bill Text
		case 1:
		{
			 // get the URL for the full-text of the bill and load-up 
			 // our mini web browser to view it!
			 MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:[bill getFullTextURL]];
			 [mbc display:self];
		}
			break;
			
		// Comment!
		case 2:
		{
			MessageData *msg = [[MessageData alloc] init];
			msg.m_transport = eMT_MyGov;
			msg.m_to = @"MyGovernment Community";
			msg.m_subject = [NSString stringWithFormat:@"Comment on %@",[bill m_title]];
			msg.m_body = @" ";
			// display the message composer
			ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
			[cmvc display:msg fromParent:self];
		}
			break;
			
		default:
			break;
	}
	
	// deselect the selected row 
deselect_and_return:
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
}


#pragma mark UIAlertViewDelegate Methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// Do something here?!
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
		
		case eCongressSearchResults:
			return 1;
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
			
		case eCongressSearchResults:
			return [m_data numSearchResults];
	}
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( ![m_data isDataAvailable] ) return 20.0f;
	
	BillContainer *bc = [self billAtIndexPath:indexPath];
	
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
		case eCongressSearchResults:
			return @"Search Results";
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
		[cell setDetailTarget:self andSelector:@selector(showBillDetail:)];
	}
	
	BillContainer *bc = [self billAtIndexPath:indexPath];
	[cell setContentFromBill:bc];
	
	// let the cell know where it currently is...
	cell.m_tableRange = (NSRange){indexPath.section, indexPath.row};
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	BillContainer *bill = [self billAtIndexPath:indexPath];
	
	// pop up an alert asking the user what action to perform
	UIActionSheet *contactAlert =
	[[UIActionSheet alloc] initWithTitle:[bill m_title]
								delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
					   otherButtonTitles:@"Sponsor Info",@"Full Bill Text",@"Comment!",nil,nil];
	
	// use the same style as the nav bar
	contactAlert.actionSheetStyle = self.navigationController.navigationBar.barStyle;
	
	[contactAlert showInView:self.view];
	[contactAlert release];
}


@end


/*
 File: BillsViewController.m
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
	- (BOOL)scrollToInitialPosition;
	- (void)showInitialBill:(BillContainer *)bill;
	- (void)reloadBillData;
	- (void)dataManagerCallback:(id)sender;
	- (void)shadowDataCallback:(id)sender;
	- (void)congressSwitch: (id)sender;
	- (void)deselectRow:(id)sender;
	- (void)setRefreshButtonInNavBar;
	- (void)setActivityViewInNavBar;
	- (void)searchForBills:(id)searchBar;
@end


enum
{
	eAlertType_General = 0,
	eAlertType_ReloadQuestion = 1,
};



@implementation BillsViewController

enum
{
	eTAG_ACTIVITY = 999,
};


- (void)dealloc 
{
	[m_data release];
	[m_HUD release];
	
	[m_initialSearchString release];
	[m_initialIndexPath release];
	[m_initialBillID release];
	[super dealloc];
}


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	m_data = [[myGovAppDelegate sharedBillsData] retain];
	
	m_initialSearchString = nil;
	m_initialIndexPath = nil;
	m_initialBillID = nil;
	m_alertViewFunction = eAlertType_General;
	m_outOfScope = NO;
	
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
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
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
	
}


- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
	[self.tableView setNeedsDisplay];
}


- (void)viewDidAppear:(BOOL)animated
{
	if ( ![myGovAppDelegate networkIsAvailable:NO]  )
	{
		[m_HUD show:NO];
		[m_data setNotifyTarget:nil withSelector:nil];
		return;
	}
	else
	{
		[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
	}
	
	[super viewDidAppear:animated];
	
	if ( ![m_data isDataAvailable] )
	{
		if ( ![m_data isBusy] )
		{
			[m_data loadData];
		}
		[m_HUD show:YES];
		[m_HUD setText:[m_data currentStatusMessage] andIndicateProgress:YES];
		return;
	}
	else
	{
		[m_HUD show:NO];
	}
	
	BOOL isReloading = NO;
	if ( nil != m_initialIndexPath || nil != m_initialSearchString )
	{
		isReloading = [self scrollToInitialPosition];
	}
	
	if ( nil != m_initialBillID )
	{
		//[self scrollToInitialPosition];
		
		BillContainer *bill = [m_data billWithIdentifier:m_initialBillID];
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																			selector:@selector(showInitialBill:) object:bill];
		// Add the operation to the internal operation queue managed by the application delegate.
		[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
		[theOp release];
	}
	
	if ( m_outOfScope )
	{
		m_outOfScope = NO;
		if ( !isReloading ) [self.tableView reloadData];
	}
}


- (void)viewWillDisappear:(BOOL)animated 
{
	m_outOfScope = YES;
	[super viewWillDisappear:animated];
}

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
	
	// Are we looking at a particular bill?
	id topView = self.navigationController.visibleViewController;
	if ( [topView respondsToSelector:@selector(m_bill)] )
	{
		// grab the legislator currently being viewed
		BillContainer *bill = [topView performSelector:@selector(m_bill)];
		[state appendFormat:@"%@/%d",[BillContainer stringFromBillType:[bill m_type]], [bill m_number]];
	}
	
	
	// current selected chamber
	switch ( m_selectedChamber )
	{
		default:
		case eCongressChamberHouse:
			[state appendString:@":house"];
			break;
		case eCongressChamberSenate:
			[state appendString:@":senate"];
			break;
		case eCongressSearchResults:
			[state appendString:@":search"];
			[state appendString:[NSString stringWithFormat:@":%@",[m_data currentSearchString]]];
			break;
		case eCongressCommittee:
			[state appendString:@":committee"];
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
	
	return state;
}


- (void)handleURLParms:(NSString *)parms
{
	// 
	// Handle Bill URLs
	// 
	
	NSInteger parmIdx = 0;
	NSString *chamber = nil;
	NSArray *pArray = [parms componentsSeparatedByString:@":"];
	if ( parmIdx >= [pArray count] ) return;
	
	NSString *billStr = [pArray objectAtIndex:parmIdx];
	
	if ( ++parmIdx >= [pArray count] ) goto get_out;
	
	// Congressional Chamber selected
	chamber = [pArray objectAtIndex:parmIdx];
	if ( [chamber isEqualToString:@"senate"] )
	{
		m_selectedChamber = eCongressChamberSenate;
		m_segmentCtrl.selectedSegmentIndex = 1;
	}
	else if ( [chamber isEqualToString:@"house"] )
	{
		m_selectedChamber = eCongressChamberHouse;
		m_segmentCtrl.selectedSegmentIndex = 0;
	}
	else if ( [chamber isEqualToString:@"committee"] )
	{
		// XXX - unsupported!
	}
	else if ( [chamber isEqualToString:@"search"] )
	{
		m_selectedChamber = eCongressSearchResults;
		[m_initialSearchString release]; m_initialSearchString = nil;
		if ( ++parmIdx < [pArray count] ) m_initialSearchString = [[NSString alloc] initWithString:[[pArray objectAtIndex:parmIdx] stringByReplacingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]];
	}
	
	// Current index in the table
	if ( ++parmIdx < [pArray count] )
	{
		NSInteger section = 0;
		NSInteger row = 0;
		section = [[pArray objectAtIndex:parmIdx] integerValue];
		if ( ++parmIdx < [pArray count] ) row = [[pArray objectAtIndex:parmIdx] integerValue];
		
		[m_initialIndexPath release];
		NSUInteger idx[2] = {section,row};
		m_initialIndexPath = [[NSIndexPath alloc] initWithIndexes:idx length:2];
	}
	
get_out:
	if ( nil != billStr && ([billStr length] > 0) )
	{
		m_initialBillID = [[NSString alloc] initWithString:[billStr stringByReplacingOccurrencesOfString:@"/" withString:@" "]
						  ];
	}
	
	if ( [m_data isDataAvailable] )
	{
		if ( nil != m_initialIndexPath || nil != m_initialSearchString )
		{
			[self scrollToInitialPosition];
		}
		
		if ( nil != m_initialBillID )
		{
			BillContainer *bill = [m_data billWithIdentifier:m_initialBillID];
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																				selector:@selector(showInitialBill:) object:bill];
			// Add the operation to the internal operation queue managed by the application delegate.
			[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
			[theOp release];
		}
	}
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


- (BOOL)scrollToInitialPosition
{
	BOOL isReloading = NO;
	
	if ( nil != m_initialSearchString )
	{
		m_outOfScope = NO;
		
		UISearchBar *searchBar = (UISearchBar *)(self.tableView.tableHeaderView);
		[searchBar setText:m_initialSearchString];
		// this function does all the table data reloading for us :-)
		[self searchBar:searchBar textDidChange:m_initialSearchString];
		isReloading = YES;
	}
	
	if ( nil != m_initialIndexPath )
	{
		if ( !isReloading ) 
		{ 
			isReloading = YES; 
			m_outOfScope = NO; 
			[self.tableView reloadData]; 
		}
		// make sure the new index is within the bounds of our table
		if ( [self.tableView numberOfSections] > m_initialIndexPath.section &&
			[self.tableView numberOfRowsInSection:m_initialIndexPath.section] > m_initialIndexPath.row )
		{
			// scroll there!
			[self.tableView scrollToRowAtIndexPath:m_initialIndexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}
	}
	
	// clear all the state (no matter what)
	[m_initialSearchString release]; m_initialSearchString = nil;
	[m_initialIndexPath release]; m_initialIndexPath = nil;
	
	return isReloading;
}


- (void)showInitialBill:(BillContainer *)bill
{
	// we should be running in a thread, so this should give my table
	// enough time to load itself up before I go and cover it up.
	// (yeah, it's a bit of a hack...)
	//[NSThread sleepForTimeInterval:0.33f]; 
	while ( self.navigationController.visibleViewController != self && 
		    !self.tableView.userInteractionEnabled
		  )
	{
		[m_HUD show:YES];
		[m_HUD setText:[m_data currentStatusMessage] andIndicateProgress:YES];
		//[self.tableView setNeedsDisplay];
		
		[NSThread sleepForTimeInterval:0.2f];
	}
	[NSThread sleepForTimeInterval:0.35f];
	
	if ( nil != bill )
	{
		// only 1 bill at a time!
		[self.navigationController popToRootViewControllerAnimated:NO];
		
		BillInfoViewController *biView = [[BillInfoViewController alloc] init];
		[biView setBill:bill];
		[self.navigationController pushViewController:biView animated:YES];
		[biView release];
	}
	else
	{
		// search for bill (at OpenCongress.org!)
		UISearchBar *searchBar = (UISearchBar *)self.tableView.tableHeaderView;
		searchBar.text = m_initialBillID;
		
		[m_HUD setText:@"Searching Bills..." andIndicateProgress:YES];
		[m_HUD show:YES];
		[self.tableView setUserInteractionEnabled:NO];
		
		// kick off the search in a thread
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																			selector:@selector(searchForBills:) object:searchBar];
		
		// Add the operation to the internal operation queue managed by the application delegate.
		[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
		
		[theOp release];
	}
	
	[m_initialBillID release]; m_initialBillID = nil;
	[self.tableView setNeedsDisplay];
}


- (void)reloadBillData
{
	m_alertViewFunction = eAlertType_ReloadQuestion;
	UIAlertView *alert = [[UIAlertView alloc] 
						  initWithTitle:@"Reload Bill Data"
						  message:@"Remove cached bill data?\nAnswering NO will download more recent bill data."
						  delegate:self
						  cancelButtonTitle:@"No"
						  otherButtonTitles:@"Yes",nil];
	[alert show];
	
	// set an activity button in the navbar to indicate progress
	// (and also prevent this from happening again until we're ready)
	[self setActivityViewInNavBar];
	
}


- (void)dataManagerCallback:(id)msg
{
	if ( [m_data isDataAvailable] )
	{
		self.tableView.userInteractionEnabled = YES;
		[m_HUD show:NO];
		
		BOOL isReloading = NO;
		if ( nil != m_initialIndexPath || nil != m_initialSearchString )
		{
			isReloading = [self scrollToInitialPosition];
		}
		else
		{
			// scroll to the top of the table
			if ( [m_data totalBills] > 0 )
			{
				isReloading = YES;
				[self.tableView reloadData];
				NSUInteger idx[2] = {0,0};
				[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
			}
		}
		
		if ( nil != m_initialBillID )
		{
			BillContainer *bill = [m_data billWithIdentifier:m_initialBillID];
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																				selector:@selector(showInitialBill:) object:bill];
			// Add the operation to the internal operation queue managed by the application delegate.
			[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
			[theOp release];
		}
		
		if ( !isReloading ) [self.tableView reloadData];
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
		[self.tableView setUserInteractionEnabled:NO];
		
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
			m_alertViewFunction = eAlertType_General;
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
		[self.tableView setUserInteractionEnabled:NO];
		[m_HUD setText:@"Searching Bills..." andIndicateProgress:YES];
		[m_HUD show:YES];
		
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
			
		// Tweet This!
		case 2: 
		{
			MessageData *msg = [[MessageData alloc] init];
			msg.m_transport = eMT_SendTweet;
			//msg.m_subject = [NSString stringWithFormat:@"%@ %0d:", [BillContainer getBillTypeShortDescrip:bill.m_type], bill.m_number];
			msg.m_body = [NSString stringWithFormat:@"#mygov Check out %@ %0d: ",
														[BillContainer getBillTypeShortDescrip:bill.m_type],
														bill.m_number
						  ];
			NSString *shortDescrip = [bill summaryText];
			NSInteger hdrLen = [msg.m_body length];
			NSInteger maxLen = 140 - hdrLen;
			if ( [shortDescrip length] > maxLen ) shortDescrip = [shortDescrip substringToIndex:maxLen];
			
			msg.m_body = [msg.m_body stringByAppendingString:shortDescrip];
			
			// display the message composer
			ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
			[cmvc display:msg fromParent:self];
		}
			break;
			
		// Comment!
		case 3:
		{
			MessageData *msg = [[MessageData alloc] init];
			msg.m_transport = eMT_MyGov;
			msg.m_to = @"MyGovernment Community";
			msg.m_subject = [NSString stringWithFormat:@"%@ %0d:", [BillContainer getBillTypeShortDescrip:bill.m_type], bill.m_number];
			msg.m_body = @" ";
			msg.m_appURL = [NSURL URLWithString:[NSString stringWithFormat:@"mygov://bills/%@/%0d",
												               [BillContainer stringFromBillType:bill.m_type],
												               bill.m_number]
							];
			msg.m_appURLTitle = msg.m_subject;
			msg.m_webURL = [bill getFullTextURL];
			msg.m_webURLTitle = @"Full Bill Text";
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
	switch ( m_alertViewFunction )
	{
		default:
		case eAlertType_General:
			break;
			
		case eAlertType_ReloadQuestion:
			[m_shadowData release]; m_shadowData = nil;
			// we want this to happen in the background, 
			// so here's what we'll do:
			// 
			// Make a completely new copy of our bill data object, and tell it 
			// to download the data. When it's done, we'll release the old data
			// object, replace it with the new one and reload our table data!
			// 
			// allocate a new data manager
			m_shadowData = [[BillsDataManager alloc] init];
			// hook it up to our shadow callback
			[m_shadowData setNotifyTarget:self withSelector:@selector(shadowDataCallback:)];
			
			switch ( buttonIndex )
			{
				case 1: // YES: Please remove local cache
					// start downloading and let the callback handle the data-swap-and-reload
					[m_shadowData loadDataByDownload:YES];
					break;
					
				default:
				case 0: // NO: don't remove local cache
					[m_shadowData loadDataByDownload:NO];
					break;
			}
			break;
	}
	m_alertViewFunction = eAlertType_General;
}



#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if ( m_outOfScope || ![m_data isDataAvailable] ) return 1;
	
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
	if ( m_outOfScope || ![m_data isDataAvailable] ) return 0;

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
	if ( m_outOfScope || ![m_data isDataAvailable] ) return 20.0f;
	
	BillContainer *bc = [self billAtIndexPath:indexPath];
	
	return [BillSummaryTableCell getCellHeightForBill:bc];
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ( m_outOfScope || ![m_data isDataAvailable] ) return nil;
	
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
	
	// let the cell know where it currently is...
	cell.m_tableRange = (NSRange){indexPath.section, indexPath.row};
	
	if ( m_outOfScope ) return cell;
	
	BillContainer *bc = [self billAtIndexPath:indexPath];
	[cell setContentFromBill:bc];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	BillContainer *bill = [self billAtIndexPath:indexPath];
	
	// pop up an alert asking the user what action to perform
	UIActionSheet *contactAlert =
	[[UIActionSheet alloc] initWithTitle:[bill m_title]
								delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
					   otherButtonTitles:@"Sponsor Info",@"Full Bill Text",@"Tweet This",@"Comment!",nil,nil];
	
	// use the same style as the nav bar
	contactAlert.actionSheetStyle = self.navigationController.navigationBar.barStyle;
	
	//[contactAlert showInView:self.view];
	[contactAlert showFromTabBar:(UITabBar *)[myGovAppDelegate sharedAppDelegate].m_tabBarController.view];
	[contactAlert release];
}


@end


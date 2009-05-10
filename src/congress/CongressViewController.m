//
//  CongressViewController.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"

#import "ComposeMessageViewController.h"
#import "CongressDataManager.h"
#import "CongressViewController.h"
#import "LegislatorContainer.h"
#import "LegislatorNameCell.h"
#import "LegislatorViewController.h"
#import "MiniBrowserController.h"
#import "ProgressOverlayViewController.h"
#import "StateAbbreviations.h"


@interface CongressViewController (private)
	- (void)setLocationButtonInNavBar;
	- (void)setActivityViewInNavBar;
	- (void)congressSwitch: (id)sender;
	- (void)reloadCongressData;
	- (void)deselectRow:(id)sender;
	- (void)findLocalLegislators:(id)sender;
	- (void)scrollToInitialPosition;
	- (void)showInitialLegislator:(LegislatorContainer *)legislator;
	- (LegislatorContainer *)legislatorFromIndexPath:(NSIndexPath *)idx;
@end

enum
{
	eTAG_ACTIVITY = 999,
};

@implementation CongressViewController

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[m_data release];
	[m_locationManager release];
	[m_currentLocation release];
	[m_initialIndexPath release];
	[m_initialLegislatorID release];
	[m_initialSearchString release];
	[m_searchResultsTitle release];
    [super dealloc];
}


- (void)viewDidLoad
{
	self.title = @"Congress";
	
	self.tableView.autoresizesSubviews = YES;
	self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
	self.tableView.rowHeight = 50.0f;
	
	m_data = [[myGovAppDelegate sharedCongressData] retain];
	[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
	
	m_searchResultsTitle = [[NSString alloc] initWithString:@"Search Results"];
	
	m_locationManager = nil;
	m_currentLocation = nil;
	
	m_initialIndexPath = nil;
	m_initialLegislatorID = nil;
	m_initialSearchString = nil;
	
	m_actionType = eActionReload;
	
	m_HUD = [[ProgressOverlayViewController alloc] initWithWindow:self.tableView];
	[m_HUD show:NO];
	if ( ![m_data isDataAvailable] )
	{
		[m_HUD setText:[m_data currentStatusMessage] andIndicateProgress:YES];
	}
	
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
	// re-download congress data
	// 
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] 
											   initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
											   target:self 
											   action:@selector(reloadCongressData)] autorelease];
	
	// 
	// Add a "location" button which will be used to find senators/representatives
	// which represent a users current district
	// 
	[self setLocationButtonInNavBar];
	
	// create a search bar which will be used as our table's header view
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 50.0f)];
	searchBar.delegate = self;
	searchBar.prompt = @"";
	searchBar.placeholder = @"Search for legislator...";
	searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
	searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	searchBar.barStyle = UIBarStyleBlackOpaque;
	searchBar.showsCancelButton = YES;
	
	self.tableView.tableHeaderView = searchBar;
	self.tableView.tableHeaderView.userInteractionEnabled = YES;
	
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
	
	[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
}


- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
	
	if ( [m_data isDataAvailable] )
	{
		self.tableView.userInteractionEnabled = YES;
		[m_HUD show:NO];
		
		[self scrollToInitialPosition];
		
		if ( nil != m_initialLegislatorID )
		{
			LegislatorContainer *legislator = [m_data getLegislatorFromBioguideID:m_initialLegislatorID];
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		  selector:@selector(showInitialLegislator:) object:legislator];
			// Add the operation to the internal operation queue managed by the application delegate.
			[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
			[theOp release];
		}
	}
	else
	{
		[m_HUD show:YES]; // with whatever text is there...
		[m_HUD setText:[m_data currentStatusMessage] andIndicateProgress:YES];
	}
	
	[self.tableView setNeedsDisplay];
	
	// de-select the currently selected row
	// (so the user can go back to the same legislator)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
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
    return YES; // (interfaceOrientation == UIInterfaceOrientationPortrait);
}


// method called by our data manager when something interesting happens
- (void)dataManagerCallback:(id)message
{
	NSString *msg = message;
	
	NSRange msgTypeRange = {0, 5};
	if ( ([msg length] >= 5) && 
		 (NSOrderedSame == [msg compare:@"ERROR" options:NSCaseInsensitiveSearch range:msgTypeRange]) )
	{
		// crap! an error occurred in the parsing/downloading: give the user
		// an error message and leave it there...
		[self setLocationButtonInNavBar];
		self.tableView.userInteractionEnabled = NO;
		NSString *txt = [[[NSString alloc] initWithFormat:@"Error loading data%@",
											([msg length] <= 6 ? @"!" : 
											 [NSString stringWithFormat:@":\n%@",[msg substringFromIndex:6]])
						] autorelease];
		
		[m_HUD show:NO];
		self.tableView.userInteractionEnabled = YES;
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Error!"
							  message:txt
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:@"OK",nil];
		[alert show];
	}
	else if ( NSOrderedSame == [msg compare:@"LOCTN" options:NSCaseInsensitiveSearch range:msgTypeRange] )
	{
		m_selectedChamber = eCongressSearchResults;
		[self setLocationButtonInNavBar];
		[self.tableView reloadData];
		NSUInteger idx[2] = {0,0};
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
		[m_HUD show:NO];
		self.tableView.userInteractionEnabled = YES;
	}
	else if ( [m_data isDataAvailable] )
	{
		[m_HUD show:NO];
		self.tableView.userInteractionEnabled = YES;
		
		if ( nil != m_initialIndexPath || nil != m_initialSearchString )
		{
			[self scrollToInitialPosition];
		}
		else
		{
			// scroll to the top of the table
			[self.tableView reloadData];
			NSUInteger idx[2] = {0,0};
			[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}
		
		// load an initial legislator if we were told to do so!
		if ( nil != m_initialLegislatorID )
		{
			LegislatorContainer *legislator = [m_data getLegislatorFromBioguideID:m_initialLegislatorID];
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		  selector:@selector(showInitialLegislator:) object:legislator];
			
			// Add the operation to the internal operation queue managed by the application delegate.
			[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
			[theOp release];
		}
	}
	else
	{
		// something interesting must have happened,
		// update the user with some progress
		self.tableView.userInteractionEnabled = NO;
		[m_HUD show:YES];
		[m_HUD setText:msg andIndicateProgress:YES];
		[self.tableView setNeedsDisplay];
	}
	
}


- (void)showLegislatorDetail:(id)sender
{
	UIButton *button = (UIButton *)sender;
	if ( nil == button ) return;
	
	LegislatorNameCell *sdr = (LegislatorNameCell *)[button superview];
	if ( nil == sdr ) return;
	
	LegislatorViewController *legViewCtrl = [[LegislatorViewController alloc] init];
	[legViewCtrl setLegislator:[sdr m_legislator]];
	[self.navigationController pushViewController:legViewCtrl animated:YES];
	[legViewCtrl release];
}


- (NSString *)areaName
{
	return @"congress";
}


- (NSString *)getURLStateParms
{
	NSMutableString *state = [[[NSMutableString alloc] init] autorelease];
	
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
			[state appendString:[NSString stringWithFormat:@":%@:%@",[m_data currentSearchString],m_searchResultsTitle]];
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
	if ( [topView respondsToSelector:@selector(m_legislator)] )
	{
		// grab the legislator currently being viewed
		LegislatorContainer *legislator = [topView performSelector:@selector(m_legislator)];
		[state appendFormat:@":%@",[legislator bioguide_id]];
	}
	
	return state;
}


- (void)handleURLParms:(NSString *)parms
{
	NSString *bioguideID = nil;
	NSString *chamber = nil;
	int parmIdx = 0;
	
	if ( nil == parms ) return;
	
	NSArray *pArray = [parms componentsSeparatedByString:@":"];
	if ( [pArray count] < 1 ) return;
	
	if ( [pArray count] == 1 )
	{
		// this is a simple legislator URL, and the parameter should
		// be the legislator's bioguide_id 
		bioguideID = [pArray objectAtIndex:0];
		goto show_legislator;
	}
	
	
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
		m_selectedChamber = eCongressCommittee;
		// XXX - fill me in!
	}
	else if ( [chamber isEqualToString:@"search"] )
	{
		m_selectedChamber = eCongressSearchResults;
		[m_initialSearchString release]; m_initialSearchString = nil;
		[m_searchResultsTitle release]; m_searchResultsTitle = nil;
		if ( ++parmIdx < [pArray count] ) m_initialSearchString = [[NSString alloc] initWithString:[[pArray objectAtIndex:parmIdx] stringByReplacingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]];
		if ( ++parmIdx < [pArray count] ) m_searchResultsTitle = [[NSString alloc] initWithString:[[pArray objectAtIndex:parmIdx] stringByReplacingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]];
	}
	
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
	
	// a Bioguide ID can be tacked onto the end
	if ( ++parmIdx < [pArray count] )
	{
		bioguideID = [pArray objectAtIndex:parmIdx];
	}
	
	// the parms should be a legislator ID
show_legislator:
	if ( [m_data isDataAvailable] )
	{
		[self scrollToInitialPosition];
		
		[m_initialLegislatorID release]; m_initialLegislatorID = nil;
		if ( nil != bioguideID )
		{
			LegislatorContainer *legislator = [m_data getLegislatorFromBioguideID:bioguideID];
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																		  selector:@selector(showInitialLegislator:) object:legislator];
			
			// Add the operation to the internal operation queue managed by the application delegate.
			[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
			[theOp release];
		}
	}
	else
	{
		// stash the ID for later (when data is ready)
		if ( nil != bioguideID )
		{
			m_initialLegislatorID = [[NSString alloc] initWithString:bioguideID];
		}
	}
}



#pragma mark CongressViewController Private


- (void)setLocationButtonInNavBar
{
	UIImage *locImg = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"location_overlay.png"]];
	UIBarButtonItem *locBarButton = [[UIBarButtonItem alloc] 
									  initWithImage:locImg 
									  style:UIBarButtonItemStylePlain 
									  target:self 
									  action:@selector(findLocalLegislators:)];
	self.navigationItem.leftBarButtonItem = locBarButton;
	[locBarButton release];
}


- (void)setActivityViewInNavBar
{
	UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 32.0f)];
	UIActivityIndicatorView *aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
	//aiView.hidesWhenStopped = YES;
	[aiView setFrame:CGRectMake(12.0f, 6.0f, 20.0f, 20.0f)];
	[view addSubview:aiView];
	[aiView startAnimating];
	
	//UIBarButtonItem *locBarButton = [[UIBarButtonItem alloc] initWithCustomView:aiView];
	UIBarButtonItem *locBarButton = [[UIBarButtonItem alloc] 
										initWithBarButtonSystemItem:UIBarButtonSystemItemStop
										target:nil action:nil];
	locBarButton.customView = view;
	locBarButton.style = UIBarButtonItemStyleBordered;
	locBarButton.target = nil;
	self.navigationItem.leftBarButtonItem = locBarButton;
	
	[self.navigationController.navigationBar setNeedsDisplay];
	
	[view release];
	[aiView release];
	[locBarButton release];
}


// Switch the table data source between House and Senate
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


// wipe our device cache and re-download all congress personnel data
// (see UIActionSheetDelegate method for actual work)
- (void) reloadCongressData
{
	// don't start another re-load while one is apparently already in progress!
	if ( [m_data isBusy] ) return;
	
	// pop up an alert asking the user if this is what they really want
	m_actionType = eActionReload;
	UIActionSheet *reloadAlert =
	[[UIActionSheet alloc] initWithTitle:@"Re-Download congress data?\nWARNING: This may take some time..."
						   delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
					       otherButtonTitles:@"Download",nil,nil,nil,nil];
	
	// use the same style as the nav bar
	reloadAlert.actionSheetStyle = self.navigationController.navigationBar.barStyle;
	
	[reloadAlert showInView:self.view];
	[reloadAlert release];
}


- (void) deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same legislator)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


-(void)findLocalLegislators:(id)sender
{
	// XXX - lookup legislators in current district using location services
	// plus govtrack district data
	//NSLog( @"CongressViewController: finding local legislators..." );
	
	if ( nil == m_locationManager )
	{
		m_locationManager = [[CLLocationManager alloc] init];
		m_locationManager.desiredAccuracy = kCLLocationAccuracyBest;
		m_locationManager.distanceFilter = kCLDistanceFilterNone;
		m_locationManager.delegate = self;
	}
	
	if ( !m_locationManager.locationServicesEnabled )
	{
		// XXX - alert user of failure?!
		UIAlertView *alert = [[UIAlertView alloc] 
							  initWithTitle:@"Error finding local legislators"
							  message:[NSString stringWithString:@"Sorry, localtion services seems to be disabled/non-functional!"]
							  delegate:self
							  cancelButtonTitle:nil
							  otherButtonTitles:@"OK",nil];
		[alert show];
	}
	else
	{
		[self setActivityViewInNavBar];
		[m_searchResultsTitle release];
		m_searchResultsTitle = [[NSString alloc] initWithString:@"Local Legislators"];
		
		[m_locationManager startUpdatingLocation];
	}
}


- (void)scrollToInitialPosition
{
	BOOL isReloading = NO;
	
	if ( nil != m_initialSearchString )
	{
		UISearchBar *searchBar = (UISearchBar *)(self.tableView.tableHeaderView);
		[searchBar setText:m_initialSearchString];
		// this function does all the table data reloading for us :-)
		[self searchBar:searchBar textDidChange:m_initialSearchString];
		isReloading = YES;
	}
	
	if ( nil != m_initialIndexPath )
	{
		if ( !isReloading ) [self.tableView reloadData];
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
}


- (void)showInitialLegislator:(LegislatorContainer *)legislator
{
	// we should be running in a thread, so this should give my table
	// enough time to load itself up before I go and cover it up.
	// (yeah, it's a bit of a hack...)
	[NSThread sleepForTimeInterval:0.33f]; 
	
	[m_initialLegislatorID release]; m_initialLegislatorID = nil;
	if ( nil != legislator )
	{
		// only 1 legislator at a time!
		[self.navigationController popToRootViewControllerAnimated:NO];
		
		LegislatorViewController *legViewCtrl = [[LegislatorViewController alloc] init];
		[legViewCtrl setLegislator:legislator];
		[self.navigationController pushViewController:legViewCtrl animated:YES];
		[legViewCtrl release];
	}
}


- (LegislatorContainer *)legislatorFromIndexPath:(NSIndexPath *)idx
{
	LegislatorContainer *legislator = nil;
	//NSString *state = [[m_data states] objectAtIndex:indexPath.section];
	NSString *state = [[StateAbbreviations abbrList] objectAtIndex:idx.section];
	switch ( m_selectedChamber )
	{
		case eCongressChamberHouse:
			legislator = [[m_data houseMembersInState:state] objectAtIndex:idx.row];
			break;
		case eCongressChamberSenate:
			legislator = [[m_data senateMembersInState:state] objectAtIndex:idx.row];
			break;
		case eCongressSearchResults:
			legislator = [[m_data searchResultsArray] objectAtIndex:idx.row];
			break;
		default:
			legislator = nil;
			break;
	}
	
	return legislator;
}


#pragma mark CLLocationManagerDelegate methods


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	if ( signbit(newLocation.horizontalAccuracy) )
	{
		// Negative accuracy means an invalid or unavailable measurement
		// XXX - stop activity wheel, and notify user of failure?
	} 
	else if ( nil != oldLocation )
	{
		// try to smooth this a little - wait until the distance between
		// two subsequent readings is less than ~0.5km
		if ( [newLocation getDistanceFrom:oldLocation] < 500.0f )
		{
			[m_locationManager stopUpdatingLocation]; // save power!
			[m_data setSearchLocation:newLocation];
		}
    }
	else if ( nil != newLocation )
	{
		[m_data setSearchLocation:newLocation];
		// don't stop the updates...
	}
}


- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	[self setLocationButtonInNavBar];
	
	// XXX - notify user of error?
}


#pragma mark UISearchBarDelegate methods


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
	[m_searchResultsTitle release];
	m_searchResultsTitle = [[NSString alloc] initWithString:@"Search Results"];
	
	if ( [searchText length] == 0 )
	{
		[searchBar resignFirstResponder];
		switch ( [m_segmentCtrl selectedSegmentIndex] )
		{
			default:
			case 0:
				m_selectedChamber = eCongressChamberHouse;
				break;
			case 1:
				m_selectedChamber = eCongressChamberSenate;
				break;
		}
		[self.tableView reloadData];
	}
	else
	{
		m_selectedChamber = eCongressSearchResults;
		[m_data setSearchString:searchText];
	}
	
	[self.tableView reloadData];
}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
	m_selectedChamber = eCongressSearchResults;
	[self.tableView reloadData];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	searchBar.text = @"";
	[searchBar resignFirstResponder];
	
	switch ( [m_segmentCtrl selectedSegmentIndex] )
	{
		default:
		case 0:
			m_selectedChamber = eCongressChamberHouse;
			break;
		case 1:
			m_selectedChamber = eCongressChamberSenate;
			break;
	}
	
	[self.tableView reloadData];
}


#pragma mark UIActionSheetDelegate methods


// action sheet callback: maybe start a re-download on congress data
- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if ( eActionContact == m_actionType )
	{
		MessageData *msg = [[MessageData alloc] init];
		msg.m_transport = eMT_Invalid;
		
		LegislatorContainer *legislator = [self legislatorFromIndexPath:[self.tableView indexPathForSelectedRow]];
		if ( nil == legislator )
		{
			goto deselect_and_return;
		}
		
		// use currently selected legislator to perfom the following action:
		switch ( buttonIndex )
		{
			case 0:
				if ( [[legislator phone] length] > 0 )
				{
					msg.m_transport = eMT_PhoneCall;
					msg.m_to = [legislator phone];
				}
				break;
			case 1:
			{
				if ( [[legislator email] length] > 0 )
				{
					msg.m_transport = eMT_Email;
					msg.m_to = [legislator email];
					msg.m_subject = @"Message from a concerned citizen";
				}
				else
				{
					if ( [[legislator webform] length] > 0 ) 
					{
						// open a web browser to view the congress person's
						// web-based contact form (because they'e too luddite 
						// and/or paranoid to provide a standard email)
						MiniBrowserController *mbc = [MiniBrowserController sharedBrowser];
						[mbc loadURL:[NSURL URLWithString:[legislator webform]]];
						[mbc display:self];
					}
					else
					{
						// No twitter ID
						UIAlertView *alert = [[UIAlertView alloc] 
											  initWithTitle:@"Email Unavailable"
											  message:[NSString stringWithFormat:@"%@ has not registered any form of email contact!",[legislator shortName]]
											  delegate:self
											  cancelButtonTitle:nil
											  otherButtonTitles:@"OK",nil];
						[alert show];
					}
					goto deselect_and_return;
				}
			}
				break;
			case 2:
				if ( [[legislator twitter_id] length] > 0 )
				{
					msg.m_transport = eMT_SendTwitterDM;
					msg.m_to = [NSString stringWithFormat:@"@%@",[legislator twitter_id]];
					msg.m_subject = @"";
				}
				else
				{
					// No twitter ID
					UIAlertView *alert = [[UIAlertView alloc] 
											initWithTitle:@"Twitter Unavailable"
											message:[NSString stringWithFormat:@"%@ does not have a registered twitter account.",[legislator shortName]]
											delegate:self
											cancelButtonTitle:nil
											otherButtonTitles:@"OK",nil];
					[alert show];
				}
				break;
			case 3:
				msg.m_transport = eMT_MyGov;
				msg.m_to = @"MyGovernment Community";
				msg.m_subject = [NSString stringWithFormat:@"%@:",[legislator shortName]];
				msg.m_appURL = [NSURL URLWithString:[NSString stringWithFormat:@"mygov://congress/%@",[legislator bioguide_id]]];
				msg.m_appURLTitle = [legislator shortName];
				if ( [[legislator website] length] > 0 )
				{
					msg.m_webURL = [NSURL URLWithString:[legislator website]];
					msg.m_webURLTitle = @"Website";
				}
				break;
				
			default:
				break;
		}
		
		if ( msg.m_transport != eMT_Invalid )
		{
			// display the message composer
			ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
			[cmvc display:msg fromParent:self];
		}
		
		// deselect the selected row (after we've used it to get phone/email/twitter)
	deselect_and_return:
		[msg release];
		[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
	}
	else if ( eActionReload == m_actionType )
	{
		switch ( buttonIndex )
		{
			case 0:
			{
				// don't start another download if the data store is busy!
				if ( ![m_data isBusy] ) 
				{
					if ( [self.tableView numberOfSections] > 0 && 
						 [self.tableView numberOfRowsInSection:0] > 0 )
					{
						// scroll to the top of the table so that our progress HUD
						// is displayed properly
						NSUInteger idx[2] = {0,0};
						[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
					}
					// start a data download/update: this destroys the current data cache
					[m_data updateCongressData];
				}
				break;
			}
			default:
				break;
		}
	}
}


#pragma mark UIAlertViewDelegate Methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// Do something here?!
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if ( [m_data isDataAvailable] )
	{
		switch ( m_selectedChamber )
		{
			case eCongressSearchResults:
				return 1;
			
			default:
				return [[StateAbbreviations abbrList] count]; // [[m_data states] count];
		}
	}
	else
	{
		return 1;
	}
}


- (NSArray *)sectionIndexTitlesForTableView: (UITableView *)tableView
{
	if ( [m_data isDataAvailable] )
	{
		switch ( m_selectedChamber )
		{
			case eCongressSearchResults:
				return nil;
			default:
			{
				return [StateAbbreviations abbrTableIndexList];
			}
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
		switch ( m_selectedChamber )
		{
			case eCongressSearchResults:
				return m_searchResultsTitle;
			default:
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
		//NSString *state = [[m_data states] objectAtIndex:section];
		NSString *state = [[StateAbbreviations abbrList] objectAtIndex:section];
		switch (m_selectedChamber) 
		{
			default:
			case eCongressChamberHouse:
				return [[m_data houseMembersInState:state] count];
			case eCongressChamberSenate:
				return [[m_data senateMembersInState:state] count];
			case eCongressSearchResults:
				return [[m_data searchResultsArray] count];
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
    
	static NSString *CellIdentifier = @"CongressCell";

	LegislatorNameCell *cell = (LegislatorNameCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if ( cell == nil ) 
	{
		cell = [[[LegislatorNameCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier detailTarget:self detailSelector:@selector(showLegislatorDetail:)] autorelease];
	}
	
	cell.m_tableRange = (NSRange){indexPath.section, indexPath.row};
	
	if ( ![m_data isDataAvailable] ) return cell;
	
	LegislatorContainer *legislator = [self legislatorFromIndexPath:indexPath];
	
	if ( nil == legislator ) 
	{
		return cell;
	}
	
	// Set up the cell...
	[cell setInfoFromLegislator:legislator];
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	LegislatorContainer *legislator = [self legislatorFromIndexPath:indexPath];
	
	// no legislator here...
	if ( nil == legislator )
	{
		[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
		return;
	}
	
	// pop up an alert asking the user what action to perform
	m_actionType = eActionContact;
	UIActionSheet *contactAlert =
	[[UIActionSheet alloc] initWithTitle:[legislator shortName]
							delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
							otherButtonTitles:@"Call",@"Email",@"Twitter DM",@"Comment!",nil];
	
	// use the same style as the nav bar
	contactAlert.actionSheetStyle = self.navigationController.navigationBar.barStyle;
	
	[contactAlert showInView:self.view];
	[contactAlert release];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath 
{
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath 
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


@end


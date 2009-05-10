//
//  CommunityViewController.m
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//  Copyright 2009 U.S. PIRG. All rights reserved.
//

#import "myGovAppDelegate.h"
#import "CommunityDataManager.h"
#import "CommunityDetailViewController.h"
#import "CommunityItem.h"
#import "CommunityItemTableCell.h"
#import "CommunityViewController.h"
#import "ComposeMessageViewController.h"
#import "MyGovUserData.h"
#import "ProgressOverlayViewController.h"


@interface CommunityViewController (private)
	- (void)dataManagerCallback:(NSString *)msg;
	- (void)communityItemTypeSwitch:(id)sender;
	- (void)reloadCommunityItems;
	- (void)composeNewCommunityItem;
	- (void)deselectRow:(id)sender;
	- (void)setReloadButtonInNavBar;
	- (void)setActivityViewInNavBar;
@end


@implementation CommunityViewController


- (void)dealloc 
{
	[m_data release];
	[m_HUD release];
	[super dealloc];
}


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)viewDidLoad 
{
	m_data = [[myGovAppDelegate sharedCommunityData] retain];
	[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
	
	m_HUD = [[ProgressOverlayViewController alloc] initWithWindow:self.tableView];
	[m_HUD show:NO];
	[m_HUD setText:[m_data currentStatusMessage] andIndicateProgress:YES];
	
	
/* Leave this off for now - maybe in the next release...
 
	// create a search bar which will be used as our table's header view
	UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 50.0f)];
	searchBar.delegate = self;
	searchBar.prompt = @"";
	searchBar.placeholder = @"Search Chatter...";
	searchBar.autocorrectionType = UITextAutocorrectionTypeYes;
	searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
	searchBar.barStyle = UIBarStyleBlackOpaque;
	searchBar.showsCancelButton = YES;
	
	self.tableView.tableHeaderView = searchBar;
	self.tableView.tableHeaderView.userInteractionEnabled = YES;
*/
	
	// Create a new segment control and place it in 
	// the NavigationController's title area
	
	//NSArray *buttonNames = [NSArray arrayWithObjects:@"Chatter", @"Events", nil];
	NSArray *buttonNames = [NSArray arrayWithObjects:@"Chatter", nil];
	m_segmentCtrl = [[UISegmentedControl alloc] initWithItems:buttonNames];
	
	// default styles
	m_segmentCtrl.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	m_segmentCtrl.segmentedControlStyle = UISegmentedControlStyleBar;
	m_segmentCtrl.selectedSegmentIndex = 0; // Default to the "Chatter"
	m_selectedItemType = eCommunity_Chatter;
	m_segmentCtrl.frame = CGRectMake(0,0,200,30);
	// saturation of 0.0 means black/white
	m_segmentCtrl.tintColor = [UIColor darkGrayColor];
	
	// add ourself as the target
	[m_segmentCtrl addTarget:self action:@selector(communityItemTypeSwitch:) forControlEvents:UIControlEventValueChanged];
	
	// add the buttons to the navigation bar
	self.navigationItem.titleView = m_segmentCtrl;
	[m_segmentCtrl release];
	
	
	// 
	// Add a "new" button which will add either a 
	// new piece of chatter, or a new event depending on the 
	// currently selected view!
	// 
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] 
											  initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
											  target:self 
											  action:@selector(composeNewCommunityItem)];
	
	// 
	// Add a "refresh" button which will wipe out the on-device cache and 
	// re-download congressional bill data 
	// 
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
											  initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
											  target:self 
											  action:@selector(reloadCommunityItems)];
	
	
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
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}


- (void)showCommunityDetail:(id)sender
{
	// XXX - do this!
	UIButton *button = (UIButton *)sender;
	if ( nil == button ) return;
	
	CommunityItemTableCell *tcell = (CommunityItemTableCell *)[button superview];
	if ( nil == tcell ) return;
	
	CommunityDetailViewController *cdView = [[CommunityDetailViewController alloc] init];
	[cdView setItem:[tcell m_item]];
	[self.navigationController pushViewController:cdView animated:YES];
	[cdView release];
}


- (NSString *)areaName
{
	return @"community";
}


- (NSString *)getURLStateParms
{
	return @"";
}


- (void)handleURLParms:(NSString *)parms
{
}


#pragma mark CommunityViewController Private


- (void)dataManagerCallback:(NSString *)msg
{
	NSRange endTypeRange = {0, 3};
	NSRange msgTypeRange = {0, 5};
	if ( NSOrderedSame == [msg compare:@"ERR: " options:NSCaseInsensitiveSearch range:msgTypeRange] )
	{
		// pop up an alert dialog to let the user know that an error has occurred!
		UIAlertView *alert = [[UIAlertView alloc] 
										initWithTitle:@"Community Data Error"
											  message:[msg substringFromIndex:msgTypeRange.length-1]
											 delegate:self
									cancelButtonTitle:nil
									otherButtonTitles:@"OK",nil];
		[alert show];
		[self setReloadButtonInNavBar];
	}
	else if ( [m_data isDataAvailable] )
	{
		[m_HUD show:NO];
		[self.tableView setUserInteractionEnabled:YES];
		[self.tableView reloadData];
		
		[self setReloadButtonInNavBar];
	}
	else if ( NSOrderedSame == [msg compare:@"END" options:NSCaseInsensitiveSearch range:endTypeRange] )
	{
		// the data manager is done doing what it was doing, so kill the HUD
		[m_HUD show:NO];
		[self.tableView setUserInteractionEnabled:YES];
		[self.tableView reloadData];
		[self setReloadButtonInNavBar];
	}
	else
	{
		// display the status text
		[m_HUD setText:[m_data currentStatusMessage] andIndicateProgress:YES];
		[m_HUD show:YES];
		[self.tableView setUserInteractionEnabled:NO];
	}
	
	[self.tableView setNeedsDisplay];
}


- (void)communityItemTypeSwitch:(id)sender
{
	UISearchBar *searchBar = (UISearchBar *)self.tableView.tableHeaderView;
	
	switch ( [sender selectedSegmentIndex] )
	{
		default:
		case 0:
			// This is the chatter (feedback) list
			m_selectedItemType = eCommunity_Chatter;
			searchBar.placeholder = @"Search Chatter...";
			break;
			
		case 1:
			// This is the event list
			m_selectedItemType = eCommunity_Event;
			searchBar.placeholder = @"Search Events...";
			break;
	}
	if ( [m_data isDataAvailable] ) 
	{
		[self.tableView reloadData];
		if ( [m_data numberOfRowsInSection:0 forType:m_selectedItemType] > 0 ) 
		{
			NSUInteger idx[2] = {0,0};
			[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
		}
		self.tableView.userInteractionEnabled = YES;
	}
}


- (void)reloadCommunityItems
{
	[self setActivityViewInNavBar];
	
	[m_data purgeAllItemsFromCacheAndMemory];
	
	[m_data loadData];
}


- (void)composeNewCommunityItem
{
	switch ( m_selectedItemType )
	{
		default:
			break;
		
		case eCommunity_Chatter:
		{
			// create a new feedback item!
			MessageData *msg = [[MessageData alloc] init];
			msg.m_transport = eMT_MyGov;
			msg.m_to = @"MyGovernment Community";
			msg.m_subject = @" ";
			msg.m_body = @" ";
			msg.m_communityThreadID = nil;
			
			// display the message composer
			ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
			[cmvc display:msg fromParent:self];
		}
			break;
			
		case eCommunity_Event:
		{
			NSString *title = @"New Community Event";
			UIAlertView *alert = [[UIAlertView alloc] 
								  initWithTitle:title
								  message:@"This action is temporarily disabled..."
								  delegate:self
								  cancelButtonTitle:nil
								  otherButtonTitles:@"OK",nil];
			[alert show];
		}
			break;
	}
}


- (void) deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same row)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}



- (void)setReloadButtonInNavBar
{
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
											 initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh 
											 target:self 
											 action:@selector(reloadCommunityItems)];
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
	self.navigationItem.rightBarButtonItem = locBarButton;
	
	[self.navigationController.navigationBar setNeedsDisplay];
	
	[view release];
	[aiView release];
	[locBarButton release];
}



#pragma mark UIAlertViewDelegate Methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	// Do something here?!
}


#pragma mark UIActionSheetDelegate methods


// action sheet callback: maybe start a re-download on congress data
- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	
	CommunityItem *item = [m_data itemForIndexPath:[self.tableView indexPathForSelectedRow] 
										   andType:m_selectedItemType];
	if ( nil == item )
	{
		goto deselect_and_return;
	}
	
	// use currently selected legislator to perfom the following action:
	switch ( buttonIndex )
	{
/*
		// View User Info
		case 0:
		{
			// XXX - not ready for this yet...
			UIAlertView *alert = [[UIAlertView alloc] 
								  initWithTitle:[[[myGovAppDelegate sharedUserData] userFromID:item.m_creator] m_username]
								  message:@"User info view is currently disabled"
								  delegate:self
								  cancelButtonTitle:nil
								  otherButtonTitles:@"OK",nil];
			[alert show];
		}
			break;
*/
		// Reply/comment on this event or piece of chatter (feedback)
		case 0:
		{
			MessageData *msg = [[MessageData alloc] init];
			msg.m_transport = eMT_MyGovUserComment;
			msg.m_to = @"MyGovernment Community";
			msg.m_subject = [NSString stringWithFormat:@"Re: %@",[item m_title]];
			msg.m_body = @" "; //[item m_title];
			msg.m_communityThreadID = [item m_id];
			msg.m_appURL = [item m_mygovURL];
			msg.m_appURLTitle = [item m_mygovURLTitle];
			msg.m_webURL = [item m_webURL];
			msg.m_webURLTitle = [item m_webURLTitle];
			
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


#pragma mark UISearchBarDelegate methods


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{}


- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
	[searchBar resignFirstResponder];
}


- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
	searchBar.text = @"";
	[searchBar resignFirstResponder];
}


#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return [m_data numberOfSectionsForType:m_selectedItemType];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	//NSLog(@"Number of rows in community table view: %d", [displayList count]);
	return [m_data numberOfRowsInSection:section forType:m_selectedItemType];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [m_data heightForDataAtIndexPath:indexPath forType:m_selectedItemType];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *CellIdentifier = @"CommunityCell";
	
	CommunityItemTableCell *cell = (CommunityItemTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if ( nil == cell ) 
	{
		cell = [[[CommunityItemTableCell alloc] initWithFrame:CGRectZero
											  reuseIdentifier:CellIdentifier] autorelease];
		
		[cell setDetailTarget:self andSelector:@selector(showCommunityDetail:)];
	}	
	
	// Set up the cell...
	[cell setCommunityItem:[m_data itemForIndexPath:indexPath andType:m_selectedItemType]];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
	CommunityItem *item = [m_data itemForIndexPath:indexPath andType:m_selectedItemType];
	
	// pop up an alert asking the user what action to perform
	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:[item m_title]
													   delegate:self 
											  cancelButtonTitle:@"Cancel" 
										 destructiveButtonTitle:nil
											  otherButtonTitles:@"Reply!",nil,nil];
	
	// use the same style as the nav bar
	sheet.actionSheetStyle = self.navigationController.navigationBar.barStyle;
	
	[sheet showInView:self.view];
	[sheet release];
	
	//[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
}



// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// Return NO if you do not want the specified item to be editable.
	return NO;
}


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
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


@end


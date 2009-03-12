//
//  CongressViewController.m
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CongressViewController.h"
#import "CongressDataManager.h"
#import "LegislatorContainer.h"
#import "LegislatorViewController.h"
#import "LegislatorNameCell.h"
#import "ProgressOverlayViewController.h"


@interface CongressViewController (private)
	- (void) congressSwitch: (id)sender;
	- (void) reloadCongressData;
	- (void) deselectRow:(id)sender;
@end


@implementation CongressViewController

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
    // Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
    [super dealloc];
}


- (void)viewDidLoad
{
	self.title = @"Congress";
	
	self.tableView.autoresizesSubviews = YES;
	self.tableView.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin);
	self.tableView.rowHeight = 50.0f;
	
	m_HUD = [[ProgressOverlayViewController alloc] initWithWindow:self.tableView];
	[m_HUD setText:@"Loading..." andIndicateProgress:YES];
	
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
	m_segmentCtrl.tintColor = [[UIColor alloc] initWithHue:0.0 saturation:0.0 brightness:0.45 alpha:1.0];
	
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
	// XXX - Add a "location" button
	// 
	/*
	 UIButton* modalViewButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	 [modalViewButton addTarget:self action:@selector(modalViewAction:) forControlEvents:UIControlEventTouchUpInside];
	 UIBarButtonItem *modalButton = [[UIBarButtonItem alloc] initWithCustomView:modalViewButton];
	 self.navigationItem.leftBarButtonItem = modalButton;
	 [modalViewButton release];
	 */
	
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated 
{
	if ( nil == m_data )
	{
		m_data = [[CongressDataManager alloc] initWithNotifyTarget:self andSelector:@selector(dataManagerCallback:)];
		//[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
	}
	
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
	}
	
	// de-select the currently selected row
	// (so the user can go back to the same legislator)
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
    return YES; // (interfaceOrientation == UIInterfaceOrientationPortrait);
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


// method called by our data manager when something interesting happens
- (void)dataManagerCallback:(id)message
{
	NSString *msg = message;
	
	NSLog( @"dataManagerCallback: %@",msg );
	
	NSRange errRange = {0, 5};
	if ( NSOrderedSame == [msg compare:@"ERROR" options:NSCaseInsensitiveSearch range:errRange] )
	{
		// crap! an error occurred in the parsing/downloading: give the user
		// an error message and leave it there...
		self.tableView.userInteractionEnabled = NO;
		NSString *txt = [NSString stringWithFormat:@"Error loading data%@",
							([msg length] <= 6 ? @"!" : 
							 [NSString stringWithFormat:@": \n%@",[msg substringFromIndex:6]])];
		[m_HUD setText:txt andIndicateProgress:NO];
		[m_HUD show:YES];
		[txt release];
	}
	else if ( [m_data isDataAvailable] )
	{
		[self.tableView reloadData];
		NSUInteger idx[2] = {0,0};
		[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
		[m_HUD show:NO];
		self.tableView.userInteractionEnabled = YES;
	}
	else
	{
		// something interesting must have happened,
		// update the user with some progress
		self.tableView.userInteractionEnabled = YES;
		[m_HUD setText:msg andIndicateProgress:YES];
		[m_HUD show:YES];
		[self.tableView setNeedsDisplay];
		self.tableView.userInteractionEnabled = NO;
	}
}


- (void) deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same legislator)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


// wipe our device cache and re-download all congress personnel data
// (see UIActionSheetDelegate method for actual work)
- (void) reloadCongressData
{
	// don't start another re-load while one is apparently already in progress!
	if ( [m_data isBusy] ) return;
	
	// pop up an alert asking the user if this is what they really want
	UIActionSheet *reloadAlert =
	[[UIActionSheet alloc] initWithTitle:@"Re-Download congress data?\nWARNING: This may take some time..."
						   delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
					       otherButtonTitles:@"Download",nil,nil,nil,nil];
	
	// use the same style as the nav bar
	reloadAlert.actionSheetStyle = self.navigationController.navigationBar.barStyle;
	
	[reloadAlert showInView:self.view];
	[reloadAlert release];
}


#pragma mark UIActionSheetDelegate methods


// action sheet callback: maybe start a re-download on congress data
- (void)actionSheet:(UIActionSheet *)modalView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	switch (buttonIndex)
	{
		case 0:
		{
			// don't start another download if the data store is busy!
			if ( ![m_data isBusy] ) 
			{
				// scroll to the top of the table so that our progress HUD
				// is displayed properly
				NSUInteger idx[2] = {0,0};
				[self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathWithIndexes:idx length:2] atScrollPosition:UITableViewScrollPositionTop animated:NO];
				
				// start a data download/update: this destroys the current data cache
				[m_data updateCongressData];
			}
			break;
		}
		default:
			break;
	}
}


#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if ( [m_data isDataAvailable] )
	{
		return [[m_data states] count];
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
		// 50 index points is too many - cut it in half by simple
		// NULL-ing out every odd entry title
		NSMutableArray * tmpArray = [[[NSMutableArray alloc] initWithArray:[m_data states]] autorelease];
		NSUInteger numStates = [tmpArray count];
		
		for ( NSUInteger st = 0; st < numStates; ++st )
		{
			if ( ((st+1) % 2) ) // || !((st+1) % 3) )
			{
				[tmpArray replaceObjectAtIndex:st withObject:[NSString stringWithString:@""] ];
			}
		}
		
		return tmpArray; //[m_data states];
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
		// XXX - get full state name?
		return [[m_data states] objectAtIndex:section];
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
		NSString *state = [[m_data states] objectAtIndex:section];
		switch (m_selectedChamber) 
		{
			default:
			case eCongressChamberHouse:
				return [[m_data houseMembersInState:state] count];
			case eCongressChamberSenate:
				return [[m_data senateMembersInState:state] count];
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
		cell = [[[LegislatorNameCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
	
	if ( ![m_data isDataAvailable] ) return cell;
	
	NSString *state = [[m_data states] objectAtIndex:indexPath.section];
	LegislatorContainer *legislator;
	if ( eCongressChamberHouse == m_selectedChamber ) 
	{
		legislator = [[m_data houseMembersInState:state] objectAtIndex:indexPath.row];
	}
	else
	{
		legislator = [[m_data senateMembersInState:state] objectAtIndex:indexPath.row];
	}
	
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
	NSString *state = [[m_data states] objectAtIndex:indexPath.section];
	LegislatorContainer *legislator;
	if ( eCongressChamberHouse == m_selectedChamber ) 
	{
		legislator = [[m_data houseMembersInState:state] objectAtIndex:indexPath.row];
	}
	else
	{
		legislator = [[m_data senateMembersInState:state] objectAtIndex:indexPath.row];
	}
	
	LegislatorViewController *legViewCtrl = [[LegislatorViewController alloc] init];
	[legViewCtrl setLegislator:legislator];
	[self.navigationController pushViewController:legViewCtrl animated:YES];
	[legViewCtrl release];
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


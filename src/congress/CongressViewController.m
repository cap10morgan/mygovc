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

@interface CongressViewController (private)
	- (void) congressSwitch: (id)sender;
@end


@implementation CongressViewController

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


/**
	Switch the table data source between House and Senate
 */
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
	if ( [m_data isDataAvailable] ) [self.tableView reloadData];
}


- (void)dataManagerCallback:(id)dataManager
{
	if ( dataManager == m_data )
	{
		if ( [m_data isDataAvailable] )
		{
			[self.tableView reloadData];
		}
	}
}


- (void)viewDidLoad
{
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
	
	// XXX - Add a "location" button
	
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated 
{
	if ( nil == m_data )
	{
		m_data = [[CongressDataManager alloc] init];
		[m_data setNotifyTarget:self withSelector:@selector(dataManagerCallback:)];
	}
	
	if ( !m_data.isDataAvailable )
	{
		// XXX = put up some sort of notification that 
		// data is being downloaded/retrieved...
	}
	
    [super viewWillAppear:animated];
}


/*
- (void)viewDidAppear:(BOOL)animated 
{
    [super viewDidAppear:animated];
}
*/

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
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
			if ( st % 2 )
			{
				[tmpArray replaceObjectAtIndex:st withObject:[[[NSString alloc] initWithString:@""] autorelease] ];
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

	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if ( cell == nil ) 
	{
		cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
	
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
		cell.text = [[[NSString alloc] initWithString:@"??"] autorelease];
		return cell;
	}
	
	// Set up the cell...
	NSString *lbl = [[NSString alloc] initWithFormat:@"%@. %@ %@ %@ (%@)",
											[legislator title],
											[legislator firstname],
											([legislator middlename] ? [legislator middlename] : @""),
											[legislator lastname],
											[legislator party]
					 ];
	cell.text = lbl;
	[lbl release];
	
	//cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
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


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
#import "ProgressOverlayViewController.h"


@interface BillsViewController (private)
	- (void)dataManagerCallback:(id)sender;
	- (void) deselectRow:(id)sender;
@end



@implementation BillsViewController

enum
{
	eTAG_ACTIVITY = 999,
};

static CGFloat S_CELL_PADDING = 7.0f;
static CGFloat S_HEADER_HEIGHT = 33.0f;
/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

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
	[m_HUD setText:@"Waiting for data..." andIndicateProgress:YES];
	
	self.tableView.separatorColor = [UIColor blackColor];
	self.tableView.backgroundColor = [UIColor blackColor];
	
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated 
{
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

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}
*/

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
		[m_HUD setText:[NSString stringWithString:@"Waiting for data..."] andIndicateProgress:YES];
	}
}


- (void) deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same row)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	if ( ![m_data isDataAvailable] ) return 1;
	else return [m_data totalBills]; // 1 section per bill
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	return 1; // 1 row per bill :-)
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ( ![m_data isDataAvailable] ) return 20.0f;
	
	return [BillSummaryTableCell getCellHeightForBill:[m_data billAtIndex:indexPath.section]];
}


- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return (S_HEADER_HEIGHT + S_CELL_PADDING);
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	CGRect lblFrame = CGRectMake(S_CELL_PADDING, S_CELL_PADDING, 320.0f - S_CELL_PADDING, S_HEADER_HEIGHT);
	UILabel *sectionLabel = [[[UILabel alloc] initWithFrame:lblFrame] autorelease];
	sectionLabel.backgroundColor = [UIColor clearColor];
	sectionLabel.textColor = [UIColor whiteColor];
	sectionLabel.font = [UIFont boldSystemFontOfSize:18.0f];
	sectionLabel.textAlignment = UITextAlignmentLeft;
	sectionLabel.adjustsFontSizeToFitWidth = YES;
	
	if ( [m_data isDataAvailable] )
	{
		[sectionLabel setText:[[m_data billAtIndex:section] getShortTitle]];
	}
	else
	{
		[sectionLabel setText:@"Downloading..."];
		CGSize lblSz = [sectionLabel.text sizeWithFont:[UIFont boldSystemFontOfSize:18.0f] 
							  constrainedToSize:CGSizeMake(320.0f - S_CELL_PADDING,S_HEADER_HEIGHT) 
							  lineBreakMode:UILineBreakModeTailTruncation];
		UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		[activity setFrame:CGRectMake(lblSz.width+S_CELL_PADDING,S_CELL_PADDING,S_HEADER_HEIGHT,S_HEADER_HEIGHT)];
		[activity startAnimating];
	}
	
	return sectionLabel;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{    
	static NSString *CellIdentifier = @"BillCell";
    
	BillSummaryTableCell *cell = (BillSummaryTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[[BillSummaryTableCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
	
	if ( ![m_data isDataAvailable] )
	{
		[cell setContentFromBill:nil];
	}
	else
	{
		[cell setContentFromBill:[m_data billAtIndex:indexPath.section]];
	}
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// XXX - do something!
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
}


@end


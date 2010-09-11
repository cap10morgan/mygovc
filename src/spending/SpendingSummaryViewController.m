/*
 File: SpendingSummaryViewController.m
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
#import "myGovCompileOptions.h"
#import "ComposeMessageViewController.h"
#import "ContractorSpendingData.h"
#import "CustomTableCell.h"
#import "PlaceSpendingData.h"
#import "SpendingSummaryData.h"
#import "SpendingSummaryViewController.h"


@interface SpendingSummaryViewController (private)
	- (void)deselectRow:(id)sender;
	- (void)composeNewCommunityItem;
@end



@implementation SpendingSummaryViewController

@synthesize m_placeData, m_contractorData;

- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[m_placeData release];
	[m_contractorData release];
	
	[m_data release];
	
	[super dealloc];
}


- (id) init
{
	if ( self = [super init] )
	{
		self.title = @"Spending Summary"; // this will be updated later...
		m_placeData = nil;
		m_contractorData = nil;
		m_data = nil;
	}
	return self;
}


- (void)setPlaceData:(PlaceSpendingData *)data
{
	[m_contractorData release]; m_contractorData = nil;
	[m_placeData release];
	m_placeData = [data retain];
	
	if ( nil == m_data )
	{
		m_data = [[SpendingSummaryData alloc] init];
	}
	[m_data setPlaceData:m_placeData];
	
	self.title = [data placeDescrip];
	[self.tableView reloadData];
}


- (void)setContractorData:(ContractorInfo *)data
{
	[m_placeData release]; m_placeData = nil;
	[m_contractorData release];
	m_contractorData = [data retain];
	
	if ( nil == m_data )
	{
		m_data = [[SpendingSummaryData alloc] init];
	}
	[m_data setContractorData:m_contractorData];
	
	self.title = m_contractorData.m_parentCompany;
	[self.tableView reloadData];
}


- (void)loadView
{
	m_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	m_tableView.delegate = self;
	m_tableView.dataSource = self;
	
	self.view = m_tableView;
	[m_tableView release];
	
	//m_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	m_tableView.separatorColor = [UIColor blackColor];
	m_tableView.backgroundColor = [UIColor blackColor];
	
	// 
	// Add a "new" button which will add either a 
	// new piece of chatter, or a new event depending on the 
	// currently selected view!
	// 
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
											  initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
											  target:self 
											  action:@selector(composeNewCommunityItem)];
	
	
	/*
	 // XXX - set tableHeaderView to a custom UIView which has legislator
	 //       photo, name, major info (party, state, district), add to contacts link
	 // m_tableView.tableHeaderView = headerView;
	 CGRect hframe = CGRectMake(0,0,320,150);
	 m_headerViewCtrl = [[LegislatorHeaderViewController alloc] initWithNibName:@"LegislatorHeaderView" bundle:nil ];
	 [m_headerViewCtrl.view setFrame:hframe];
	 [m_headerViewCtrl setLegislator:m_legislator];
	 [m_headerViewCtrl setNavController:self];
	 m_tableView.tableHeaderView = m_headerViewCtrl.view;
	 m_tableView.tableHeaderView.userInteractionEnabled = YES;
	 */
}


/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

/*
- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
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
	MYGOV_SHOULD_SUPPORT_ROTATION(interfaceOrientation);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.tableView reloadData];
}


#pragma mark SpendingSummaryViewController Private


- (void)deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same legislator)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


- (void)composeNewCommunityItem
{
	MessageData *msg = [[MessageData alloc] init];
	msg.m_transport = eMT_MyGov;
	msg.m_to = @"MyGovernment Community";
	
	if ( nil != m_placeData )
	{
		// place 
		msg.m_body = @" ";
		
		msg.m_subject = [NSString stringWithFormat:@"Spending: %@",[m_placeData m_place]];
		msg.m_appURL = [NSURL URLWithString:[NSString stringWithFormat:@"mygov://spending/place/%@",[m_placeData m_place]]];;
		msg.m_appURLTitle = [m_placeData m_place];
		
		msg.m_appURLTitle = msg.m_subject;
		msg.m_webURL = [m_placeData getTransactionListURL];
		msg.m_webURLTitle = @"USASpending.gov";  
	}
	else
	{
		// contractor
		msg.m_subject = [NSString stringWithFormat:@"Spending: %@",m_contractorData.m_parentCompany];
		msg.m_appURL = [NSURL URLWithString:[NSString stringWithFormat:@"mygov://spending/contractor/%0d",m_contractorData.m_parentDUNS]];
		msg.m_appURLTitle = m_contractorData.m_parentCompany;
	}
	
	// display the message composer
	ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
	[cmvc display:msg fromParent:self];
}


#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return [m_data numberOfSections];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	
	if ( nil ==  m_placeData && nil == m_contractorData ) return 0;
	
	return [m_data numberOfRowsInSection:section];
}



- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 35.0f;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	CGRect lblFrame = CGRectMake(0.0f, 0.0f, 320.0f, 40.0f);
	UILabel *sectionLabel = [[[UILabel alloc] initWithFrame:lblFrame] autorelease];
	sectionLabel.backgroundColor = [UIColor clearColor];
	sectionLabel.textColor = [UIColor whiteColor];
	sectionLabel.font = [UIFont boldSystemFontOfSize:18.0f];
	sectionLabel.textAlignment = UITextAlignmentLeft;
	sectionLabel.adjustsFontSizeToFitWidth = YES;
	
	NSMutableString *sectionTitle = [[[NSMutableString alloc] initWithString:[m_data titleForSection:section]] autorelease];
	if ( m_data.recoveryDataOnly )
	{
		[sectionTitle appendString:@" (Recovery)"];
	}
	
	[sectionLabel setText:sectionTitle];
	
	return sectionLabel;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [m_data heightForDataAtIndexPath:indexPath];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *CellIdentifier = @"SpendingSummaryInfoCell";
	
	CustomTableCell *cell = (CustomTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if ( nil == cell )
	{
		cell = [[[CustomTableCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}
	
	TableRowData *rd = [m_data dataAtIndexPath:indexPath];
	[cell setRowData:rd];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// perform a custom action based on the section/row
	// i.e. make a phone call, send an email, view a map, etc.
	[m_data performActionForIndex:indexPath withParent:self];
	
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
}


@end


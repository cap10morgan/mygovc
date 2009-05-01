//
//  BillInfoViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BillInfoViewController.h"
#import "BillContainer.h"
#import "BillInfoData.h"
#import "ComposeMessageViewController.h"
#import "CustomTableCell.h"

@interface BillInfoViewController (private)
	- (void)deselectRow;
	- (void)composeNewCommunityItem;
@end


@implementation BillInfoViewController

@synthesize m_bill;


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[m_bill release];
	
	[m_data release];
	
	[super dealloc];
}


- (id) init
{
	if ( self = [super init] )
	{
		self.title = @"Bill"; // this will be updated later...
		m_bill = nil;
		m_data = nil;
	}
	return self;
}


- (void)setBill:(BillContainer *)bill
{
	[m_bill release];
	m_bill = [bill retain];
	
	if ( nil == m_data )
	{
		m_data = [[BillInfoData alloc] init];
	}
	[m_data setBill:m_bill];
	
	self.title = [m_bill getShortTitle];
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
	return YES;
}


#pragma mark BillInfoViewController Private


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
	msg.m_subject = [NSString stringWithFormat:@"%@ %0d:", [BillContainer getBillTypeShortDescrip:m_bill.m_type], m_bill.m_number];
	msg.m_body = @" ";
	msg.m_appURL = [NSURL URLWithString:[NSString stringWithFormat:@"mygov://bills/%@/%0d",
										 [BillContainer stringFromBillType:m_bill.m_type],
										 m_bill.m_number]
					];
	msg.m_appURLTitle = msg.m_subject;
	msg.m_webURL = [m_bill getFullTextURL];
	msg.m_webURLTitle = @"Full Bill Text";
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
	
	if ( nil ==  m_bill ) return 0;
	
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
	
	[sectionLabel setText:[m_data titleForSection:section]];
	
	return sectionLabel;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [m_data heightForDataAtIndexPath:indexPath];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *CellIdentifier = @"BillInfoCell";
	
	CustomTableCell *cell = (CustomTableCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if ( nil == cell )
	{
		cell = [[[CustomTableCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
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


//
//  LegislatorViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LegislatorViewController.h"
#import "LegislatorContainer.h"
#import "LegislatorInfoCell.h"
#import "LegislatorHeaderViewController.h"

@implementation LegislatorViewController

@synthesize m_legislator;

static const int  kNumTableSections = 3;

static const int  kContactSectionIdx = 0;
static NSString  *kContactHeaderTxt = @"Contact Information";

static const int  kStreamSectionIdx = 1;
static NSString  *kStreamHeaderTxt = @"Legislator Info Stream";

static const int  kActivitySectionIdx = 2;
static NSString  *kActivityHeaderTxt = @"Recent Activity";


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[m_legislator release];
	[m_headerViewCtrl release];
	
	[m_contactFields release];
	[m_streamFields release];
	[m_activityFields release];
	
	[m_contactRows release];
	[m_streamRows release];
	[m_activityRows release];
	
	[super dealloc];
}

- (id) init
{
	if ( self = [super init] )
	{
		self.title = @"Legislator"; // this will be updated later...
		m_contactRows = [[NSMutableDictionary alloc] initWithCapacity:10];
		m_streamRows = [[NSMutableDictionary alloc] initWithCapacity:10];
		m_activityRows = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	return self;
}


- (void)setLegislator:(LegislatorContainer *)legislator
{
	[m_legislator release];
	[m_contactFields release];
	[m_streamFields release];
	[m_activityFields release];
	
	
	m_legislator = [legislator retain];
	self.title = [[[NSString alloc] initWithFormat:@"%@ %@",[m_legislator firstname],[m_legislator lastname]] autorelease];
	
	// 
	// setup the table data
	//
	
	// Contact Section --------------
	[m_contactRows removeAllObjects];
	
	if ( [[m_legislator email] length] > 0 )
	{
		[m_contactRows setObject:[m_legislator email] forKey:@"01_email"];
	}
	
	if ( [[m_legislator phone] length] > 0 )
	{
		[m_contactRows setObject:[m_legislator phone] forKey:@"02_phone"];
	}
	
	if ( [[m_legislator fax] length] > 0 )
	{
		[m_contactRows setObject:[m_legislator fax] forKey:@"03_fax"];
	}
	
	if ( [[m_legislator website] length] > 0 )
	{
		[m_contactRows setObject:[m_legislator website] forKey:@"04_website"];
	}
	
	if ( [[m_legislator congress_office] length] > 0 )
	{
		[m_contactRows setObject:[m_legislator congress_office] forKey:@"05_office"];
	}
	
	m_contactFields = [[NSArray alloc] initWithArray:[[m_contactRows allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	
	// Stream Section --------------
	[m_streamRows removeAllObjects];
	
	/*
	if ( [[m_legislator votesmart_id] length] > 0 )
	{
		[m_streamRows setObject:[m_legislator votesmart_id] forKey:@"01_votesmart"];
	}
	*/
	
	if ( [[m_legislator twitter_id] length] > 0 )
	{
		[m_streamRows setObject:[m_legislator twitter_id] forKey:@"01_twitter"];
	}
	
	if ( [[m_legislator youtube_url] length] > 0 )
	{
		[m_streamRows setObject:[m_legislator youtube_url] forKey:@"02_youtube"];
	}
	
	if ( [[m_legislator eventful_id] length] > 0 )
	{
		[m_streamRows setObject:[m_legislator eventful_id] forKey:@"03_eventful"];
	}
	
	if ( [[m_legislator congresspedia_url] length] > 0 )
	{
		[m_streamRows setObject:[m_legislator congresspedia_url] forKey:@"04_open congress"];
	}
	
	m_streamFields = [[NSArray alloc] initWithArray:[[m_streamRows allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	
	// XXX - kick off a data download from OpenCongress.org
	
	[m_activityRows setObject:[NSString stringWithString:@"Download from OpenCongress.org..."] forKey:@"01_..."];
	m_activityFields = [[NSArray alloc] initWithArray:[[m_activityRows allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	
	[m_headerViewCtrl setLegislator:legislator];
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
	
	// XXX - set tableHeaderView to a custom UIView which has legislator
	//       photo, name, major info (party, state, district), add to contacts link
	// m_tableView.tableHeaderView = headerView;
	CGRect hframe = CGRectMake(0,0,320,140);
	m_headerViewCtrl = [[LegislatorHeaderViewController alloc] initWithNibName:@"LegislatorHeaderView" bundle:nil ];
	[m_headerViewCtrl.view setFrame:hframe];
	[m_headerViewCtrl setLegislator:m_legislator];
	m_tableView.tableHeaderView = m_headerViewCtrl.view;
	m_tableView.tableHeaderView.userInteractionEnabled = YES;
}


/*
- (void)viewDidLoad 
{
	[super viewDidLoad];

	// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
	// self.navigationItem.rightBarButtonItem = self.editButtonItem;
}
*/

/*
- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
}
*/

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
    return kNumTableSections;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if ( nil ==  m_legislator ) return 0;
	
	if ( kContactSectionIdx == section )
	{
		return [m_contactRows count];
	}
	else if ( kStreamSectionIdx == section )
	{
		return [m_streamRows count];
	}
	else if ( kActivitySectionIdx == section )
	{
		return [m_activityRows count];
	}
	else
	{
		return 0;
	}
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	if ( kContactSectionIdx == section )
	{
		return kContactHeaderTxt;
	}
	else if ( kStreamSectionIdx == section )
	{
		return kStreamHeaderTxt;
	}
	else if ( kActivitySectionIdx == section )
	{
		return kActivityHeaderTxt;
	}
	else
	{
		return 0;
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *CellIdentifier = @"LegInfoCell";

	LegislatorInfoCell *cell = (LegislatorInfoCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[[LegislatorInfoCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
	
	// Set up the cell...
	if ( kContactSectionIdx == indexPath.section )
	{
		NSString *keyName = [m_contactFields objectAtIndex:indexPath.row];
		NSString *val = [m_contactRows objectForKey:keyName];
		[cell setField:keyName withValue:val];
	}
	else if ( kStreamSectionIdx == indexPath.section )
	{
		NSString *keyName = [m_streamFields objectAtIndex:indexPath.row];
		NSString *val = [m_streamRows objectForKey:keyName];
		[cell setField:keyName withValue:val];
	}
	else if ( kActivitySectionIdx == indexPath.section )
	{
		NSString *keyName = [m_activityFields objectAtIndex:indexPath.row];
		NSString *val = [m_activityRows objectForKey:keyName];
		[cell setField:keyName withValue:val];
	}
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// XXX - perform a custom action based on the section/row
	// XXX - i.e. make a phone call, send an email, view a map, etc.
	
    // Navigation logic may go here. Create and push another view controller.
	// AnotherViewController *anotherViewController = [[AnotherViewController alloc] initWithNibName:@"AnotherView" bundle:nil];
	// [self.navigationController pushViewController:anotherViewController];
	// [anotherViewController release];
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// Return NO if you do not want the specified item to be editable.
	return NO;
}


@end


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
#import "LegislatorHeaderView.h"

@implementation LegislatorViewController

@synthesize m_legislator;


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[m_legislator release];
	[m_keyNames release];
	[super dealloc];
}

- (id) init
{
	if ( self = [super init] )
	{
		self.title = @"Legislator"; // this will be updated later...
		m_infoSelector = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	return self;
}


- (void)setLegislator:(LegislatorContainer *)legislator
{
	[m_legislator release];
	[m_keyNames release];
	
	m_legislator = [legislator retain];
	if ( [[m_legislator title] isEqualToString:@"Sen"] )
	{
		self.title = [[[NSString alloc] initWithFormat:@"%@ Senator",[m_legislator state]] autorelease];
	}
	else 
	{
		self.title = [[[NSString alloc] initWithFormat:@"%@ District %@",[m_legislator state],[m_legislator district]] autorelease];
	}
	
	// setup the table data
	[m_infoSelector removeAllObjects];
	
	if ( [[m_legislator email] length] > 0 )
	{
		[m_infoSelector setObject:[m_legislator email] forKey:@"01_email"];
	}
	
	if ( [[m_legislator phone] length] > 0 )
	{
		[m_infoSelector setObject:[m_legislator phone] forKey:@"02_phone"];
	}
	
	if ( [[m_legislator fax] length] > 0 )
	{
		[m_infoSelector setObject:[m_legislator fax] forKey:@"03_fax"];
	}
	
	if ( [[m_legislator website] length] > 0 )
	{
		[m_infoSelector setObject:[m_legislator website] forKey:@"04_website"];
	}
	
	if ( [[m_legislator congress_office] length] > 0 )
	{
		[m_infoSelector setObject:[m_legislator congress_office] forKey:@"05_office"];
	}
	
	if ( [[m_legislator votesmart_id] length] > 0 )
	{
		[m_infoSelector setObject:[m_legislator votesmart_id] forKey:@"06_votesmart"];
	}
	
	if ( [[m_legislator congresspedia_url] length] > 0 )
	{
		[m_infoSelector setObject:[m_legislator congresspedia_url] forKey:@"07_congresspedia"];
	}
	
	if ( [[m_legislator twitter_id] length] > 0 )
	{
		[m_infoSelector setObject:[m_legislator twitter_id] forKey:@"08_twitter"];
	}
	
	if ( [[m_legislator youtube_url] length] > 0 )
	{
		[m_infoSelector setObject:[m_legislator youtube_url] forKey:@"09_youtube"];
	}
	
	m_keyNames = [[NSArray alloc] initWithArray:[[m_infoSelector allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	
	[self.tableView reloadData];
}


- (void)loadView
{
	m_tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStylePlain];
	m_tableView.delegate = self;
	m_tableView.dataSource = self;
	
	self.view = m_tableView;
	[m_tableView release];
	
	m_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	m_tableView.separatorColor = [UIColor blackColor];
	m_tableView.backgroundColor = [UIColor blackColor];
	
	// XXX - set tableHeaderView to a custom UIView which has legislator
	//       photo, name, major info (party, state, district), add to contacts link
	// m_tableView.tableHeaderView = headerView;
	CGRect hframe = CGRectMake(0,0,320,125);
	LegislatorHeaderView *hview = [[LegislatorHeaderView alloc] initWithFrame:hframe];
	m_tableView.tableHeaderView = hview;
	[hview release];
	
	[hview setLegislator:m_legislator];
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

- (void)viewDidAppear:(BOOL)animated 
{
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
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}



#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	if ( nil ==  m_legislator ) return 0;
	
	return [m_infoSelector count];
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
	NSString *keyName = [m_keyNames objectAtIndex:indexPath.row];
	NSString *val = [m_infoSelector objectForKey:keyName];
	[cell setField:keyName withValue:val];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
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


//
//  LegislatorViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import <AddressBook/AddressBook.h>

#import "LegislatorViewController.h"
#import "LegislatorContainer.h"
#import "LegislatorInfoCell.h"
#import "LegislatorHeaderViewController.h"
#import "CongressionalCommittees.h"
#import "StateAbbreviations.h"

@interface LegislatorViewController (private)
	- (void) deselectRow:(id)sender;
@end


@implementation LegislatorViewController

@synthesize m_legislator;

static const int  kNumTableSections = 4;

static const int  kContactSectionIdx = 0;
static NSString  *kContactHeaderTxt = @" Contact Information";

static const int  kCommitteeSectionIdx = 1;
static NSString * kCommitteeSectionTxt = @" Committee Membership";

static const int  kStreamSectionIdx = 2;
static NSString  *kStreamHeaderTxt = @" Legislator Info Stream";

static const int  kActivitySectionIdx = 3;
static NSString  *kActivityHeaderTxt = @" Recent Activity";


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
	[m_committeeFields release];
	[m_streamFields release];
	[m_activityFields release];
	
	[m_contactRows release];
	[m_committeeRows release];
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
		m_committeeRows = [[NSMutableDictionary alloc] initWithCapacity:10];
		m_streamRows = [[NSMutableDictionary alloc] initWithCapacity:10];
		m_activityRows = [[NSMutableDictionary alloc] initWithCapacity:10];
	}
	return self;
}


- (void)addLegislatorToContacts:(LegislatorContainer *)legislator withImage:(UIImage *)img
{
	ABAddressBookRef ab = ABAddressBookCreate();
	
	// 
	// Query the address book to see if we've aleady added this person
	// 
	{
		NSString *nameStr = [NSString stringWithFormat:@"%@ %@",
										[legislator firstname],
										[legislator lastname]
							 ];
		NSArray *searchResults = (NSArray *)ABAddressBookCopyPeopleWithName( ab, (CFStringRef)nameStr );
		if ( [searchResults count] > 0 )
		{
			// we already have this legislator - use a different ViewController!
			ABPersonViewController *pvc = [[ABPersonViewController alloc] init];
			pvc.addressBook = ab;
			pvc.allowsEditing = YES;
			pvc.personViewDelegate = self;
			pvc.displayedPerson = [searchResults objectAtIndex:0];
			
			CFRelease(ab);
			
			[self.navigationController pushViewController:pvc animated:YES];
			[pvc release];
			return;
		}
	}
	
	ABNewPersonViewController *np = [[ABNewPersonViewController alloc] init];
	np.addressBook = ab;
	np.newPersonViewDelegate = self;
	
	
	ABRecordRef abRecord = ABPersonCreate();
	CFErrorRef abError;
	BOOL success = NO;
	
	// 
	// Address 
	// 
	NSString *azip = nil;
	if ( [[legislator title] isEqualToString:@"Sen"] )
	{
		azip = @"20510";
	}
	else
	{
		azip = @"20515";
	}
	NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] initWithCapacity:6];
	[addressDictionary setObject:[legislator congress_office] forKey:(NSString *)kABPersonAddressStreetKey];
	[addressDictionary setObject:@"Washington" forKey:(NSString *)kABPersonAddressCityKey];
	[addressDictionary setObject:@"DC" forKey:(NSString *)kABPersonAddressStateKey];
	[addressDictionary setObject:azip forKey:(NSString *)kABPersonAddressZIPKey];
	[addressDictionary setObject:@"United States" forKey:(NSString *)kABPersonAddressCountryKey];
	[addressDictionary setObject:@"us" forKey:(NSString *)kABPersonAddressCountryCodeKey];
	
	ABMutableMultiValueRef addrVals = ABMultiValueCreateMutable( kABPersonAddressProperty );
	success = ABMultiValueAddValueAndLabel( addrVals, addressDictionary, kABHomeLabel, NULL );
	ABRecordSetValue( abRecord, kABPersonAddressProperty, addrVals, &abError );
	
	
	CFDataRef imgData = (CFDataRef)UIImageJPEGRepresentation( img, 1.0 );
	success = ABPersonSetImageData( abRecord, imgData, &abError);
	
	// 
	// Personal Info
	// 
	ABRecordSetValue( abRecord, kABPersonPrefixProperty, [legislator title], &abError );
	ABRecordSetValue( abRecord, kABPersonFirstNameProperty, [legislator firstname], &abError );
	ABRecordSetValue( abRecord, kABPersonMiddleNameProperty, [legislator middlename], &abError );
	ABRecordSetValue( abRecord, kABPersonLastNameProperty, [legislator lastname], &abError );
	ABRecordSetValue( abRecord, kABPersonSuffixProperty, [NSString stringWithFormat:@"%@(%@)",
																	([legislator name_suffix] ? [NSString stringWithFormat:@"%@ ",[legislator name_suffix]] : @""),
																	[legislator party]
														 ], &abError );
	ABRecordSetValue( abRecord, kABPersonNicknameProperty, [legislator nickname], &abError );
	
	// 
	// Organization / JobTitle
	// 
	ABRecordSetValue( abRecord, kABPersonOrganizationProperty, CFSTR("United States Congress"), &abError );
	NSString *legTitle = [legislator title];
	NSString *state = [StateAbbreviations nameFromAbbr:[legislator state]];
	NSString *jobTitle = @" ";
	NSString *deptStr = @" ";
	if ( [legTitle isEqualToString:@"Sen"] )
	{
		jobTitle = @"US Senator";
		deptStr = state;
	}
	else if ( [legTitle isEqualToString:@"Rep"] )
	{
		jobTitle = @"US Representative";
		if ( 0 == [[legislator district] integerValue] )
		{
			// At-Large
			deptStr = [NSString stringWithFormat:@"%@ At-Large",state];
		}
		else
		{
			deptStr = [NSString stringWithFormat:@"%@ District %@",state,[legislator district]];
		}
	}
	else if ( [legTitle isEqualToString:@"Del"] )
	{
		jobTitle = @"US Delegate";
		deptStr = [NSString stringWithFormat:@"%@ Delegate",state];
	}
	ABRecordSetValue( abRecord, kABPersonJobTitleProperty, jobTitle, &abError );
	ABRecordSetValue( abRecord, kABPersonDepartmentProperty, deptStr, &abError );
	
	// 
	// email 
	// 
	NSString *email = [legislator email];
	if ( [email length] > 0 )
	{
		ABRecordSetValue( abRecord, kABPersonEmailProperty, email, &abError );
	}
	
	// 
	// Website / misc. URLs
	// 
	ABMutableMultiValueRef websites = ABMultiValueCreateMutable( kABPersonURLProperty );
	success = ABMultiValueAddValueAndLabel( websites, [legislator website], kABPersonHomePageLabel, NULL );
	success = ABMultiValueAddValueAndLabel( websites, [legislator webform], CFSTR("WebForm"), NULL );
	if ( [[legislator youtube_url] length] > 0 )
	{
		success = ABMultiValueAddValueAndLabel( websites, [legislator youtube_url], CFSTR("YouTube"), NULL );
	}
	if ( [[legislator congresspedia_url] length] > 0 )
	{
		success = ABMultiValueAddValueAndLabel( websites, [legislator congresspedia_url], CFSTR("OpenCongress"), NULL );
	}
	if ( [[legislator eventful_id] length] > 0 )
	{
		static NSString *kEventfulBaseURLFmt = @"http://eventful.com/performers/%@";
		NSString *url = [NSString stringWithFormat:kEventfulBaseURLFmt,[legislator eventful_id]];
		success = ABMultiValueAddValueAndLabel( websites, url, CFSTR("Eventful"), NULL );
	}
	ABRecordSetValue( abRecord, kABPersonURLProperty, websites, &abError );
	
	// 
	// Phone Numbers
	//
	ABMutableMultiValueRef phoneNums = ABMultiValueCreateMutable( kABPersonPhoneProperty );
	success = ABMultiValueAddValueAndLabel( phoneNums, [legislator phone], kABPersonPhoneMainLabel, NULL );
	success = ABMultiValueAddValueAndLabel( phoneNums, [legislator fax], kABPersonPhoneWorkFAXLabel, NULL );
	ABRecordSetValue( abRecord, kABPersonPhoneProperty, phoneNums, &abError );
		
	np.displayedPerson = abRecord;
	
	[self.navigationController pushViewController:np animated:YES];
	[np release];
	CFRelease(abRecord);
	CFRelease(ab);
}


- (void)setLegislator:(LegislatorContainer *)legislator
{
	[m_legislator release];
	[m_contactFields release];
	[m_streamFields release];
	[m_activityFields release];
	
	
	m_legislator = [legislator retain];
	
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
	
	if ( [[m_legislator webform] length] > 0 )
	{
		[m_contactRows setObject:[m_legislator webform] forKey:@"04_webform"];
	}
	
	if ( [[m_legislator website] length] > 0 )
	{
		[m_contactRows setObject:[m_legislator website] forKey:@"05_website"];
	}
	
	if ( [[m_legislator congress_office] length] > 0 )
	{
		NSString *zip;
		if ( [[m_legislator title] isEqualToString:@"Sen"] )
		{
			zip = @"Washington, DC 20510";
		}
		else
		{
			zip = @"Washington, DC 20515";
		}
		NSString * office = [NSString stringWithFormat:@"%@\n%@",[m_legislator congress_office],zip];
		[m_contactRows setObject:office forKey:@"05_office"];
	}
	
	m_contactFields = [[NSArray alloc] initWithArray:[[m_contactRows allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	
	
	// Committee Membership Section --------------
	[m_committeeRows removeAllObjects];
	
	NSArray *comData = [m_legislator committee_data];
	if ( nil != comData )
	{
		// XXX - fill this in!
		//[m_committeeRows setObject:[NSString stringWithString:@""] forKey:@"S111"];
		NSEnumerator *comEnum = [comData objectEnumerator];
		id obj;
		while (obj = [comEnum nextObject]) 
		{
			LegislativeCommittee *committee = (LegislativeCommittee *)obj;
			NSString *cID = [NSString stringWithFormat:@"%@_%@",
										committee.m_id,
										(nil == committee.m_parentCommittee ? 
											@"" : 
											[NSString stringWithFormat:@"[%@]",committee.m_parentCommittee]
										)
							];
			NSString *cNM = [NSString stringWithFormat:@"%@\n%@",
										(nil == committee.m_parentCommittee ? committee.m_id : @""),
										committee.m_name
							];
			
			[m_committeeRows setObject:cNM forKey:cID];
		}
		
		m_committeeFields = [[NSArray alloc] initWithArray:[[m_committeeRows allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	}
	
	
	// Stream Section --------------
	[m_streamRows removeAllObjects];
	
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
		[m_streamRows setObject:[m_legislator congresspedia_url] forKey:@"04_O.C."];
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
	CGRect hframe = CGRectMake(0,0,320,150);
	m_headerViewCtrl = [[LegislatorHeaderViewController alloc] initWithNibName:@"LegislatorHeaderView" bundle:nil ];
	[m_headerViewCtrl.view setFrame:hframe];
	[m_headerViewCtrl setLegislator:m_legislator];
	[m_headerViewCtrl setNavController:self];
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


#pragma mark LegislatorViewController Private


- (void) deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same legislator)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
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
	else if ( kCommitteeSectionIdx == section )
	{
		return [m_committeeRows count];
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
	
	if ( kContactSectionIdx == section )
	{
		[sectionLabel setText:kContactHeaderTxt];
	}
	else if ( kCommitteeSectionIdx == section )
	{
		[sectionLabel setText:kCommitteeSectionTxt];
	}
	else if ( kStreamSectionIdx == section )
	{
		[sectionLabel setText:kStreamHeaderTxt];
	}
	else if ( kActivitySectionIdx == section )
	{
		[sectionLabel setText:kActivityHeaderTxt];
	}
	
	return sectionLabel;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	NSString *keyName = nil;
	NSString *val = nil;
	if ( kContactSectionIdx == indexPath.section )
	{
		keyName = [m_contactFields objectAtIndex:indexPath.row];
		val = [m_contactRows objectForKey:keyName];
	}
	else if ( kCommitteeSectionIdx == indexPath.section )
	{
		keyName = [m_committeeFields objectAtIndex:indexPath.row];
		val = [m_committeeRows objectForKey:keyName];
	}
	else if ( kStreamSectionIdx == indexPath.section )
	{
		keyName = [m_streamFields objectAtIndex:indexPath.row];
		val = [m_streamRows objectForKey:keyName];
	}
	else if ( kActivitySectionIdx == indexPath.section )
	{
		keyName = [m_activityFields objectAtIndex:indexPath.row];
		val = [m_activityRows objectForKey:keyName];
	}
	
	CGFloat cellSz = [LegislatorInfoCell cellHeightForText:val];
	
	return cellSz;
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
	NSString *keyName;
	NSString *val;
	if ( kContactSectionIdx == indexPath.section )
	{
		keyName = [m_contactFields objectAtIndex:indexPath.row];
		val = [m_contactRows objectForKey:keyName];
		[cell setField:keyName withValue:val];
	}
	else if ( kCommitteeSectionIdx == indexPath.section )
	{
		keyName = [m_committeeFields objectAtIndex:indexPath.row];
		val = [m_committeeRows objectForKey:keyName];
		[cell setField:keyName withValue:val];
	}
	else if ( kStreamSectionIdx == indexPath.section )
	{
		keyName = [m_streamFields objectAtIndex:indexPath.row];
		val = [m_streamRows objectForKey:keyName];
		[cell setField:keyName withValue:val];
	}
	else if ( kActivitySectionIdx == indexPath.section )
	{
		keyName = [m_activityFields objectAtIndex:indexPath.row];
		val = [m_activityRows objectForKey:keyName];
		[cell setField:keyName withValue:val];
	}
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// XXX - perform a custom action based on the section/row
	// XXX - i.e. make a phone call, send an email, view a map, etc.
	
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
	
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


#pragma mark ABNewPersonViewControllerDelegate methods


- (void)newPersonViewController:(ABNewPersonViewController *)newPersonViewController didCompleteWithNewPerson:(ABRecordRef)person
{
	[self.navigationController popViewControllerAnimated:YES];
}


- (BOOL)personViewController:(ABPersonViewController *)personViewController shouldPerformDefaultActionForPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifierForValue
{
	return YES;
}


@end


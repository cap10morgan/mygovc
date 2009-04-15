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
#import "LegislatorInfoData.h"
#import "LegislatorHeaderViewController.h"
#import "CongressionalCommittees.h"
#import "StateAbbreviations.h"

@interface LegislatorViewController (private)
	- (void) deselectRow:(id)sender;
@end


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
	[m_headerViewCtrl release];
	
	[m_data release];
	
	[super dealloc];
}

- (id) init
{
	if ( self = [super init] )
	{
		self.title = @"Legislator"; // this will be updated later...
		m_data = nil;
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
	if ( [[legislator eventful_url] length] > 0 )
	{
		success = ABMultiValueAddValueAndLabel( websites, [legislator eventful_url], CFSTR("Eventful"), NULL );
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
	m_legislator = [legislator retain];
	
	m_data = [[LegislatorInfoData alloc] init];
	[m_data setLegislator:m_legislator];
	
	// 
	// setup the table data
	//
/*
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
*/
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
	return YES;
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
	return [m_data numberOfSections];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	
	if ( nil ==  m_legislator ) return 0;
	
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
	static NSString *CellIdentifier = @"LegInfoCell";

	LegislatorInfoCell *cell = (LegislatorInfoCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (cell == nil) 
	{
		cell = [[[LegislatorInfoCell alloc] initWithFrame:CGRectZero reuseIdentifier:CellIdentifier] autorelease];
	}
	
	// Set up the cell...
	[m_data setInfoCell:cell forIndex:indexPath];
	
	return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// XXX - perform a custom action based on the section/row
	// XXX - i.e. make a phone call, send an email, view a map, etc.
	[m_data performActionForIndex:indexPath withParent:self];
	
	[self performSelector:@selector(deselectRow:) withObject:nil afterDelay:0.5f];
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


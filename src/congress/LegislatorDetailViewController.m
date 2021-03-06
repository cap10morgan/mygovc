/*
 File: LegislatorDetailViewController.m
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
#import "myGovAppDelegate.h"

#import <AddressBook/AddressBook.h>

#import "ComposeMessageViewController.h"
#import "CustomTableCell.h"
#import "LegislatorDetailViewController.h"
#import "LegislatorContainer.h"
#import "LegislatorInfoData.h"
#import "LegislatorHeaderViewController.h"
#import "CongressionalCommittees.h"
#import "StateAbbreviations.h"

@interface LegislatorDetailViewController (private)
	- (void)deselectRow:(id)sender;
	- (void)dataCallback:(NSString *)msg;
	- (void)composeNewCommunityItem;
@end


@implementation LegislatorDetailViewController

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
	NSString *tmp = nil;
	NSMutableDictionary *addressDictionary = [[NSMutableDictionary alloc] initWithCapacity:6];
	tmp = [[NSString alloc] initWithString:[legislator congress_office_noStateOrZip]];
	[addressDictionary setObject:tmp forKey:(NSString *)kABPersonAddressStreetKey];
	[tmp release]; tmp = nil;
	
	[addressDictionary setObject:@"Washington" forKey:(NSString *)kABPersonAddressCityKey];
	[addressDictionary setObject:@"DC" forKey:(NSString *)kABPersonAddressStateKey];
	
	tmp = [[NSString alloc] initWithString:azip];
	[addressDictionary setObject:tmp forKey:(NSString *)kABPersonAddressZIPKey];
	[tmp release]; tmp = nil;
	
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
	tmp = [[NSString alloc] initWithString:[legislator title]];
	ABRecordSetValue( abRecord, kABPersonPrefixProperty, tmp, &abError ); [tmp release]; tmp = nil;
	
	tmp = [[NSString alloc] initWithString:[legislator firstname]];
	ABRecordSetValue( abRecord, kABPersonFirstNameProperty, tmp, &abError ); [tmp release]; tmp = nil;
	
	tmp = [[NSString alloc] initWithString:[legislator middlename]];
	ABRecordSetValue( abRecord, kABPersonMiddleNameProperty, tmp, &abError ); [tmp release]; tmp = nil;
	
	tmp = [[NSString alloc] initWithString:[legislator lastname]];
	ABRecordSetValue( abRecord, kABPersonLastNameProperty, tmp, &abError ); [tmp release]; tmp = nil;
	
	tmp = [[NSString alloc] initWithFormat:@"%@(%@)",
								([legislator name_suffix] ? [NSString stringWithFormat:@"%@ ",[legislator name_suffix]] : @""),
								[legislator party]
		   ];
	ABRecordSetValue( abRecord, kABPersonSuffixProperty, tmp, &abError ); [tmp release]; tmp = nil;
	
	tmp = [[NSString alloc] initWithString:[legislator nickname]];
	ABRecordSetValue( abRecord, kABPersonNicknameProperty, tmp, &abError ); [tmp release]; tmp = nil;
	
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
	tmp = [[NSString alloc] initWithString:jobTitle];
	ABRecordSetValue( abRecord, kABPersonJobTitleProperty, tmp, &abError ); [tmp release]; tmp = nil;
	
	tmp = [[NSString alloc] initWithString:deptStr];
	ABRecordSetValue( abRecord, kABPersonDepartmentProperty, tmp, &abError ); [tmp release]; tmp = nil;
	
	// 
	// email 
	// 
	NSString *email = [legislator email];
	if ( [email length] > 0 )
	{
		ABMutableMultiValueRef emailList = ABMultiValueCreateMutable( kABPersonEmailProperty );
		tmp = [[NSString alloc] initWithString:email];
		success = ABMultiValueAddValueAndLabel( emailList, tmp, CFSTR("Work"), NULL ); [tmp release]; tmp = nil;
		
		ABRecordSetValue( abRecord, kABPersonEmailProperty, emailList, &abError );
	}
	
	// 
	// Website / misc. URLs
	// 
	ABMutableMultiValueRef websites = ABMultiValueCreateMutable( kABPersonURLProperty );
	tmp = [[NSString alloc] initWithString:[legislator website]];
	success = ABMultiValueAddValueAndLabel( websites, tmp, kABPersonHomePageLabel, NULL ); [tmp release]; tmp = nil;
	
	tmp = [[NSString alloc] initWithString:[legislator webform]];
	success = ABMultiValueAddValueAndLabel( websites, tmp, CFSTR("WebForm"), NULL ); [tmp release]; tmp = nil;
	if ( [[legislator youtube_url] length] > 0 )
	{
		tmp = [[NSString alloc] initWithString:[legislator youtube_url]];
		success = ABMultiValueAddValueAndLabel( websites, tmp, CFSTR("YouTube"), NULL ); [tmp release]; tmp = nil;
	}
	if ( [[legislator congresspedia_url] length] > 0 )
	{
		tmp = [[NSString alloc] initWithString:[legislator congresspedia_url]];
		success = ABMultiValueAddValueAndLabel( websites, tmp, CFSTR("OpenCongress"), NULL ); [tmp release]; tmp = nil;
	}
	if ( [[legislator eventful_url] length] > 0 )
	{
		tmp = [[NSString alloc] initWithString:[legislator eventful_url]];
		success = ABMultiValueAddValueAndLabel( websites, tmp, CFSTR("Eventful"), NULL ); [tmp release]; tmp = nil;
	}
	ABRecordSetValue( abRecord, kABPersonURLProperty, websites, &abError );
	
	// 
	// Phone Numbers
	//
	ABMutableMultiValueRef phoneNums = ABMultiValueCreateMutable( kABPersonPhoneProperty );
	tmp = [[NSString alloc] initWithString:[legislator phone]];
	success = ABMultiValueAddValueAndLabel( phoneNums, tmp, kABPersonPhoneMainLabel, NULL ); [tmp release]; tmp = nil;
	
	tmp = [[NSString alloc] initWithString:[legislator fax]];
	success = ABMultiValueAddValueAndLabel( phoneNums, tmp, kABPersonPhoneWorkFAXLabel, NULL ); [tmp release]; tmp = nil;
	ABRecordSetValue( abRecord, kABPersonPhoneProperty, phoneNums, &abError );
	
	np.displayedPerson = abRecord;
	np.hidesBottomBarWhenPushed = YES;
	
	[self.navigationController pushViewController:np animated:YES];
	[np release];
	CFRelease(abRecord);
	CFRelease(ab);
}


- (void)setLegislator:(LegislatorContainer *)legislator
{
	[m_legislator release];
	m_legislator = [legislator retain];
	
	if ( nil == m_data )
	{
		m_data = [[LegislatorInfoData alloc] init];
	}
	[m_headerViewCtrl setLegislator:legislator];
	
	[m_data setNotifyTarget:self andSelector:@selector(dataCallback:)];
	[m_data setLegislator:m_legislator];
	
	[self.tableView reloadData];
}


- (void)loadView
{
	self.tableView = [[UITableView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame] style:UITableViewStyleGrouped];
	self.tableView.delegate = self;
	self.tableView.dataSource = self;
	
	self.view = self.tableView;
	
	//m_tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	self.tableView.separatorColor = [UIColor blackColor];
	self.tableView.backgroundColor = [UIColor blackColor];
	
	// 
	// Add a "new" button which will add either a 
	// new piece of chatter, or a new event depending on the 
	// currently selected view!
	// 
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
											  initWithBarButtonSystemItem:UIBarButtonSystemItemCompose 
											  target:self 
											  action:@selector(composeNewCommunityItem)];
	
	// set tableHeaderView to a custom UIView which has legislator
	//       photo, name, major info (party, state, district), add to contacts link
	CGRect hframe = CGRectMake(0,0,320,150);
	m_headerViewCtrl = [[LegislatorHeaderViewController alloc] initWithNibName:@"LegislatorHeaderView" bundle:nil ];
	[m_headerViewCtrl.view setFrame:hframe];
	[m_headerViewCtrl setLegislator:m_legislator];
	[m_headerViewCtrl setNavController:self];
	self.tableView.tableHeaderView = m_headerViewCtrl.view;
	self.tableView.tableHeaderView.userInteractionEnabled = YES;
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


- (void)viewWillDisappear:(BOOL)animated 
{
	[super viewWillDisappear:animated];
	
	[m_data stopAnyWebActivity];
}

/*
- (void)viewDidDisappear:(BOOL)animated 
{
	[super viewDidDisappear:animated];
}
*/


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	MYGOV_SHOULD_SUPPORT_ROTATION(toInterfaceOrientation);
}


- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	[self.tableView reloadData];
}


#pragma mark LegislatorDetailViewController Private


- (void)deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same legislator)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


- (void)dataCallback:(NSString *)msg
{
	NSRange msgTypeRange = {0, 5};
	if ( NSOrderedSame == [msg compare:@"ERROR" options:NSCaseInsensitiveSearch range:msgTypeRange] )
	{
		// XXX - notify the user of an error?
	}
	else
	{
		[self.tableView reloadData];
	}
}

- (void)composeNewCommunityItem
{
	// create a new feedback item!
	MessageData *msg = [[MessageData alloc] init];
	msg.m_transport = eMT_MyGov;
	msg.m_to = @"MyGovernment Community";
	msg.m_body = @" ";
	msg.m_subject = [NSString stringWithFormat:@"%@:",[m_legislator shortName]];
	msg.m_appURL = [NSURL URLWithString:[NSString stringWithFormat:@"mygov://congress/%@",[m_legislator bioguide_id]]];
	msg.m_appURLTitle = [m_legislator shortName];
	if ( [[m_legislator website] length] > 0 )
	{
		msg.m_webURL = [NSURL URLWithString:[m_legislator website]];
		msg.m_webURLTitle = @"Website";
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
	
	if ( nil ==  m_legislator ) return 0;
	
	return [m_data numberOfRowsInSection:section];
}



- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 35.0f;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	CGRect lblFrame = CGRectMake(0.0f, 0.0f, CGRectGetWidth([tableView frame]), 40.0f);
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


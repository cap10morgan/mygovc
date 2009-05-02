//
//  CommunityDetailViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import "myGovAppDelegate.h"
#import "CDetailHeaderViewController.h"
#import "CommunityDetailData.h"
#import "CommunityDetailViewController.h"
#import "CommunityItem.h"
#import "ComposeMessageViewController.h"
#import "CustomTableCell.h"
#import "MyGovUserData.h"
#import "TableDataManager.h"

@interface CommunityDetailViewController (private)
	- (void)deselectRow:(id)sender;
	- (CGFloat)heightForFeedbackText;
	- (void)addItemComment;
	- (void)useWantsToAttend;
	- (void)attendCurrentEvent;
	- (void)addCurrentEventToCalendar;
@end


@implementation CommunityDetailViewController

@synthesize m_item;


enum
{
	eCDV_AlertShouldAttend  = 1,
	eCDV_AlertAddToCalendar = 2,
};


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[m_item release];
	
	[m_data release];
	
	[super dealloc];
}


- (id) init
{
	if ( self = [super init] )
	{
		self.title = @"Community Item"; // this will be updated later...
		m_item = nil;
		m_data = nil;
		m_alertSheetUsed = eCDV_AlertShouldAttend;
	}
	return self;
}


- (void)setItem:(CommunityItem *)item
{
	[m_item release];
	m_item = [item retain];
	
	if ( nil == m_data )
	{
		m_data = [[CommunityDetailData alloc] init];
	}
	[m_data setItem:m_item];
	
	switch ( m_item.m_type )
	{
		case eCommunity_Event:
		{
			self.title = @"Event";
		}
			break;
		
		case eCommunity_Chatter:
		{
			MyGovUserData *mgud = [myGovAppDelegate sharedUserData];
			MyGovUser *user = [mgud userFromID:m_item.m_creator];
			NSString *uname;
			if ( nil == user || nil == user.m_username )
			{
				uname = @"??";
			}
			else
			{
				uname = user.m_username;
			}
			self.title = [NSString stringWithFormat:@"%@ says...",uname];
		}
			break;
	}
	
	UILabel *titleView = [[[UILabel alloc] initWithFrame:CGRectMake(0,0,240,32)] autorelease];
	titleView.backgroundColor = [UIColor clearColor];
	titleView.textColor = [UIColor whiteColor];
	titleView.font = [UIFont boldSystemFontOfSize:18.0f];
	titleView.textAlignment = UITextAlignmentCenter;
	titleView.adjustsFontSizeToFitWidth = YES;
	titleView.text = self.title;
	self.navigationItem.titleView = titleView;
	
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
	
	
	if ( eCommunity_Event == [m_item m_type] )
	{
		// 
		// XXX - check to see if the user is already attending!!
		// 
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
													  initWithTitle:@"I'm Coming!"
													  style:UIBarButtonItemStyleDone
													  target:self 
													  action:@selector(useWantsToAttend)];
	}
	else
	{
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
												  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
												  target:self 
												  action:@selector(addItemComment)];
	}
	
	// 
	// The header view loads up the user / event / chatter image
	// and holds a title, and URL links
	CGRect hframe = CGRectMake(0,0,320,165);
	CDetailHeaderViewController *hdrViewCtrl;
	hdrViewCtrl = [[CDetailHeaderViewController alloc] initWithNibName:@"CDetailHeaderView" bundle:nil ];
	[hdrViewCtrl.view setFrame:hframe];
	[hdrViewCtrl setItem:m_item];
	self.tableView.tableHeaderView = hdrViewCtrl.view;
	self.tableView.tableHeaderView.userInteractionEnabled = YES;
	
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


#pragma mark CommunityDetailViewController Private


- (void)deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same legislator)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}


- (CGFloat)heightForFeedbackText
{
	NSString *txt = m_item.m_text;
	
	CGSize txtSz = [txt sizeWithFont:[UIFont systemFontOfSize:16.0f] 
					constrainedToSize:CGSizeMake(300.0f,280.0f) 
						lineBreakMode:UILineBreakModeWordWrap];
	
	return txtSz.height + 14.0f; // with some padding...
}


- (void)addItemComment
{
	// create a new feedback item!
	MessageData *msg = [[MessageData alloc] init];
	msg.m_transport = eMT_MyGovUserComment;
	msg.m_to = @"MyGovernment Community";
	msg.m_subject = [NSString stringWithFormat:@"Re: %@",m_item.m_title];
	msg.m_body = @" ";
	msg.m_appURL = m_item.m_mygovURL;
	msg.m_appURLTitle = m_item.m_mygovURLTitle;
	msg.m_webURL = m_item.m_webURL;
	msg.m_webURLTitle = m_item.m_webURLTitle;
	msg.m_communityThreadID = m_item.m_id;
	
	// display the message composer
	ComposeMessageViewController *cmvc = [ComposeMessageViewController sharedComposer];
	[cmvc display:msg fromParent:self];
}


- (void)useWantsToAttend
{
	
	UIAlertView *alert = [[UIAlertView alloc] 
								initWithTitle:[NSString stringWithFormat:@"Do you plan on attending %@?",[m_item m_title]]
									  message:@""
									 delegate:self
							cancelButtonTitle:@"No"
							otherButtonTitles:@"Yes",nil];
	
	m_alertSheetUsed = eCDV_AlertShouldAttend;
	[alert show];
}


- (void)attendCurrentEvent
{
	// XXX - 
	// XXX - actually mark the current user as attending this event!
	// XXX - 
	
	UIAlertView *alert = [[UIAlertView alloc] 
						  initWithTitle:[NSString stringWithFormat:@"Would you like to add %@ to your calendar?",[m_item m_title]]
						  message:@""
						  delegate:self
						  cancelButtonTitle:@"No"
						  otherButtonTitles:@"Yes",nil];
	
	m_alertSheetUsed = eCDV_AlertAddToCalendar;
	[alert show];
}


- (void)addCurrentEventToCalendar
{
	// XXX - 
	// XXX - add the current event to a user's calendar!
	// XXX - 
	
}


#pragma mark UIAlertViewDelegate Methods


- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
	if ( eCDV_AlertAddToCalendar == m_alertSheetUsed )
	{
		switch ( buttonIndex )
		{
			default:
			case 0: // no action
				break;
				
			case 1: // add the current event to the user's calendar!
				[self addCurrentEventToCalendar];
				break;
		}
	}
	else if ( eCDV_AlertShouldAttend == m_alertSheetUsed )
	{
		switch ( buttonIndex )
		{
			default:
			case 0: // doesn't want to attent...
				break;
			
			case 1: // wants to attend!
				[self attendCurrentEvent];
				break;
		}
	}
}


#pragma mark Table view methods


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return [m_data numberOfSections];
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	
	if ( nil ==  m_item ) return 0;
	
	return [m_data numberOfRowsInSection:section];
}



- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	if ( 0 == section )
	{
		if ( eCommunity_Chatter == m_item.m_type )
		{
			return [self heightForFeedbackText];
		}
		else
		{
			return 0.0f;
		}
	}
	else
	{
		return 35.0f;
	}
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	CGRect lblFrame = CGRectMake(0.0f, 0.0f, 320.0f, 40.0f);
	UILabel *sectionLabel = [[[UILabel alloc] initWithFrame:lblFrame] autorelease];
	
	NSString *lblText = [m_data titleForSection:section];
	
	if ( 0 == section )
	{
		if ( eCommunity_Chatter == m_item.m_type )
		{
			lblText = m_item.m_text;
		}
		
		sectionLabel.backgroundColor = [UIColor clearColor];
		sectionLabel.textColor = [UIColor grayColor];
		sectionLabel.font = [UIFont systemFontOfSize:16.0f];
		sectionLabel.textAlignment = UITextAlignmentCenter;
		sectionLabel.lineBreakMode = UILineBreakModeWordWrap;
		sectionLabel.numberOfLines = 0;
		
		// adjust frame to fit _all_ of the text :-)
		CGFloat cellHeight = [self heightForFeedbackText];
		[sectionLabel setFrame:CGRectMake( 10.0f, 0.0f, 300.0f, cellHeight )];
	}
	else
	{
		sectionLabel.backgroundColor = [UIColor clearColor];
		sectionLabel.textColor = [UIColor whiteColor];
		sectionLabel.font = [UIFont boldSystemFontOfSize:18.0f];
		sectionLabel.textAlignment = UITextAlignmentLeft;
		sectionLabel.adjustsFontSizeToFitWidth = YES;
	}
	
	[sectionLabel setText:lblText];
	
	return sectionLabel;
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return [m_data heightForDataAtIndexPath:indexPath];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath 
{
	static NSString *CellIdentifier = @"CommunityDetailCell";
	
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


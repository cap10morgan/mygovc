/*
 File: CommunityDetailViewController.m
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
#import "CDetailHeaderViewController.h"
#import "CommunityDataManager.h"
#import "CommunityDetailData.h"
#import "CommunityDetailViewController.h"
#import "CommunityItem.h"
#import "ComposeMessageViewController.h"
#import "CustomTableCell.h"
#import "MiniBrowserController.h"
#import "MyGovUserData.h"
#import "TableDataManager.h"

#define COMMENT_HTML_HDR  @" \
<html> \
	<head> \
		<title>User Comments!</title> \
		<meta name=\"viewport\" content=\"300, initial-scale=1.0\"> \
		<script type=\"text/javascript\"> \
			function endcommenttouch(e) { \
				e.preventDefault(); \
				var ypos = window.pageYOffset; \
				document.location='http://touchend/'+ypos; \
			} \
			function hookTouchEvents() { \
				document.addEventListener(\"touchend\", endcommenttouch, true); \
			} \
			function scrollToBottom() { \
				window.scrollTop = window.scrollHeight; \
			} \
			function scrollCommentsTo(x,y) { \
				window.scrollTo(x,y); \
			} \
		</script> \
		<style> \
		a { \
			color: #cfc; \
			text-decoration: none; \
			font-weight: bold; \
		} \
		img.avatar { \
			border: 0px; \
			margin-right: 7px; \
			margin-bottom: 2px; \
			margin-left: 4px; \
			float: left; \
			width: 38px; \
			height: 38px \
		} \
		div.comment { \
			font-size: 1em; \
			float: left; \
			border-left: 5px solid #889; \
			margin-top: 0.7em; \
			margin-right: 0.1em; \
			margin-left: 0.5em; \
			margin-bottom: 1em; \
			padding-left: 0.5em; \
		} \
		div.header { \
			border-top: 2px solid #444; \
			padding-top: 0.2em; \
			font-size: 1.2em; \
			clear: both; \
		} \
		div.subtitle { \
			font-size: 0.8em; \
			margin-top: 0.1em; \
			margin-left: 0.5em; \
			margin-right: 0.5em; \
			padding: 0.1em; \
			color: #ff4; \
			clear: both; \
		} \
		</style> \
	</head> \
	<body style=\"background: #000; color: #fff\"> \
"

#define COMMENT_HTML_FMT @" \
		<div class=\"header\">%@</div> \
		<div class=\"subtitle\">%@</div> \
		<div class=\"comment\"><img class=\"avatar\" src=\"%@\" />%@</div> \
"

#define COMMENT_HTML_END @" \
	</body> \
</html> \
"

static const CGFloat HEADER_WIDTH = 320.0f;
static const CGFloat HEADER_HEIGHT = 165.0f;
static const CGFloat CONTENT_STARTX = 10.0f;
static const CGFloat CONTENT_WIDTH = 300.0f;
static const CGFloat COMMENT_TXT_HEIGHT = 40.0f;
static const CGFloat COMMENT_TXT_MAXHEIGHT = 800.0f;
static const CGFloat COMMENT_WEBVIEW_HEIGHT = 360.0f;
static const CGFloat EMPTY_WEBVIEW_HEIGHT = 25.0f;

#define COMMENT_TXT_FONT [UIFont systemFontOfSize:16.0f]
#define COMMENT_TXT_COLOR [UIColor colorWithRed:0.56f green:0.56f blue:1.0f alpha:1.0f]


@interface CommunityDetailViewController (private)
	- (void)reloadItemData;
	- (NSString *)formatItemComments;
	- (CGFloat)heightForFeedbackText;
	- (void)addItemComment;
	- (void)userWantsToAttend;
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
	[m_hdrViewCtrl release];
	[m_itemLabel release];
	[m_webView release];
	[m_item release];
	
	[super dealloc];
}


- (id) init
{
	if ( self = [super init] )
	{
		self.title = @"Community Item"; // this will be updated later...
		m_item = nil;
		m_webView = nil;
		m_itemLabel = nil;
		m_alertSheetUsed = eCDV_AlertShouldAttend;
	}
	return self;
}


- (void)setItem:(CommunityItem *)item
{
	[m_item release];
	m_item = [item retain];
	m_item.m_uiStatus = eCommunityItem_Old;
	
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
			MyGovUser *user = [mgud userFromUsername:m_item.m_creator];
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
	titleView.font = [UIFont boldSystemFontOfSize:16.0f];
	titleView.textAlignment = UITextAlignmentCenter;
	titleView.adjustsFontSizeToFitWidth = YES;
	titleView.text = self.title;
	self.navigationItem.titleView = titleView;
	
	[self reloadItemData];
}


- (void)updateItem
{
	// grab a (possibly) new/update CommunityItem from
	// the shared data manager and update our GUI
	CommunityItem *newItem = [[myGovAppDelegate sharedCommunityData] itemWithId:[m_item m_id]];
	if ( nil != newItem )
	{
		[self setItem:newItem];
		// javascript scroll to bottom of UIWebView!
		[m_webView stringByEvaluatingJavaScriptFromString:@"scrollToBottom();"];
	}
}


- (void)loadView
{
	if ( eCommunity_Event == [m_item m_type] )
	{
		// 
		// XXX - check to see if the user is already attending!!
		// 
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
													  initWithTitle:@"I'm Coming!"
													  style:UIBarButtonItemStyleDone
													  target:self 
													  action:@selector(userWantsToAttend)];
	}
	else
	{
		self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] 
												  initWithBarButtonSystemItem:UIBarButtonSystemItemAdd 
												  target:self 
												  action:@selector(addItemComment)];
	}

	UIScrollView *myView = [[UIScrollView alloc] initWithFrame:CGRectMake(0,0,
																		  HEADER_WIDTH,
																		  HEADER_HEIGHT + COMMENT_TXT_HEIGHT + COMMENT_WEBVIEW_HEIGHT)];
	myView.userInteractionEnabled = YES;
	[myView setDelegate:self];
	
	// 
	// The header view loads up the user / event / chatter image
	// and holds a title, and URL links
	CGRect hframe = CGRectMake(0,0,CONTENT_WIDTH,HEADER_HEIGHT);
	m_hdrViewCtrl = [[CDetailHeaderViewController alloc] initWithNibName:@"CDetailHeaderView" bundle:nil ];
	[m_hdrViewCtrl.view setFrame:hframe];
	[m_hdrViewCtrl.view setUserInteractionEnabled:YES];
	[m_hdrViewCtrl setItem:m_item];
	[myView addSubview:m_hdrViewCtrl.view];
	
	m_itemLabel = [[UILabel alloc] initWithFrame:CGRectMake(CONTENT_STARTX,
															HEADER_HEIGHT,
															CONTENT_WIDTH,
															COMMENT_TXT_HEIGHT)];
	m_itemLabel.backgroundColor = [UIColor clearColor];
	m_itemLabel.textColor = COMMENT_TXT_COLOR;
	m_itemLabel.font = COMMENT_TXT_FONT;
	m_itemLabel.textAlignment = UITextAlignmentLeft;
	m_itemLabel.lineBreakMode = UILineBreakModeWordWrap;
	m_itemLabel.numberOfLines = 0;
	[myView addSubview:m_itemLabel];
	
	m_webView = [[UIWebView alloc] initWithFrame:CGRectMake(CONTENT_STARTX,
															HEADER_HEIGHT + COMMENT_TXT_HEIGHT,
															CONTENT_WIDTH,
															EMPTY_WEBVIEW_HEIGHT)];
	m_webView.backgroundColor = [UIColor clearColor];
	m_webView.dataDetectorTypes = UIDataDetectorTypeAll;
	[m_webView setDelegate:self];
	m_webView.userInteractionEnabled = YES;
	
	// HACK alert: try to prevent rubberbanding in the UIWebView
	id maybeAScrollView = [[m_webView subviews] objectAtIndex:0];
	if ( [maybeAScrollView respondsToSelector:@selector(setAllowsRubberBanding:)] )
	{
		[maybeAScrollView performSelector:@selector(setAllowsRubberBanding:) withObject:(id)(NO)];
	}
	
	[myView addSubview:m_webView];
	
	myView.backgroundColor = [UIColor blackColor];
	self.view = myView;
	[myView release];
	
	[self reloadItemData];
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


#pragma mark UIScrollViewDelegate methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	CGPoint ofst = scrollView.contentOffset;
	if ( ofst.y > m_webView.frame.origin.y )
	{
		[scrollView setScrollEnabled:NO];
		
		// XXX - call javascript function to scroll webview by 
		//       difference: (ofst.y - m_webView.frame.origin.y) for 
		//       more smooth scrolling...
		NSString *scrollJavaScript = [NSString stringWithFormat:@"scrollCommentsTo(0,%d);",(ofst.y - m_webView.frame.origin.y)];
		[m_webView stringByEvaluatingJavaScriptFromString:scrollJavaScript];
		
		[scrollView setContentOffset:CGPointMake(0,m_webView.frame.origin.y) animated:YES];
	}
}

#pragma mark UIWebViewDelegate methods

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request 
									 navigationType:(UIWebViewNavigationType)navigationType
{
	if ( [request.URL.host isEqualToString:@"touchend"] )
	{
		NSInteger ypos = [[[request.URL relativePath] lastPathComponent] integerValue];
		if ( ypos <= 0 )
		{
			UIScrollView *sv = (UIScrollView *)(self.view);
			[sv setScrollEnabled:YES];
			[sv setContentOffset:CGPointMake(0,m_webView.frame.origin.y-15) animated:YES];
		}
		return NO;
	}
	else if ( [request.URL.absoluteString isEqualToString:@"about:blank"] )
	{
		return YES;
	}
	else if ( ([request.URL.absoluteString length] >= 7) && 
			  (NSOrderedSame == [request.URL.absoluteString compare:@"mailto:" options:NSCaseInsensitiveSearch range:(NSRange){0,7}]) 
			 )
	{
		// XXX - handle mailto links!
		return NO;
	}
	else 
	{
		// intercept link clicking and open our MiniBrowser!
		MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:request.URL];
		[mbc display:[[myGovAppDelegate sharedAppDelegate] topViewController]];
		return NO;
	}
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[webView stringByEvaluatingJavaScriptFromString:@"hookTouchEvents();"];
}


#pragma mark CommunityDetailViewController Private

/*
- (void)deselectRow:(id)sender
{
	// de-select the currently selected row
	// (so the user can go back to the same legislator)
	[self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}
*/


- (void)reloadItemData
{
	if ( nil == m_item ) return;

	CGFloat pos = HEADER_HEIGHT;
	
	// adjust frame to fit _all_ of the text :-)
	CGFloat commentTxtHeight = [self heightForFeedbackText];
	[m_itemLabel setFrame:CGRectMake( CONTENT_STARTX, pos, CONTENT_WIDTH, commentTxtHeight )];
	m_itemLabel.text = m_item.m_text;
	
	pos += commentTxtHeight;
	
	// resize the comment view and reload it's data
	[m_webView setFrame:CGRectMake( CONTENT_STARTX, pos, CONTENT_WIDTH, COMMENT_WEBVIEW_HEIGHT)];
	
	NSString *htmlStr = [self formatItemComments];
	[m_webView loadHTMLString:htmlStr 
					  baseURL:nil ];
	
	// only adjust the content size for scrolling if there is at least 1 comment!
	if ( [[m_item comments] count] > 0 )
	{
		pos += COMMENT_WEBVIEW_HEIGHT;
	}
	m_webView.userInteractionEnabled=YES;
	
	[(UIScrollView *)(self.view) setContentSize:CGSizeMake(HEADER_WIDTH,pos)];
	
	[self.view setNeedsDisplay];
}


- (NSString *)formatItemComments
{
	NSMutableString *html = [[[NSMutableString alloc] initWithString:COMMENT_HTML_HDR] autorelease];
	
	NSDateFormatter *dateFmt = [[[NSDateFormatter alloc] init] autorelease];
	[dateFmt setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
	
	// Add all the comments!
	NSArray *commentArray = [[m_item comments] sortedArrayUsingSelector:@selector(compareCommentByDate:)];
	NSEnumerator *cmntEnum = [commentArray objectEnumerator];
	CommunityComment *cmnt;
	while ( cmnt = [cmntEnum nextObject] )
	{
		
		NSString *dateStr = (cmnt.m_date ? [dateFmt stringFromDate:cmnt.m_date] : @"some unspecified date/time!");
		MyGovUser *user = [[myGovAppDelegate sharedUserData] userFromUsername:cmnt.m_creator];
		NSURL *avatarURL = [NSURL fileURLWithPath:[MyGovUserData userAvatarPath:user.m_username]];
		NSString *subtitle = [NSString stringWithFormat:@"Posted by <b>%@</b> on %@",[user m_username],dateStr];
		[html appendFormat:COMMENT_HTML_FMT, cmnt.m_title, subtitle, [avatarURL absoluteString], cmnt.m_text];
	}
	
	[html appendString:COMMENT_HTML_END];
	return html;
}


- (CGFloat)heightForFeedbackText
{
	NSString *txt = m_item.m_text;
	
	CGSize txtSz = [txt sizeWithFont:COMMENT_TXT_FONT
				   constrainedToSize:CGSizeMake(CONTENT_WIDTH,COMMENT_TXT_MAXHEIGHT)
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
	
	//[self.tableView reloadData];
	[self reloadItemData];
}


- (void)userWantsToAttend
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

/**
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
*/

@end


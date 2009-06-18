/*
 File: TableDataManager.m
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
#import "CustomTableCell.h"
#import "TableDataManager.h"
#import "MiniBrowserController.h"

@implementation TableRowData

@synthesize title, titleColor, titleFont, titleAlignment;
@synthesize line1, line1Color, line1Font, line1Alignment;
@synthesize line2, line2Color, line2Font, line2Alignment;
@synthesize url, action;

- (id)init
{
	if ( self = [super init] )
	{
		title = nil;
		titleColor = nil;
		titleFont = nil;
		titleAlignment = UITextAlignmentLeft;
		
		line1 = nil;
		line1Color = nil;
		line1Font = nil;
		line1Alignment = UITextAlignmentLeft;
		
		line2 = nil;
		line2Color = nil;
		line2Font = nil;
		line2Alignment = UITextAlignmentLeft;
		
		url = nil;
		action = nil;
	}
	return self;
}


- (NSComparisonResult)compareTitle:(TableRowData *)other
{
	return [title compare:other.title];
}

@end



@interface TableDataManager (private)
	- (void)rowActionNone:(NSIndexPath *)indexPath;
	- (void)rowActionMailto:(NSIndexPath *)indexPath;
	- (void)rowActionPhoneCall:(NSIndexPath *)indexPath;
	- (void)rowActionURL:(NSIndexPath *)indexPath;
	- (void)rowActionMap:(NSIndexPath *)indexPath;
@end



@implementation TableDataManager

- (id)init
{
	if ( self = [super init] )
	{
		m_notifyTarget = nil;
		m_notifySelector = nil;
		m_dataSections = nil;
		m_data = nil;
		m_actionParent = nil;
	}
	return self;
}


- (void)dealloc
{
	[m_notifyTarget release];
	[m_data release];
	[m_dataSections release];
	
	[super dealloc];
}


- (void)setNotifyTarget:(id)target andSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = target;
	m_notifySelector = sel;
}


- (NSInteger)numberOfSections
{
	return [m_data count];
}


- (NSString *)titleForSection:(NSInteger)section
{
	if ( section < [m_dataSections count] )
	{
		return [m_dataSections objectAtIndex:section];
	}
	return nil;
}


- (NSInteger)numberOfRowsInSection:(NSInteger)section
{
	if ( section >= [m_data count] ) return 0;
	return [[m_data objectAtIndex:section] count];
}


- (CGFloat)heightForDataAtIndexPath:(NSIndexPath *)indexPath
{
	TableRowData *rd = [self dataAtIndexPath:indexPath];
	return [CustomTableCell cellHeightForRow:rd];
}


- (id)dataAtIndexPath:(NSIndexPath *)indexPath
{
	NSInteger section = indexPath.section;
	NSInteger row = indexPath.row;
	
	if ( section >= [m_data count] ) return nil;
	
	NSArray *secArray = [m_data objectAtIndex:section];
	if ( row >= [secArray count] ) return nil;
	
	// 
	// Get the key/value pair from the single-object-dictionary stored
	// in the 'm_data' object at: m_data[indexPath.section][indexPath.row]
	// 
	return [secArray objectAtIndex:row];
}


- (void)performActionForIndex:(NSIndexPath *)indexPath withParent:(id)parent
{
	m_actionParent = [parent retain];
	
	TableRowData *rd = [self dataAtIndexPath:indexPath];
	if ( nil != rd && nil != rd.action )
	{
		if ( [self respondsToSelector:rd.action] )
		{
			[self performSelector:rd.action withObject:indexPath];
		}
	}
	
	[m_actionParent release]; m_actionParent = nil;
}


#pragma mark TableDataManager Private 


- (void)rowActionNone:(NSIndexPath *)indexPath
{
	(void)indexPath;
	return;
}

- (void)rowActionMailto:(NSIndexPath *)indexPath
{
	TableRowData *rd = [self dataAtIndexPath:indexPath];
	if ( nil == rd ) return;
	
	NSString *subject = [NSString stringWithString:@"Message from a concerned citizen"];
	NSString *emailStr = [[NSString alloc] initWithFormat:@"mailto:%@?subject=%@",
							  [rd.line1 stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding], 
							  [subject stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]
						  ];
	NSURL *emailURL = [[NSURL alloc] initWithString:emailStr];
	[[UIApplication sharedApplication] openURL:emailURL];
	[emailStr release];
	[emailURL release];
}


- (void)rowActionPhoneCall:(NSIndexPath *)indexPath
{
	if ( ![myGovAppDelegate canMakePhoneCalls] ) return;
	
	TableRowData *rd = [self dataAtIndexPath:indexPath];
	if ( nil == rd ) return;
	
	// make a phone call!
	NSString *telStr = [[[NSString alloc] initWithFormat:@"tel:%@",rd.line1] stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding];
	NSURL *telURL = [[NSURL alloc] initWithString:telStr];
	[[UIApplication sharedApplication] openURL:telURL];
	[telStr release];
	[telURL release];
}


- (void)rowActionURL:(NSIndexPath *)indexPath
{
	TableRowData *rd = [self dataAtIndexPath:indexPath];
	if ( nil == rd ) return;
	
	NSURL *url;
	if ( [[rd.url absoluteString] length] > 0 )
	{
		url = rd.url;
	}
	else
	{
		url = [NSURL URLWithString:[rd.line1 stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]];
	}
	
	NSString *urlStr = [url absoluteString];
	
	// look for in-app URLs and open them appropriately
	NSRange mgRange = {0,5};
	if ( ([urlStr length] >= mgRange.length) && 
		(NSOrderedSame == [urlStr compare:@"mygov" options:NSCaseInsensitiveSearch range:mgRange])
		)
	{
		[[UIApplication sharedApplication] openURL:url];
	}
	else
	{
		// open other URLs in our mini browser
		MiniBrowserController *mbc = [MiniBrowserController sharedBrowserWithURL:url];
		[mbc display:m_actionParent];
	}
}


- (void)rowActionMap:(NSIndexPath *)indexPath
{
	TableRowData *rd = [self dataAtIndexPath:indexPath];
	if ( nil == rd ) return;
	
	NSURL *url;
	if ( [[rd.url absoluteString] length] > 0 )
	{
		url = rd.url;
	}
	else
	{
		url = [NSURL URLWithString:[rd.line1 stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]];
	}
	
	// just open the URL via the shared application and hope
	// that it's been formed well :-)
	[[UIApplication sharedApplication] openURL:url];
}


@end


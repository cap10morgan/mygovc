/*
 File: PlaceSpendingTableCell.m
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

#import "CongressDataManager.h"
#import "LegislatorContainer.h"
#import "PlaceSpendingData.h"
#import "PlaceSpendingTableCell.h"
#import "SpendingDataManager.h"
#import "StateAbbreviations.h"

enum  
{
	eTAG_ACTIVITY = 999	
};


#define RANK_FONT [UIFont systemFontOfSize:16.0f]
#define RANK_FONT_BIGSPENDER [UIFont boldSystemFontOfSize:16.0f]
#define RANK_COLOR [UIColor grayColor]
#define RANK_COLOR_BIGSPENDER [UIColor darkGrayColor]


@interface PlaceSpendingTableCell (private)
	- (void)layoutStateData;
	- (void)layoutDistrictData;
@end


@implementation PlaceSpendingTableCell

@synthesize m_placeView;
@synthesize m_legView;
@synthesize m_rankView;
@synthesize m_detailButton;
@synthesize m_data;


- (void)dealloc 
{
	[m_data release]; // release our handle to the data 
	[super dealloc];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	
	m_placeView.highlighted = selected;
	m_legView.highlighted = selected;
	m_rankView.highlighted = selected;
}


- (void)setDetailTarget:(id)tgt withSelector:(SEL)sel
{
	// set delegate for detail button press!
	[m_detailButton addTarget:tgt action:sel forControlEvents:UIControlEventTouchUpInside];
}


- (void)setPlaceData:(PlaceSpendingData *)data 
{
	if ( nil == data ) return;
	
	[m_data release];
	m_data = [data retain];
	
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	if ( ![m_data isDataAvailable] )
	{
		CGFloat cellHeight = (CGFloat)(self.contentView.bounds.size.height);
		
		[m_placeView setText:m_data.m_place];
		m_legView.textColor = [UIColor darkGrayColor];
		
		[m_detailButton setHidden:YES];
		[m_rankView setHidden:YES];
		
		if ( ![myGovAppDelegate networkIsAvailable:NO]  )
		{
			[m_legView setText:@"No network!"];
		}
		else
		{
			[m_legView setText:@"downloading..."];
			CGSize txtSize = [m_legView.text sizeWithFont:m_legView.font
										constrainedToSize:self.contentView.bounds.size 
											lineBreakMode:UILineBreakModeTailTruncation];
			
			// render a UIActivityView...
			if ( nil == aiView )
			{
				aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
				aiView.hidesWhenStopped = YES;
				[aiView setFrame:CGRectMake(0.0f, 0.0f, cellHeight/2.0f, cellHeight/2.0f)];
				[aiView setCenter:CGPointMake(CGRectGetMinX(m_legView.frame) + txtSize.width + cellHeight, cellHeight/2.0f)];
				[aiView setTag:eTAG_ACTIVITY];
				[self addSubview:aiView];
				[aiView release];
			}
			[aiView startAnimating];
		}
		return;
	}
	
	SpendingPlaceType type = m_data.m_placeType;
	switch ( type )
	{
		default:
		case eSPT_District:
			[self layoutDistrictData];
			break;
		case eSPT_State:
			[self layoutStateData];
			break;
	}
	
	[m_detailButton setHidden:NO];
	[m_rankView setHidden:NO];
}


#pragma mark PlaceSpendingTableCell Private


- (void)layoutStateData
{
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	if ( nil != aiView ) { [aiView stopAnimating]; }
	
	// set place text, and get its size so we can re-size the 
	// legislator text to a maximum...
	[m_placeView setText:[[StateAbbreviations nameFromAbbr:m_data.m_place] stringByAppendingString:@": "]];
	
	CGSize placeSz = [m_placeView.text sizeWithFont:m_placeView.font
									 constrainedToSize:self.contentView.bounds.size 
									 lineBreakMode:UILineBreakModeTailTruncation];
	
	[m_placeView setFrame:CGRectMake(CGRectGetMinX(m_placeView.frame), 
									 CGRectGetMinY(m_placeView.frame), 
									 placeSz.width, placeSz.height)
	 ];
	
	[m_legView setFrame:CGRectMake(CGRectGetMaxX(m_placeView.frame),
								   CGRectGetMinY(m_legView.frame),
								   CGRectGetMaxX(m_legView.frame) - CGRectGetMaxX(m_placeView.frame),
								   placeSz.height)
	 ];
	
	NSString *legText;
	NSArray *senateMembers = [[myGovAppDelegate sharedCongressData] senateMembersInState:m_data.m_place];
	UIColor *legColor;
	if ( nil == senateMembers ) 
	{
		legText = @" "; // no senate members!
		legColor = [UIColor darkGrayColor];
	}
	else if ( [senateMembers count] < 2 && [senateMembers count] > 0 )
	{
		NSString *party = [[senateMembers objectAtIndex:0] party];
		legText = [[[NSString alloc] initWithFormat:@" %@ (%@)",
											[[senateMembers objectAtIndex:0] lastname],
											party
					] autorelease];
		legColor = [LegislatorContainer partyColor:party];
	}
	else
	{
		NSString *party1 = [[senateMembers objectAtIndex:0] party];
		NSString *party2 = [[senateMembers objectAtIndex:1] party];
		
		legText = [[[NSString alloc] initWithFormat:@" %@ (%@) / %@ (%@)",
											[[senateMembers objectAtIndex:0] lastname],
											party1,
											[[senateMembers objectAtIndex:1] lastname],
											party2
				   ] autorelease];
		
		if ( ![party1 isEqualToString:party2] )
		{
			// a purple haze...
			legColor = [UIColor colorWithRed:0.4f green:0.09f blue:0.4f alpha:1.0f];
		}
		else
		{
			legColor = [LegislatorContainer partyColor:party1];
		}
	}
	
	m_legView.textColor = legColor;
	[m_legView setText:legText];
	
	[m_rankView setText:[m_data rankStr]];
	
	// color high-spenders in red!
	if ( [m_data rankIsTop25Pct] )
	{
		m_rankView.font = RANK_FONT_BIGSPENDER;
		m_rankView.textColor = RANK_COLOR_BIGSPENDER;
	}
	else
	{
		m_rankView.font = RANK_FONT;
		m_rankView.textColor = RANK_COLOR;
	}
}


- (void)layoutDistrictData
{
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	if ( nil != aiView ) { [aiView stopAnimating]; }
	
	[m_placeView setText:[m_data.m_place stringByAppendingString:@": "]];
	
	CGSize placeSz = [m_placeView.text sizeWithFont:m_placeView.font
								  constrainedToSize:self.contentView.bounds.size 
									  lineBreakMode:UILineBreakModeTailTruncation];
	
	[m_placeView setFrame:CGRectMake(CGRectGetMinX(m_placeView.frame), 
									 CGRectGetMinY(m_placeView.frame), 
									 placeSz.width, placeSz.height)
	 ];
	
	[m_legView setFrame:CGRectMake(CGRectGetMaxX(m_placeView.frame),
								   CGRectGetMinY(m_legView.frame),
								   CGRectGetMaxX(m_legView.frame) - CGRectGetMaxX(m_placeView.frame),
								   placeSz.height)
	 ];
	
	LegislatorContainer *lc =  [[myGovAppDelegate sharedCongressData] districtRepresentative:m_data.m_place];
	NSString *legislatorName = [lc shortName];
	NSString *party = [lc party];
	
	// strip the title off the name
	NSString *legText = [[[NSString alloc] initWithFormat:@" %@ (%@)",
										   [legislatorName substringFromIndex:5],
										   party
						 ] autorelease];
	
	m_legView.textColor = [LegislatorContainer partyColor:party];
	[m_legView setText:legText];
	
	[m_rankView setText:[m_data rankStr]];
	
	// color high-spenders in red!
	if ( [m_data rankIsTop25Pct] )
	{
		m_rankView.font = RANK_FONT_BIGSPENDER;
		m_rankView.textColor = RANK_COLOR_BIGSPENDER;
	}
	else
	{
		m_rankView.font = RANK_FONT;
		m_rankView.textColor = RANK_COLOR;
	}
}


@end


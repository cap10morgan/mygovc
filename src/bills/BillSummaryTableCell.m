/*
 File: BillSummaryTableCell.m
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

#import "BillSummaryTableCell.h"
#import "BillContainer.h"
#import "LegislatorContainer.h"

@implementation BillSummaryTableCell

@synthesize m_billNumView, m_sponsorView, m_descripView;
@synthesize m_statusView, m_voteView, m_detailButton;
@synthesize m_bill, m_tableRange;

static const CGFloat S_CELL_HPADDING = 7.0f;
static const CGFloat S_CELL_VPADDING = 4.0f;
static const CGFloat S_MAX_DESCRIP_HEIGHT = 120.0f;
static const CGFloat S_MIN_ROW_HEIGHT = 24.0f;

#define D_DESCRIP_FONT [UIFont systemFontOfSize:16.0f]

#define VOTE_PASSED_COLOR [UIColor colorWithRed:0.1f green:0.65f blue:0.1f alpha:1.0f]
#define VOTE_FAILED_COLOR [UIColor darkGrayColor];


+ (CGFloat)getCellHeightForBill:(BillContainer *)bill
{
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	if ( UIDeviceOrientationUnknown == orientation ) orientation = UIDeviceOrientationPortrait;
	
	CGFloat screenWidth = 0.0f;
	if ( UIDeviceOrientationPortrait == orientation || UIDeviceOrientationPortraitUpsideDown == orientation )
	{
		screenWidth = CGRectGetWidth([UIScreen mainScreen].applicationFrame);
	}
	else 
	{
		screenWidth = CGRectGetHeight([UIScreen mainScreen].applicationFrame);
	}

	NSString *descrip = bill.m_title;
	CGSize descripSz = [descrip sizeWithFont:D_DESCRIP_FONT 
							constrainedToSize:CGSizeMake(screenWidth - (3.0f*S_CELL_HPADDING) - 32.0f,S_MAX_DESCRIP_HEIGHT) 
							lineBreakMode:UILineBreakModeWordWrap];
	
	CGFloat height = S_CELL_VPADDING + S_MIN_ROW_HEIGHT + S_CELL_VPADDING // bill number + sponsor
					 + descripSz.height + S_CELL_VPADDING  // bill title/descrip
					 + S_MIN_ROW_HEIGHT + S_CELL_VPADDING; // status/vote
	
	return height;
}


- (void)dealloc 
{
	[m_bill release];
	[super dealloc];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	
	[m_billNumView setHighlighted:selected];
	[m_sponsorView setHighlighted:selected];
	[m_descripView setHighlighted:selected];
	[m_statusView setHighlighted:selected];
	[m_voteView setHighlighted:selected];
}


- (void)setDetailTarget:(id)target andSelector:(SEL)selector
{
	// set delegate for detail button press!
	[m_detailButton addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}


- (void)setContentFromBill:(BillContainer *)container
{
	[m_bill release]; m_bill = nil;
	
	if ( nil == container )
	{
		[m_detailButton setHidden:YES];
		[m_billNumView setText:@""];
		[m_sponsorView setText:@""];
		[m_descripView setText:@""];
		[m_statusView setText:@""];
		[m_voteView setText:@""];
		return;
	}
	
	m_bill = [container retain];

	// 
	// Bill Number 
	//
	NSString *billNumStr = [m_bill getShortTitle];
	[m_billNumView setText:billNumStr];
	
	// 
	// Sponsor
	// 
	LegislatorContainer *sponsor = [m_bill sponsor];
	NSString *sponsorTxt = [NSString stringWithFormat:@"%@ (%@, %@)",
											[sponsor shortName],
											[sponsor party],
											[sponsor state]
							];
	[m_sponsorView setText:sponsorTxt];
	m_sponsorView.textColor = [LegislatorContainer partyColor:[sponsor party]];
	
	// 
	// Bill title/description
	// 
	NSString *descripStr = [m_bill.m_title substringFromIndex:([m_bill.m_title rangeOfString:@" "].location + 1)];
	[m_descripView setText:descripStr];
	
	// 
	// Bill Status
	// 
	NSString *statusTxt = [m_bill.m_status capitalizedString];
	[m_statusView setText:statusTxt];
	
	// 
	// Was there a vote?
	// 
	if ( nil == [m_bill voteString] )
	{
		m_voteView.text = @"";
	}
	else
	{
		NSString *voteTxt = [m_bill voteString];
		UIColor *voteColor;
		if ( [voteTxt isEqualToString:@"Passed"] )
		{
			voteColor = VOTE_PASSED_COLOR;
		}
		else
		{
			voteColor = VOTE_FAILED_COLOR;
		}
		[m_voteView setText:voteTxt];
		m_voteView.textColor = voteColor;
	}
}

@end

/*
 File: LegislatorNameCell.m
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

#import "LegislatorNameCell.h"
#import "LegislatorContainer.h"


@implementation LegislatorNameCell

@synthesize m_tableRange, m_legislator;

static const CGFloat S_TABLE_TITLE_WIDTH = 30.0f;
static const CGFloat S_INFO_OFFSET = 10.0f;
static const CGFloat S_PARTY_INDICATOR_WIDTH = 30.0f;
static const CGFloat S_CELL_HPADDING = 7.0f;

#define NAME_FONT  [UIFont boldSystemFontOfSize:18.0f]
#define NAME_COLOR [UIColor blackColor]
#define NAME_SHADOW_COLOR [UIColor clearColor]
#define INFO_FONT  [UIFont systemFontOfSize:14.0f]
#define INFO_COLOR [UIColor darkGrayColor]
#define PARTY_FONT [UIFont systemFontOfSize:14.0f]

enum
{
	eTAG_DETAIL = 999,
	eTAG_NAME   = 998,
	eTAG_PARTY  = 997,
	eTAG_INFO   = 996,
};

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier detailTarget:(id)tgt detailSelector:(SEL)sel
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		m_legislator = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		CGFloat frameX = S_CELL_HPADDING;
		CGFloat frameY = 0.0f;
		CGFloat frameW = self.contentView.bounds.size.width - (frameX * 2.0f);
		CGFloat frameH = self.contentView.bounds.size.height - (frameY * 2.0f);
		
		UIButton *detail = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		//detail.showsTouchWhenHighlighted = YES;
		CGRect detailRect = CGRectMake( frameW - S_TABLE_TITLE_WIDTH - CGRectGetWidth(detail.frame),
									   frameY + (frameH - CGRectGetHeight(detail.frame))/2.0f,
									   CGRectGetWidth(detail.frame),
									   CGRectGetHeight(detail.frame) );
		[detail setFrame:detailRect];
		[detail setTag:eTAG_DETAIL];
		
		CGRect nameRect = CGRectMake(frameX, 
									 frameY, 
									 frameW - S_TABLE_TITLE_WIDTH - S_PARTY_INDICATOR_WIDTH - CGRectGetWidth(detailRect) - 5.0f, 
									 frameH/1.5);
		UILabel *nameView = [[UILabel alloc] initWithFrame:nameRect];
		nameView.backgroundColor = [UIColor clearColor];
		nameView.textColor = NAME_COLOR;
		nameView.shadowColor = NAME_SHADOW_COLOR;
		nameView.shadowOffset = CGSizeMake(0,-1);
		nameView.font = NAME_FONT;
		nameView.textAlignment = UITextAlignmentLeft;
		nameView.adjustsFontSizeToFitWidth = YES;
		[nameView setTag:eTAG_NAME];
		
		/*
		CGRect partyRect = CGRectMake(CGRectGetMinX(detailRect) - S_PARTY_INDICATOR_WIDTH,
									  frameY, 
									  S_PARTY_INDICATOR_WIDTH, 
									  frameH/1.5);
		 */
		CGRect partyRect = CGRectMake( frameX + S_INFO_OFFSET, 
									   frameY + CGRectGetHeight(nameRect),
									   S_PARTY_INDICATOR_WIDTH,
									   frameH - CGRectGetHeight(nameRect) );
		UILabel *partyView = [[UILabel alloc] initWithFrame:partyRect];
		partyView.backgroundColor = [UIColor clearColor];
		partyView.textColor = [UIColor darkGrayColor];
		partyView.font = PARTY_FONT;
		partyView.textAlignment = UITextAlignmentRight;
		partyView.adjustsFontSizeToFitWidth = YES;
		[partyView setTag:eTAG_PARTY];
		
		/*
		CGRect infoRect = CGRectMake( frameX + S_INFO_OFFSET, 
									  frameY + CGRectGetHeight(nameRect),
									  frameW - S_INFO_OFFSET - S_PARTY_INDICATOR_WIDTH,
									  frameH - CGRectGetHeight(nameRect) );
		 */
		CGRect infoRect = CGRectMake( CGRectGetMaxX(partyRect) + S_CELL_HPADDING, 
									  frameY + CGRectGetHeight(nameRect),
									  CGRectGetMinX(detailRect) - S_PARTY_INDICATOR_WIDTH - S_INFO_OFFSET - S_CELL_HPADDING,
									  frameH - CGRectGetHeight(nameRect) );
		UILabel *infoView = [[UILabel alloc] initWithFrame:infoRect];
		infoView.backgroundColor = [UIColor clearColor];
		infoView.textColor = INFO_COLOR;
		infoView.font = INFO_FONT;
		infoView.textAlignment = UITextAlignmentLeft;
		infoView.adjustsFontSizeToFitWidth = YES;
		[infoView setTag:eTAG_INFO];
		
		
		// set delegate for detail button press!
		[detail addTarget:tgt action:sel forControlEvents:UIControlEventTouchUpInside];
		
		// add views to cell view
		[self addSubview:nameView];
		[self addSubview:partyView];
		[self addSubview:infoView];
		[self addSubview:detail];
		
		[nameView release];
		[partyView release];
		[infoView release];
	}
	return self;
}


- (void)dealloc
{
	[m_legislator release];
	[super dealloc];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
    [super setSelected:selected animated:animated];
	
    // Configure the view for the selected state
	UILabel *nameView = (UILabel *)[self viewWithTag:eTAG_NAME];
	nameView.highlighted = selected;
	
	UILabel *partyView = (UILabel *)[self viewWithTag:eTAG_PARTY];
	partyView.highlighted = selected;
	
	UILabel *infoView = (UILabel *)[self viewWithTag:eTAG_INFO];
	infoView.highlighted = selected;
}


- (void)setInfoFromLegislator:(LegislatorContainer *)legislator
{
	[m_legislator release];
	m_legislator = [legislator retain];
	
	// Set up the cell...
	NSString *name = [[NSString alloc] initWithFormat:@"%@%@ %@%@",
										[legislator firstname],
										([legislator middlename] ? [NSString stringWithFormat:@" %@",[legislator middlename]] : @""),
										[legislator lastname],
										([legislator name_suffix] ? [NSString stringWithFormat:@" %@",[legislator name_suffix]] : @"")
					 ];
	
	NSString *party = [[NSString alloc] initWithFormat:@"(%@)",[legislator party]];
	
	NSString *info;
	if ( [[legislator title] isEqualToString:@"Rep"] )
	{
		info = [[NSString alloc] initWithFormat:@"%@ District %@%@",[legislator state],[legislator district],([[legislator district] isEqualToString:@"0"] ? @" (At-Large)" : @"")];
	}
	else if ( [[legislator title] isEqualToString:@"Sen"] )
	{
		info = [[NSString alloc] initWithFormat:@"%@ Senator",[legislator state]];
	}
	else if ( [[legislator title] isEqualToString:@"Del"] )
	{
		info = [[NSString alloc] initWithFormat:@"%@ Delegate",[legislator state]];
	}
	else
	{
		info = [[NSString alloc] initWithFormat:@"%@.",[legislator title]];
	}
	
	UILabel *nameView = (UILabel *)[self viewWithTag:eTAG_NAME];
	[nameView setText:name];
	
	UILabel *partyView = (UILabel *)[self viewWithTag:eTAG_PARTY];
	[partyView setText:party];
	//[partyView setTextColor:([party isEqualToString:@"D"] ? [UIColor blueColor] : [UIColor redColor])];
	
	UILabel *infoView = (UILabel *)[self viewWithTag:eTAG_INFO];
	[infoView setText:info];
	
	// set a background color based on party :-)
	if ( [party isEqualToString:@"(D)"] )
	{
		partyView.textColor = [UIColor blueColor];
	}
	else if ( [party isEqualToString:@"(R)"] )
	{
		partyView.textColor = [UIColor redColor];
	}
	else
	{
		partyView.textColor = [UIColor darkGrayColor];
	}
	
	[name release];
	[party release];
	[info release];
}



@end


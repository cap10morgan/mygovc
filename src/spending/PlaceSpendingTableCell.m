//
//  PlaceSpendingTableCell.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/22/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"

#import "CongressDataManager.h"
#import "LegislatorContainer.h"
#import "PlaceSpendingData.h"
#import "PlaceSpendingTableCell.h"
#import "SpendingDataManager.h"
#import "StateAbbreviations.h"


@interface PlaceSpendingTableCell (private)
	- (void)layoutStateData;
	- (void)layoutDistrictData;
@end


@implementation PlaceSpendingTableCell

@synthesize m_data;

enum
{
	eTAG_DETAIL     = 999,
	eTAG_RANK       = 998,
	eTAG_LEGISLATOR = 997, 
	eTAG_PLACE      = 996,
	eTAG_ACTIVITY   = 995,
};

static const CGFloat S_CELL_HOFFSET = 7.0f;
static const CGFloat S_CELL_VOFFSET = 2.0f;
static const CGFloat S_TABLE_TITLE_WIDTH = 20.0f;
static const CGFloat S_PLACE_TEXT_WIDTH = 120.0f;

static const CGFloat S_ROW_HEIGHT = 23.0f;

#define PLACE_FONT [UIFont boldSystemFontOfSize:16.0f]
#define LEGISLATOR_FONT [UIFont systemFontOfSize:16.0f]

#define RANK_FONT [UIFont systemFontOfSize:16.0f]
#define RANK_FONT_BIGSPENDER [UIFont boldSystemFontOfSize:16.0f]
#define RANK_COLOR [UIColor grayColor]
#define RANK_COLOR_BIGSPENDER [UIColor darkGrayColor]


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)identifier detailTarget:(id)tgt detailSelector:(SEL)sel
{
	if ( self = [super initWithFrame:frame reuseIdentifier:identifier] ) 
	{
		m_data = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		// 
		// Detail button (next to table index)
		// 
		UIButton *detail = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[detail setTag:eTAG_DETAIL];
		[self addSubview:detail];
				
		// 
		// Place text field (on the left side of the cell, first row)
		// 
		UILabel *placeView = [[UILabel alloc] initWithFrame:CGRectZero];
		placeView.backgroundColor = [UIColor clearColor];
		placeView.textColor = [UIColor blackColor];
		placeView.font = PLACE_FONT;
		placeView.textAlignment = UITextAlignmentLeft;
		placeView.adjustsFontSizeToFitWidth = YES;
		[placeView setTag:eTAG_PLACE];
		[self addSubview:placeView];
		[placeView release];
		
		// 
		// Legislator text box squeezes in between the place and detail
		// 
		UILabel *legView = [[UILabel alloc] initWithFrame:CGRectZero];
		legView.backgroundColor = [UIColor clearColor];
		legView.textColor = [UIColor darkGrayColor];
		legView.font = LEGISLATOR_FONT;
		legView.textAlignment = UITextAlignmentLeft;
		legView.adjustsFontSizeToFitWidth = YES;
		[legView setTag:eTAG_LEGISLATOR];
		[self addSubview:legView];
		[legView release];
		
		// 
		// Rank/Dollars text field: second row
		// 
		UILabel *rankView = [[UILabel alloc] initWithFrame:CGRectZero];
		rankView.backgroundColor = [UIColor clearColor];
		rankView.textColor = [UIColor darkGrayColor];
		rankView.font = RANK_FONT;
		rankView.textAlignment = UITextAlignmentLeft;
		rankView.adjustsFontSizeToFitWidth = YES;
		[rankView setTag:eTAG_RANK];
		[self addSubview:rankView];
		[rankView release];
		
		// set delegate for detail button press!
		[detail addTarget:tgt action:sel forControlEvents:UIControlEventTouchUpInside];
	}
	
	return self;
}


- (void)dealloc 
{
	[m_data release]; // release our handle to the data 
	[super dealloc];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	
	// XXX - Configure the view for the selected state
}


- (void)setPlaceData:(PlaceSpendingData *)data 
{
	if ( nil == data ) return;
	
	[m_data release];
	m_data = [data retain];
	
	// Grab all our text views
	UILabel *placeView = (UILabel *)[self viewWithTag:eTAG_PLACE];
	UILabel *legView = (UILabel *)[self viewWithTag:eTAG_LEGISLATOR];
	UILabel *rankView = (UILabel *)[self viewWithTag:eTAG_RANK];
	UIButton *detailButton = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	if ( ![m_data isDataAvailable] )
	{
		CGFloat cellHeight = (CGFloat)(self.contentView.bounds.size.height);
		
		NSString *downloadStr = @"downloading...";
		CGSize legSz = [downloadStr sizeWithFont:legView.font
									 constrainedToSize:CGSizeMake(S_PLACE_TEXT_WIDTH,cellHeight) 
									 lineBreakMode:UILineBreakModeTailTruncation];
		CGSize placeSz = [m_data.m_place sizeWithFont:placeView.font
										 constrainedToSize:CGSizeMake(S_PLACE_TEXT_WIDTH,cellHeight) 
										 lineBreakMode:UILineBreakModeTailTruncation];
		
		[placeView setFrame:CGRectMake(S_CELL_HOFFSET, 0.0f, placeSz.width, cellHeight)];
		
		[legView setFrame:CGRectMake(placeSz.width + (2.0f*S_CELL_HOFFSET),
									 0.0f,
									 legSz.width,
									 cellHeight
									 )];
		
		[placeView setText:m_data.m_place];
		[legView setText:downloadStr];
		legView.textColor = [UIColor darkGrayColor];
		
		[detailButton setHidden:YES];
		[rankView setHidden:YES];
		
		// render a UIActivityView...
		if ( nil == aiView )
		{
			aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			aiView.hidesWhenStopped = YES;
			[aiView setFrame:CGRectMake(0.0f, 0.0f, cellHeight/2.0f, cellHeight/2.0f)];
			[aiView setCenter:CGPointMake(CGRectGetMaxX(legView.frame) + S_CELL_HOFFSET + cellHeight/2.0f, cellHeight/2.0f)];
			[aiView setTag:eTAG_ACTIVITY];
			[self addSubview:aiView];
			[aiView release];
		}
		[aiView startAnimating];
		
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
	
	[detailButton setHidden:NO];
	[rankView setHidden:NO];
}


#pragma mark PlaceSpendingTableCell Private


- (void)layoutStateData
{
	// Grab all our text views
	UILabel *rankView = (UILabel *)[self viewWithTag:eTAG_RANK];
	UILabel *placeView = (UILabel *)[self viewWithTag:eTAG_PLACE];
	UILabel *legView = (UILabel *)[self viewWithTag:eTAG_LEGISLATOR];
	UIButton *detailButton = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	if ( nil != aiView ) { [aiView stopAnimating]; }
	
	CGFloat cellHeight = self.contentView.bounds.size.height;
	CGFloat cellWidth = 320.0f - (2.0f*S_CELL_HOFFSET);
	CGFloat cellY = S_CELL_VOFFSET;
	// put the detail button all the way to the edge of the frame
	CGRect detailRect = CGRectMake(S_CELL_HOFFSET + (cellWidth - CGRectGetWidth(detailButton.frame)),
								   (cellHeight - CGRectGetHeight(detailButton.frame))/2.0f,
								   CGRectGetWidth(detailButton.frame),
								   CGRectGetHeight(detailButton.frame)
								  );
	[detailButton setFrame:detailRect];
	
	
	// set place text, and get its size so we can re-size the 
	// legislator text to a maximum...
	[placeView setText:[[StateAbbreviations nameFromAbbr:m_data.m_place] stringByAppendingString:@": "]];
	
	CGSize placeSz = [placeView.text sizeWithFont:placeView.font
									 constrainedToSize:CGSizeMake(S_PLACE_TEXT_WIDTH,S_ROW_HEIGHT) 
									 lineBreakMode:UILineBreakModeTailTruncation];
	
	[placeView setFrame:CGRectMake(S_CELL_HOFFSET, cellY, placeSz.width, S_ROW_HEIGHT)];
	
	[legView setFrame:CGRectMake(CGRectGetMaxX(placeView.frame) + S_CELL_HOFFSET,
								 cellY,
								 CGRectGetMinX(detailRect) - CGRectGetMaxX(placeView.frame) - (2.0f*S_CELL_HOFFSET),
								 S_ROW_HEIGHT
								 )];
	
	NSString *legText;
	NSArray *senateMembers = [[myGovAppDelegate sharedCongressData] senateMembersInState:m_data.m_place];
	UIColor *legColor;
	if ( nil == senateMembers ) 
	{
		legText = @"( - )"; // spacing text
		
		// resize the placeView width just in case we need more space...
		CGSize legSz = [legText sizeWithFont:legView.font
								constrainedToSize:CGSizeMake(S_PLACE_TEXT_WIDTH,S_ROW_HEIGHT) 
								lineBreakMode:UILineBreakModeTailTruncation];
		[placeView setFrame:CGRectMake(S_CELL_HOFFSET,
									   cellY,
									   CGRectGetMinX(detailRect) - legSz.width - (2.0f*S_CELL_HOFFSET),
									   S_ROW_HEIGHT)];
		[legView setFrame:CGRectMake(CGRectGetMaxX(placeView.frame) + S_CELL_HOFFSET,
									 cellY, legSz.width, S_ROW_HEIGHT)];
		legText = @""; // no text displayed
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
	
	legView.textColor = legColor;
	[legView setText:legText];
	
	// next row!
	cellY += S_ROW_HEIGHT - S_CELL_VOFFSET;
	
	// put the rank cell in the second row
	CGRect rankRect = CGRectMake((2.0f*S_CELL_HOFFSET),
								 cellY, 
								 CGRectGetMinX(detailRect) - (4.0f*S_CELL_HOFFSET), 
								 S_ROW_HEIGHT);
	[rankView setFrame:rankRect];
	
	[rankView setText:[m_data rankStr]];
	
	// color high-spenders in red!
	if ( [m_data rankIsTop25Pct] )
	{
		rankView.font = RANK_FONT_BIGSPENDER;
		rankView.textColor = RANK_COLOR_BIGSPENDER;
	}
	else
	{
		rankView.font = RANK_FONT;
		rankView.textColor = RANK_COLOR;
	}
}


- (void)layoutDistrictData
{
	// Grab all our text views
	UILabel *rankView = (UILabel *)[self viewWithTag:eTAG_RANK];
	UILabel *placeView = (UILabel *)[self viewWithTag:eTAG_PLACE];
	UILabel *legView = (UILabel *)[self viewWithTag:eTAG_LEGISLATOR];
	UIButton *detailButton = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	if ( nil != aiView ) { [aiView stopAnimating]; }
	
	CGFloat cellHeight = self.contentView.bounds.size.height;
	CGFloat cellWidth = 320.0f - (3.0f*S_CELL_HOFFSET) - S_TABLE_TITLE_WIDTH;
	CGFloat cellY = S_CELL_VOFFSET;
	// put the detail button all the way to the edge of the frame
	CGRect detailRect = CGRectMake(S_CELL_HOFFSET + (cellWidth - CGRectGetWidth(detailButton.frame)),
								   (cellHeight - CGRectGetHeight(detailButton.frame))/2.0f,
								   CGRectGetWidth(detailButton.frame),
								   CGRectGetHeight(detailButton.frame)
								   );
	[detailButton setFrame:detailRect];
	
	// set the district text
	[placeView setText:[m_data.m_place stringByAppendingString:@": "]];
	CGSize placeSz = [placeView.text sizeWithFont:placeView.font
									 constrainedToSize:CGSizeMake(S_PLACE_TEXT_WIDTH,S_ROW_HEIGHT) 
									 lineBreakMode:UILineBreakModeTailTruncation];
	
	[placeView setFrame:CGRectMake(S_CELL_HOFFSET, cellY, placeSz.width, S_ROW_HEIGHT)];
	
	[legView setFrame:CGRectMake(CGRectGetMaxX(placeView.frame) + S_CELL_HOFFSET,
								 cellY,
								 CGRectGetMinX(detailRect) - CGRectGetMaxX(placeView.frame) - (2*S_CELL_HOFFSET),
								 S_ROW_HEIGHT
								 )];
	
	LegislatorContainer *lc =  [[myGovAppDelegate sharedCongressData] districtRepresentative:m_data.m_place];
	NSString *legislatorName = [lc shortName];
	NSString *party = [lc party];
	
	// strip the title off the name
	NSString *legText = [[[NSString alloc] initWithFormat:@" %@ (%@)",
										   [legislatorName substringFromIndex:5],
										   party
						 ] autorelease];
	
	legView.textColor = [LegislatorContainer partyColor:party];
	[legView setText:legText];
	
	
	// next row!
	cellY += S_ROW_HEIGHT + S_CELL_VOFFSET;
	
	// put the rank cell in the second row
	CGRect rankRect = CGRectMake((2.0f*S_CELL_HOFFSET),
								 cellY, 
								 CGRectGetMinX(detailRect) - (4.0f*S_CELL_HOFFSET), 
								 S_ROW_HEIGHT);
	[rankView setFrame:rankRect];
	
	[rankView setText:[m_data rankStr]];
	
	// color high-spenders in red!
	if ( [m_data rankIsTop25Pct] )
	{
		rankView.font = RANK_FONT_BIGSPENDER;
		rankView.textColor = RANK_COLOR_BIGSPENDER;
	}
	else
	{
		rankView.font = RANK_FONT;
		rankView.textColor = RANK_COLOR;
	}
}


@end


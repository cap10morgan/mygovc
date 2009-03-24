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

enum
{
	eTAG_DETAIL     = 999,
	eTAG_RANK       = 998,
	eTAG_LEGISLATOR = 997, 
	eTAG_PLACE      = 996,
	eTAG_ACTIVITY   = 995,
};

static const CGFloat S_CELL_OFFSET = 7.0f;
static const CGFloat S_TABLE_TITLE_WIDTH = 15.0f;
static const CGFloat S_RANK_TEXT_WIDTH = 90.0f;
static const CGFloat S_PLACE_TEXT_WIDTH = 100.0f;


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)identifier detailTarget:(id)tgt detailSelector:(SEL)sel
{
	if ( self = [super initWithFrame:frame reuseIdentifier:identifier] ) 
	{
		m_data = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		CGFloat frameX = S_CELL_OFFSET;
		CGFloat frameY = 0.0f;
		CGFloat frameW = self.contentView.bounds.size.width - (frameX * 2.0f);
		CGFloat frameH = self.contentView.bounds.size.height - (frameY * 2.0f);
		
		// 
		// Detail button (next to table index)
		// 
		UIButton *detail = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[detail setTag:eTAG_DETAIL];
		//detail.showsTouchWhenHighlighted = YES;
		CGRect detailRect = CGRectMake( frameW - S_TABLE_TITLE_WIDTH - CGRectGetWidth(detail.frame) - S_CELL_OFFSET,
									    frameY + (frameH - CGRectGetHeight(detail.frame))/2.0f,
									    CGRectGetWidth(detail.frame),
									    CGRectGetHeight(detail.frame) );
		[detail setFrame:detailRect];
		
		// 
		// Rank/Dollars text field 
		// 
		CGRect rankRect = CGRectMake(CGRectGetMinX(detailRect) - S_RANK_TEXT_WIDTH - (2.0f*S_CELL_OFFSET),
									 frameY, 
									 S_RANK_TEXT_WIDTH, 
									 frameH);
		UILabel *rankView = [[UILabel alloc] initWithFrame:rankRect];
		rankView.backgroundColor = [UIColor clearColor];
		rankView.textColor = [UIColor blueColor]; //colorWithRed:0.3f green:0.45f blue:0.84f alpha:1.0f];
		rankView.font = [UIFont boldSystemFontOfSize:14.0f];
		rankView.textAlignment = UITextAlignmentRight;
		rankView.adjustsFontSizeToFitWidth = YES;
		[rankView setTag:eTAG_RANK];
		
		// 
		// Place text field (on the left side of the cell)
		// 
		CGRect placeRect = CGRectMake(S_CELL_OFFSET,
									  frameY, 
									  S_PLACE_TEXT_WIDTH, 
									  frameH);
		UILabel *placeView = [[UILabel alloc] initWithFrame:placeRect];
		placeView.backgroundColor = [UIColor clearColor];
		placeView.textColor = [UIColor blackColor];
		placeView.font = [UIFont boldSystemFontOfSize:14.0f];
		placeView.textAlignment = UITextAlignmentLeft;
		placeView.adjustsFontSizeToFitWidth = YES;
		[placeView setTag:eTAG_PLACE];
		
		
		// 
		// Legislator text box squeezes in between the place and rank
		// 
		CGRect legRect = CGRectMake( CGRectGetMaxX(placeRect) + S_CELL_OFFSET, 
									 frameY,
									 CGRectGetMinX(rankRect) - CGRectGetMaxX(placeRect) - (2*S_CELL_OFFSET),
									 frameH );
		UILabel *legView = [[UILabel alloc] initWithFrame:legRect];
		legView.backgroundColor = [UIColor clearColor];
		legView.textColor = [UIColor darkGrayColor];
		legView.font = [UIFont systemFontOfSize:12.0f];
		legView.textAlignment = UITextAlignmentCenter;
		legView.adjustsFontSizeToFitWidth = YES;
		[legView setTag:eTAG_LEGISLATOR];
		
		
		// set delegate for detail button press!
		[detail addTarget:tgt action:sel forControlEvents:UIControlEventTouchUpInside];
		
		// add views to cell view
		[self addSubview:rankView];
		[self addSubview:placeView];
		[self addSubview:legView];
		[self addSubview:detail];
		
		[rankView release];
		[placeView release];
		[legView release];
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
		
		[placeView setFrame:CGRectMake(S_CELL_OFFSET, 0.0f, placeSz.width, cellHeight)];
		
		[legView setFrame:CGRectMake(placeSz.width + (2.0f*S_CELL_OFFSET),
									 0.0f,
									 legSz.width,
									 cellHeight
									 )];
		
		[placeView setText:m_data.m_place];
		[legView setText:downloadStr];
		[rankView setText:@""];
		
		[detailButton setHidden:YES];
		[rankView setHidden:YES];
		
		// render a UIActivityView...
		if ( nil == aiView )
		{
			aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			aiView.hidesWhenStopped = YES;
			[aiView setFrame:CGRectMake(0.0f, 0.0f, cellHeight/2.0f, cellHeight/2.0f)];
			[aiView setCenter:CGPointMake(CGRectGetMaxX(legView.frame) + S_CELL_OFFSET + cellHeight/2.0f, cellHeight/2.0f)];
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
	
	CGFloat cellHeight = self.contentView.bounds.size.height;
	CGFloat cellWidth = 320.0f - (2.0f*S_CELL_OFFSET); //self.contentView.bounds.size.width - (2.0f*S_CELL_OFFSET);
	
	// put the detail button all the way to the edge of the frame
	CGRect detailRect = CGRectMake(cellWidth - CGRectGetWidth(detailButton.frame),
								   (cellHeight - CGRectGetHeight(detailButton.frame))/2.0f,
								   CGRectGetWidth(detailButton.frame),
								   CGRectGetHeight(detailButton.frame)
								  );
	[detailButton setFrame:detailRect];
	
	// put the rank cell next to the detail button
	CGRect rankRect = CGRectMake(CGRectGetMinX(detailRect) - S_RANK_TEXT_WIDTH - (2.0f*S_CELL_OFFSET),
								 0.0f, S_RANK_TEXT_WIDTH, cellHeight);
	[rankView setFrame:rankRect];
	
	// set place text, and get its size so we can re-size the 
	// legislator text to a maximum...
	[placeView setText:[StateAbbreviations nameFromAbbr:m_data.m_place]];
	
	CGSize placeSz = [placeView.text sizeWithFont:placeView.font
									 constrainedToSize:CGSizeMake(S_PLACE_TEXT_WIDTH,cellHeight) 
									 lineBreakMode:UILineBreakModeTailTruncation];
	
	[placeView setFrame:CGRectMake(S_CELL_OFFSET, 0.0f, placeSz.width, cellHeight)];
	
	[legView setFrame:CGRectMake(CGRectGetMaxX(placeView.frame) + S_CELL_OFFSET,
								 0.0f,
								 CGRectGetMinX(rankView.frame) - CGRectGetMaxX(placeView.frame) - (2*S_CELL_OFFSET),
								 cellHeight
								 )];
	
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	if ( nil != aiView ) { [aiView stopAnimating]; }
	
	NSString *legText;
	NSArray *senateMembers = [[myGovAppDelegate sharedCongressData] senateMembersInState:m_data.m_place];
	if ( nil == senateMembers ) 
	{
		legText = @"( - )"; // spacing text
		
		// resize the placeView width just in case we need more space...
		CGSize legSz = [legText sizeWithFont:legView.font
								constrainedToSize:CGSizeMake(S_PLACE_TEXT_WIDTH,cellHeight) 
								lineBreakMode:UILineBreakModeTailTruncation];
		[placeView setFrame:CGRectMake(S_CELL_OFFSET,
									   0.0f,
									   CGRectGetMinX(rankView.frame) - legSz.width - (2.0f*S_CELL_OFFSET),
									   cellHeight)];
		[legView setFrame:CGRectMake(CGRectGetMaxX(placeView.frame) + S_CELL_OFFSET,
									 0.0f, legSz.width, cellHeight)];
		legText = @""; // no text displayed
	}
	else if ( [senateMembers count] < 2 && [senateMembers count] > 0 )
	{
		legText = [[[NSString alloc] initWithFormat:@"(%@)",
											[[senateMembers objectAtIndex:0] lastname]
					] autorelease];
	}
	else
	{
		legText = [[[NSString alloc] initWithFormat:@"(%@/%@)",
											[[senateMembers objectAtIndex:0] lastname],
											[[senateMembers objectAtIndex:1] lastname]
				   ] autorelease];
	}
	
	NSUInteger rankTotal = [[StateAbbreviations abbrList] count];
		
	CGFloat millionsOfDollars = m_data.m_totalDollarsObligated / 1000000;
	NSString *rankText = [[[NSString alloc] initWithFormat:@"$%.1fM [%d/%d]",
											millionsOfDollars,
											m_data.m_rank,
											rankTotal
						  ] autorelease];
	
	[legView setText:legText];
	[rankView setText:rankText];
	
	// color high-spenders in red!
	if ( millionsOfDollars > 0.1 && ((CGFloat)(m_data.m_rank) / (CGFloat)rankTotal) <= 0.25 )
	{
		rankView.textColor = [UIColor redColor];
	}
	else
	{
		rankView.textColor = [UIColor blueColor];
	}
}


- (void)layoutDistrictData
{
	// Grab all our text views
	UILabel *rankView = (UILabel *)[self viewWithTag:eTAG_RANK];
	UILabel *placeView = (UILabel *)[self viewWithTag:eTAG_PLACE];
	UILabel *legView = (UILabel *)[self viewWithTag:eTAG_LEGISLATOR];
	UIButton *detailButton = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	
	CGFloat cellHeight = self.contentView.bounds.size.height;
	CGFloat cellWidth = 320.0f - (2.0f*S_CELL_OFFSET); //self.contentView.bounds.size.width - (2.0f*S_CELL_OFFSET);
	
	// put the detail button close to the cell index titles
	CGRect detailRect = CGRectMake( cellWidth - S_TABLE_TITLE_WIDTH - CGRectGetWidth(detailButton.frame) - S_CELL_OFFSET,
								   (cellHeight - CGRectGetHeight(detailButton.frame))/2.0f,
								   CGRectGetWidth(detailButton.frame),
								   CGRectGetHeight(detailButton.frame) );
	[detailButton setFrame:detailRect];
	
	// put the rank cell next to the detail button
	CGRect rankRect = CGRectMake(CGRectGetMinX(detailRect) - S_RANK_TEXT_WIDTH - (2.0f*S_CELL_OFFSET),
								 0.0f, S_RANK_TEXT_WIDTH, cellHeight);
	[rankView setFrame:rankRect];
	
	// set the district text
	[placeView setText:m_data.m_place];
	CGSize placeSz = [placeView.text sizeWithFont:placeView.font
									 constrainedToSize:CGSizeMake(S_PLACE_TEXT_WIDTH,cellHeight) 
									 lineBreakMode:UILineBreakModeTailTruncation];
	
	[placeView setFrame:CGRectMake(S_CELL_OFFSET, 0.0f, placeSz.width, cellHeight)];
	
	[legView setFrame:CGRectMake(CGRectGetMaxX(placeView.frame) + S_CELL_OFFSET,
								 0.0f,
								 CGRectGetMinX(rankView.frame) - CGRectGetMaxX(placeView.frame) - (2*S_CELL_OFFSET),
								 cellHeight
								 )];
	
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	if ( nil != aiView ) { [aiView stopAnimating]; }
	
	NSString *legislatorName = [[[myGovAppDelegate sharedCongressData] districtRepresentative:m_data.m_place] shortName];
	// strip the title off the name
	NSString *legText = [[[NSString alloc] initWithFormat:@"(%@)",
										   [legislatorName substringFromIndex:5]
						 ] autorelease];
	
	NSUInteger rankTotal = [[[myGovAppDelegate sharedSpendingData] congressionalDistricts] count];
		
	CGFloat millionsOfDollars = m_data.m_totalDollarsObligated / 1000000;
	NSString *rankText = [[[NSString alloc] initWithFormat:@"$%.1fM [%d/%d]",
											millionsOfDollars,
											m_data.m_rank,	
											rankTotal
						  ] autorelease];
	
	[legView setText:legText];
	[rankView setText:rankText];
	
	// color high-spenders in red!
	if ( millionsOfDollars > 0.1 && ((CGFloat)(m_data.m_rank) / (CGFloat)rankTotal) <= 0.25 )
	{
		rankView.textColor = [UIColor redColor];
	}
	else
	{
		rankView.textColor = [UIColor blueColor];
	}
}


@end


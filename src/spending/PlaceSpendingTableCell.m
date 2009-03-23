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

@implementation PlaceSpendingTableCell


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
		//detail.showsTouchWhenHighlighted = YES;
		CGRect detailRect = CGRectMake( frameW - S_TABLE_TITLE_WIDTH - CGRectGetWidth(detail.frame),
									    frameY + (frameH - CGRectGetHeight(detail.frame))/2.0f,
									    CGRectGetWidth(detail.frame),
									    CGRectGetHeight(detail.frame) );
		[detail setFrame:detailRect];
		
		// 
		// Rank/Dollars text field 
		// 
		CGRect rankRect = CGRectMake(CGRectGetMinX(detailRect) - S_RANK_TEXT_WIDTH - S_CELL_OFFSET, 
									 frameY, 
									 S_RANK_TEXT_WIDTH + S_CELL_OFFSET, 
									 frameH);
		UILabel *rankView = [[UILabel alloc] initWithFrame:rankRect];
		rankView.backgroundColor = [UIColor clearColor];
		rankView.textColor = [UIColor colorWithRed:0.3f green:0.45f blue:0.84f alpha:1.0f];
		rankView.font = [UIFont boldSystemFontOfSize:14.0f];
		rankView.textAlignment = UITextAlignmentRight;
		rankView.adjustsFontSizeToFitWidth = YES;
		[rankView setTag:999];
		
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
		placeView.textAlignment = UITextAlignmentCenter;
		placeView.adjustsFontSizeToFitWidth = YES;
		[placeView setTag:998];
		
		
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
		legView.textAlignment = UITextAlignmentLeft;
		legView.adjustsFontSizeToFitWidth = YES;
		[legView setTag:997];
		
		
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
	[m_data release];
	[super dealloc];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	
	// Configure the view for the selected state
}


- (void)setPlaceData:(PlaceSpendingData *)data 
{
	if ( nil == data ) return;
	
	[m_data release];
	m_data = [data retain];
	
	// Grab all our text views
	UILabel *rankView = (UILabel *)[self viewWithTag:999];
	UILabel *placeView = (UILabel *)[self viewWithTag:998];
	UILabel *legView = (UILabel *)[self viewWithTag:997];
	
	SpendingPlaceType type = m_data.m_placeType;
	
	// set place text, and get its size so we can re-size the 
	// legislator text to a maximum...
	switch ( type )
	{
		default:
		case eSPT_District:
			[placeView setText:m_data.m_place];
			break;
		case eSPT_State:
			[placeView setText:[StateAbbreviations nameFromAbbr:m_data.m_place]];
			break;
	}
	CGSize placeSz = [placeView.text sizeWithFont:placeView.font
									 constrainedToSize:CGSizeMake(S_PLACE_TEXT_WIDTH,CGRectGetHeight(placeView.frame)) 
									 lineBreakMode:UILineBreakModeTailTruncation];
	[placeView setFrame:CGRectMake(S_CELL_OFFSET,
								   0.0f,
								   placeSz.width,
								   CGRectGetHeight(placeView.frame)
								  )];
	
	[legView setFrame:CGRectMake(CGRectGetMaxX(placeView.frame) + S_CELL_OFFSET,
								 CGRectGetMinY(placeView.frame),
								 CGRectGetMinX(rankView.frame) - CGRectGetMaxX(placeView.frame) - (2*S_CELL_OFFSET),
								 CGRectGetHeight(placeView.frame)
								 )];
	
	NSUInteger rankTotal = 0;
	NSString *legText;
	NSString *rankText;
	
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:111];
	if ( ![m_data isDataAvailable] )
	{
		// render a UIActivityView...
		if ( nil == aiView )
		{
			aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			aiView.hidesWhenStopped = YES;
			[aiView setFrame:CGRectMake(0.0f, 0.0f, placeSz.height, placeSz.height)];
			[aiView setCenter:CGPointMake(CGRectGetMaxX(legView.frame) + placeSz.height, CGRectGetHeight(legView.frame)/2.0f)];
			[aiView setTag:111];
			[self addSubview:aiView];
			[aiView release];
		}
		[aiView startAnimating];
		
		legText = @"downloading...";
		rankText = @"";
	}
	else
	{
		if ( nil != aiView ) { [aiView stopAnimating]; }
		
		switch ( type )
		{
			default:
			case eSPT_State:
				{
					NSArray *senateMembers = [[myGovAppDelegate sharedCongressData] senateMembersInState:m_data.m_place];
					if ( (nil == senateMembers) || ([senateMembers count] < 2) ) 
					{
						static LegislatorContainer *s_lc1, *s_lc2 = NULL;
						static id s_lc[2];
						if ( NULL == s_lc1 )
						{
							s_lc1 = [[LegislatorContainer alloc] init]; 
							[s_lc1 addKey:@"lastname" withValue:@""]; 
							s_lc[0] = s_lc1;
						}
						if ( NULL == s_lc2 )
						{
							s_lc2 = [[LegislatorContainer alloc] init]; 
							[s_lc2 addKey:@"lastname" withValue:@""]; 
							s_lc[1] = s_lc2;
						}
						senateMembers = [NSArray arrayWithObjects:s_lc count:2];
					}
					legText = [[[NSString alloc] initWithFormat:@"(%@/%@)",
												 [[senateMembers objectAtIndex:0] lastname],
												 [[senateMembers objectAtIndex:1] lastname]
								] autorelease];
					rankTotal = [[StateAbbreviations abbrList] count];
				} // case eSPT_State
				break;
			
			case eSPT_District:
				{
					NSString *legislatorName = [[[myGovAppDelegate sharedCongressData] districtRepresentative:m_data.m_place] shortName];
					legText = [[[NSString alloc] initWithFormat:@"(%@)",
														   legislatorName
									] autorelease];
					rankTotal = [[[myGovAppDelegate sharedSpendingData] congressionalDistricts] count];
				} // case eSPT_District
				break;
		} // switch ( type )
		
		
		CGFloat millionsOfDollars = m_data.m_totalDollarsObligated / 1000000;
		rankText = [[[NSString alloc] initWithFormat:@"$%.1fM [%d/%d]",
									  millionsOfDollars,
									  m_data.m_rank,
									  rankTotal
					] autorelease];
		
	} // if ( [m_data isDataAvailable] )
	
	[legView setText:legText];
	[rankView setText:rankText];
	
	// color high-spenders in red!
	if ( m_data.m_totalDollarsObligated > 100000 && ((CGFloat)(m_data.m_rank) / (CGFloat)rankTotal) <= 0.25 )
	{
		rankView.textColor = [UIColor redColor];
	}
	else
	{
		rankView.textColor = [UIColor colorWithRed:0.3f green:0.45f blue:0.84f alpha:1.0f];
	}
}



@end

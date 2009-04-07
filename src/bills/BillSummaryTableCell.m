//
//  BillSummaryTableCell.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BillSummaryTableCell.h"
#import "BillContainer.h"
#import "LegislatorContainer.h"

@implementation BillSummaryTableCell

@synthesize m_bill;

enum
{
	eTAG_TITLE        = 999,
	eTAG_STATUSLABEL  = 998,
	eTAG_STATUS       = 997,
	eTAG_VOTESTATUS   = 996,
	eTAG_HISTORYLABEL = 995,
	eTAG_HISTORY1     = 994,
	eTAG_HISTORY2     = 993,
	eTAG_HISTORY3     = 992,
	eTAG_HISTORY4     = 991,
	eTAG_HISTORY5     = 990,
	eTAG_SPONSOR      = 989,
};

static const int S_MAX_HISTORY_ITEMS = 5;

static const CGFloat S_CELL_BOUNDS = 15.0f;
static const CGFloat S_CELL_PADDING = 6.0f;
static const CGFloat S_TITLE_HEIGHT = 60.0f;
static const CGFloat S_LABEL_WIDTH = 50.0f;
static const CGFloat S_LABEL_HEIGHT = 15.0f;
static const CGFloat S_VOTE_WIDTH = 55.0f;

#define D_TITLE_FONT [UIFont systemFontOfSize:14.0f]
#define D_LABEL_FONT [UIFont boldSystemFontOfSize:12.0f]
#define D_STATUS_FONT [UIFont italicSystemFontOfSize:14.0f]
#define D_STD_FONT   [UIFont systemFontOfSize:10.0f]


+ (CGFloat)getCellHeightForBill:(BillContainer *)bill
{
	NSString *title = bill.m_title;
	CGSize titleSz = [title sizeWithFont:D_TITLE_FONT 
							constrainedToSize:CGSizeMake(320.0f - (2.0f*S_CELL_BOUNDS),S_TITLE_HEIGHT) 
							lineBreakMode:UILineBreakModeWordWrap];
	
	CGFloat height = S_CELL_PADDING + titleSz.height + S_CELL_PADDING + // title
					 S_LABEL_HEIGHT + S_CELL_PADDING +  // sponsor 
					 S_LABEL_HEIGHT + S_CELL_PADDING;   // status
	
	// history
	NSInteger numActions = [[bill billActions] count];
	height += (S_LABEL_HEIGHT + S_CELL_PADDING) * (numActions > S_MAX_HISTORY_ITEMS ? S_MAX_HISTORY_ITEMS : numActions);
	
	return height;
}


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		m_bill = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		self.backgroundColor = [UIColor clearColor];
		if ( nil != self.backgroundView )
		{
			self.contentView.backgroundColor = [UIColor clearColor];
			self.backgroundView.backgroundColor = [UIColor colorWithRed:0.1f green:0.1f blue:0.15f alpha:1.0f];
		}
		else
		{
			self.contentView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:0.9f];
		}
		
		CGFloat frameX = S_CELL_BOUNDS;
		CGFloat frameY = S_CELL_PADDING;
		CGFloat frameW = self.contentView.bounds.size.width - (frameX * 2.0f);
		//CGFloat frameH = self.contentView.bounds.size.height - (frameY * 2.0f);
		
		CGRect titleRect = CGRectMake(frameX,frameY,frameW,S_TITLE_HEIGHT);
		UILabel *titleView = [[UILabel alloc] initWithFrame:titleRect];
		titleView.backgroundColor = [UIColor clearColor];
		titleView.textColor = [UIColor whiteColor];
		titleView.highlightedTextColor =[UIColor blackColor];
		titleView.font = D_TITLE_FONT;
		titleView.textAlignment = UITextAlignmentLeft;
		titleView.lineBreakMode = UILineBreakModeWordWrap;
		titleView.numberOfLines = 5;
		[titleView setTag:eTAG_TITLE];
		[self addSubview:titleView];
		[titleView release];
		
		frameY = CGRectGetMaxY(titleRect) + S_CELL_PADDING;
		
		CGRect sponsorRect = CGRectMake(frameX, frameY, frameW, S_LABEL_HEIGHT);
		UILabel *sponsorLbl = [[UILabel alloc] initWithFrame:sponsorRect];
		sponsorLbl.backgroundColor = [UIColor clearColor];
		sponsorLbl.textColor = [UIColor yellowColor];
		sponsorLbl.highlightedTextColor =[UIColor darkGrayColor];
		sponsorLbl.font = D_LABEL_FONT;
		sponsorLbl.textAlignment = UITextAlignmentLeft;
		sponsorLbl.adjustsFontSizeToFitWidth = YES;
		sponsorLbl.text = @"Sponsor:";
		[sponsorLbl setTag:eTAG_SPONSOR];
		[self addSubview:sponsorLbl];
		[sponsorLbl release];
		
		frameY = CGRectGetMaxY(sponsorRect) + S_CELL_PADDING;
		
		CGRect labelRect = CGRectMake(frameX, frameY, S_LABEL_WIDTH, S_LABEL_HEIGHT);
		UILabel *statusLbl = [[UILabel alloc] initWithFrame:labelRect];
		statusLbl.backgroundColor = [UIColor clearColor];
		statusLbl.textColor = [UIColor yellowColor];
		statusLbl.highlightedTextColor =[UIColor darkGrayColor];
		statusLbl.font = D_LABEL_FONT;
		statusLbl.textAlignment = UITextAlignmentLeft;
		statusLbl.adjustsFontSizeToFitWidth = YES;
		statusLbl.text = @"Status:";
		[statusLbl setTag:eTAG_STATUSLABEL];
		[self addSubview:statusLbl];
		[statusLbl release];
		
		CGRect voteRect = CGRectMake(frameW - S_VOTE_WIDTH,
									 frameY,
									 S_VOTE_WIDTH,
									 S_LABEL_HEIGHT
		);
		UILabel *voteView = [[UILabel alloc] initWithFrame:voteRect];
		voteView.backgroundColor = [UIColor clearColor];
		voteView.textColor = [UIColor blueColor];
		voteView.highlightedTextColor =[UIColor darkGrayColor];
		voteView.font = D_LABEL_FONT;
		voteView.textAlignment = UITextAlignmentCenter;
		voteView.adjustsFontSizeToFitWidth = YES;
		[voteView setTag:eTAG_VOTESTATUS];
		[self addSubview:voteView];
		[voteView release];
		
		CGRect statusRect = CGRectMake(CGRectGetMaxX(labelRect) + S_CELL_PADDING,
									   frameY,
									   CGRectGetMinX(voteRect) - CGRectGetMaxX(labelRect) - (2.0f*S_CELL_PADDING),
									   S_LABEL_HEIGHT
		);
		UILabel *statusView = [[UILabel alloc] initWithFrame:statusRect];
		statusView.backgroundColor = [UIColor clearColor];
		statusView.textColor = [UIColor yellowColor];
		statusView.highlightedTextColor =[UIColor darkGrayColor];
		statusView.font = D_STATUS_FONT;
		statusView.textAlignment = UITextAlignmentLeft;
		statusView.adjustsFontSizeToFitWidth = YES;
		[statusView setTag:eTAG_STATUS];
		[self addSubview:statusView];
		[statusView release];
		
		frameY = (CGRectGetMaxY(labelRect) + S_CELL_PADDING);
		
		CGRect histLblFrame = CGRectMake(frameX, frameY, S_LABEL_WIDTH, S_LABEL_HEIGHT);
		UILabel *histLblView = [[UILabel alloc] initWithFrame:histLblFrame];
		histLblView.backgroundColor = [UIColor clearColor];
		histLblView.textColor = [UIColor yellowColor];
		histLblView.highlightedTextColor =[UIColor darkGrayColor];
		histLblView.font = D_LABEL_FONT;
		histLblView.textAlignment = UITextAlignmentLeft;
		histLblView.adjustsFontSizeToFitWidth = YES;
		histLblView.text = @" ";
		[histLblView setTag:eTAG_HISTORYLABEL];
		[self addSubview:histLblView];
		[histLblView release];
		
		CGFloat histX = CGRectGetMaxX(histLblFrame) + S_CELL_PADDING;
		CGFloat histY = frameY;
		CGFloat histW = 320.0f - histX - S_CELL_PADDING;
		CGFloat histH = S_LABEL_HEIGHT;
		
		// history items
		for ( int ii = 0; ii < S_MAX_HISTORY_ITEMS; ++ii )
		{
			CGRect histRect = CGRectMake(histX,histY,histW,histH);
			UILabel *histView = [[UILabel alloc] initWithFrame:histRect];
			histView.backgroundColor = [UIColor clearColor];
			histView.textColor = [UIColor whiteColor];
			histView.highlightedTextColor = [UIColor darkGrayColor];
			histView.font = D_STD_FONT;
			histView.textAlignment = UITextAlignmentLeft;
			histView.adjustsFontSizeToFitWidth = NO;
			histView.lineBreakMode = UILineBreakModeTailTruncation;
			histView.text = @" ";
			[histView setTag:(eTAG_HISTORY1 - ii)];
			[self addSubview:histView];
			[histView release];
			
			histY = (CGRectGetMaxY(histRect) + S_CELL_PADDING);
		}
	}
	return self;
}


- (void)dealloc 
{
	[m_bill release];
	[super dealloc];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	UILabel *titleView = (UILabel *)[self viewWithTag:eTAG_TITLE];
	[titleView setHighlighted:selected];
	UILabel *statusLbl = (UILabel *)[self viewWithTag:eTAG_STATUSLABEL];
	[statusLbl setHighlighted:selected];
	UILabel *voteView = (UILabel *)[self viewWithTag:eTAG_VOTESTATUS];
	[voteView setHighlighted:selected];
	UILabel *statusView = (UILabel *)[self viewWithTag:eTAG_STATUS];
	[statusView setHighlighted:selected];
}


- (void)setContentFromBill:(BillContainer *)container
{
	[m_bill release]; m_bill = nil;
	
	if ( nil == container )
	{
		UILabel *titleView = (UILabel *)[self viewWithTag:eTAG_TITLE];
		[titleView setText:@""];
		UILabel *sponsorView = (UILabel *)[self viewWithTag:eTAG_SPONSOR];
		[sponsorView setText:@""];
		UILabel *statusLbl = (UILabel *)[self viewWithTag:eTAG_STATUSLABEL];
		[statusLbl setText:@""];
		UILabel *voteView = (UILabel *)[self viewWithTag:eTAG_VOTESTATUS];
		[voteView setText:@""];
		UILabel *statusView = (UILabel *)[self viewWithTag:eTAG_STATUS];
		[statusView setText:@""];
		UILabel *histLblView = (UILabel *)[self viewWithTag:eTAG_HISTORYLABEL];
		[histLblView setText:@""];
		return;
	}
	
	m_bill = [container retain];
	
	UILabel *titleView = (UILabel *)[self viewWithTag:eTAG_TITLE];
	// trim off the characters before the first space - they're the title...
	NSString *titleStr = [m_bill.m_title substringFromIndex:([m_bill.m_title rangeOfString:@" "].location + 1)];
	CGSize titleSz = [titleStr sizeWithFont:D_TITLE_FONT 
									 constrainedToSize:CGSizeMake(320.0f - (2.0f*S_CELL_BOUNDS),S_TITLE_HEIGHT) 
									 lineBreakMode:UILineBreakModeTailTruncation];
	[titleView setFrame:CGRectMake(S_CELL_BOUNDS,S_CELL_PADDING,titleSz.width,titleSz.height)];
	[titleView setText:titleStr];
		
	CGRect titleRect = titleView.frame;
	CGFloat statusY = CGRectGetMaxY(titleRect) + S_CELL_PADDING;
	
	UILabel *sponsorView = (UILabel *)[self viewWithTag:eTAG_SPONSOR];
	LegislatorContainer *sponsor = [container sponsor];
	CGRect tmpRect = CGRectMake(S_CELL_BOUNDS, statusY, 320.0f - (2.0f*S_CELL_BOUNDS), S_LABEL_HEIGHT);
	[sponsorView setFrame:tmpRect];
	[sponsorView setText:[NSString stringWithFormat:@"Sponsor: %@ (%@, %@)",
									[sponsor shortName],
									[sponsor party],
									[sponsor state]
						 ]
	];
	if ( [[sponsor party] isEqualToString:@"R"] )
	{
		sponsorView.textColor = [UIColor redColor];
	}
	else if ( [[sponsor party] isEqualToString:@"D"] )
	{
		sponsorView.textColor = [UIColor blueColor];
	}
	else
	{
		sponsorView.textColor = [UIColor yellowColor];
	}
	
	statusY = CGRectGetMaxY(tmpRect) + S_CELL_PADDING;
	
	tmpRect = CGRectMake(CGRectGetMinX(titleRect), statusY, S_LABEL_WIDTH, S_LABEL_HEIGHT);
	UILabel *statusLbl = (UILabel *)[self viewWithTag:eTAG_STATUSLABEL];
	[statusLbl setFrame:tmpRect];
	[statusLbl setText:@"Status:"];
	
	UILabel *voteView = (UILabel *)[self viewWithTag:eTAG_VOTESTATUS];
	if ( eVote_novote == [[m_bill lastBillAction] m_voteResult] )
	{
		voteView.text = @"";
		[voteView setFrame:CGRectZero];
	}
	else
	{
		tmpRect = CGRectMake(CGRectGetMaxX(titleRect) - S_VOTE_WIDTH, statusY, S_VOTE_WIDTH, S_LABEL_HEIGHT);
		[voteView setFrame:tmpRect];
		NSString *voteTxt;
		UIColor *voteColor;
		if ( eVote_passed == [[m_bill lastBillAction] m_voteResult] )
		{
			voteTxt = @"Passed";
			voteColor = [UIColor greenColor];
		}
		else
		{
			voteTxt = @"Failed";
			voteColor = [UIColor redColor];
		}
		[voteView setText:voteTxt];
		voteView.textColor = voteColor;
	}
	
	CGFloat statusWidth = (CGRectGetWidth(voteView.frame) > 0) ? 
							CGRectGetMinX(voteView.frame) - CGRectGetMaxX(statusLbl.frame) - (2.0f*S_CELL_PADDING) :
							CGRectGetMaxX(titleRect) - CGRectGetMaxX(statusLbl.frame) - (2.0f*S_CELL_PADDING);
	tmpRect = CGRectMake(CGRectGetMaxX(statusLbl.frame) + S_CELL_PADDING,
						 statusY,
						 statusWidth,
						 S_LABEL_HEIGHT);
	UILabel *statusView = (UILabel *)[self viewWithTag:eTAG_STATUS];
	[statusView setFrame:tmpRect];
	[statusView setText:m_bill.m_status];
	
	// 
	// set bill history info!
	// 
	UILabel *histLblView = (UILabel *)[self viewWithTag:eTAG_HISTORYLABEL];
	[histLblView setFrame:CGRectMake(S_CELL_BOUNDS,
									 CGRectGetMaxY(statusView.frame) + S_CELL_PADDING,
									 S_LABEL_WIDTH,
									 S_LABEL_HEIGHT
									 )];
	
	CGFloat histX = CGRectGetMaxX(histLblView.frame) + S_CELL_PADDING;
	CGFloat histY = CGRectGetMinY(histLblView.frame);
	CGFloat histW = 320.0f - histX - S_CELL_PADDING;
	CGFloat histH = S_LABEL_HEIGHT;
	
	NSArray *history = [container billActions];
	if ( [history count] > 0 )
	{
		[histLblView setText: @"History:"];
		int hTag = eTAG_HISTORY1;
		UILabel *hlbl;
		for ( int ii = 0; ii < S_MAX_HISTORY_ITEMS; ++ii )
		{
			hlbl = (UILabel *)[self viewWithTag:(hTag - ii)];
			[hlbl setFrame:CGRectMake(histX,histY,histW,histH)];
			histY = (CGRectGetMaxY(hlbl.frame) + S_CELL_PADDING);
			if ( ii < [history count] )
			{
				[hlbl setText:[[history objectAtIndex:ii] shortDescrip]];
			}
			else
			{
				[hlbl setText:@""];
			}
		}
	}
	else
	{
		[histLblView setText:@""];
		int hTag = eTAG_HISTORY1;
		UILabel *hlbl;
		for ( int ii = 0; ii < S_MAX_HISTORY_ITEMS; ++ii )
		{
			hlbl = (UILabel *)[self viewWithTag:(hTag - ii)];
			[hlbl setFrame:CGRectMake(histX,histY,histW,histH)];
			histY = (CGRectGetMaxY(hlbl.frame) + S_CELL_PADDING);
			[hlbl setText:@""];
		}
	}
	
}


@end

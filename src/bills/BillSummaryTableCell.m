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
	eTAG_BILLNUM      = 999,
	eTAG_SPONSOR      = 998,
	eTAG_DESCRIP      = 997,
	eTAG_STATUSLABEL  = 996,
	eTAG_VOTESTATUS   = 995,
	eTAG_DETAIL       = 994,
};

static const CGFloat S_CELL_HPADDING = 7.0f;
static const CGFloat S_CELL_VPADDING = 3.0f;

static const CGFloat S_BILLNUM_WIDTH = 120.0f;
static const CGFloat S_DESCRIP_HEIGHT = 80.0f;

static const CGFloat S_STATUS_WIDTH = 180.0f;
static const CGFloat S_VOTE_WIDTH = 55.0f;

static const CGFloat S_ROW_HEIGHT = 25.0f;

#define D_BILLNUM_FONT [UIFont boldSystemFontOfSize:16.0f]
#define D_SPONSOR_FONT [UIFont systemFontOfSize:16.0f]
#define D_DESCRIP_FONT [UIFont systemFontOfSize:16.0f]
#define D_STATUS_FONT [UIFont italicSystemFontOfSize:14.0f]
#define D_VOTE_FONT [UIFont boldSystemFontOfSize:14.0f]

#define D_BILLNUM_COLOR [UIColor blackColor]
#define D_SPONSOR_COLOR [UIColor blackColor]
#define D_DESCRIP_COLOR [UIColor darkGrayColor]
#define D_STATUS_COLOR [UIColor blackColor]
#define D_VOTE_COLOR [UIColor darkGrayColor]


+ (CGFloat)getCellHeightForBill:(BillContainer *)bill
{
	NSString *descrip = bill.m_title;
	CGSize descripSz = [descrip sizeWithFont:D_DESCRIP_FONT 
							constrainedToSize:CGSizeMake(320.0f - (3.0f*S_CELL_HPADDING) - 32.0f,S_DESCRIP_HEIGHT + S_ROW_HEIGHT) 
							lineBreakMode:UILineBreakModeWordWrap];
	
	CGFloat height = S_ROW_HEIGHT + S_CELL_VPADDING + // bill number + sponsor
					 descripSz.height + S_CELL_VPADDING + // bill title/descrip
					 S_ROW_HEIGHT + S_CELL_VPADDING;   // status
	
	return height;
}


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		m_bill = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		self.backgroundColor = [UIColor clearColor];
		
		// 
		// Detail button (next to table index)
		// 
		UIButton *detail = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[detail setTag:eTAG_DETAIL];
		[self addSubview:detail];
		
		UILabel *billNumView = [[UILabel alloc] initWithFrame:CGRectZero];
		billNumView.backgroundColor = [UIColor clearColor];
		billNumView.textColor = D_BILLNUM_COLOR;
		billNumView.highlightedTextColor =[UIColor blackColor];
		billNumView.font = D_BILLNUM_FONT;
		billNumView.textAlignment = UITextAlignmentLeft;
		[billNumView setTag:eTAG_BILLNUM];
		[self addSubview:billNumView];
		[billNumView release];
		
		UILabel *sponsorView = [[UILabel alloc] initWithFrame:CGRectZero];
		sponsorView.backgroundColor = [UIColor clearColor];
		sponsorView.textColor = D_SPONSOR_COLOR;
		sponsorView.highlightedTextColor =[UIColor blackColor];
		sponsorView.font = D_SPONSOR_FONT;
		sponsorView.textAlignment = UITextAlignmentLeft;
		sponsorView.adjustsFontSizeToFitWidth = YES;
		[sponsorView setTag:eTAG_SPONSOR];
		[self addSubview:sponsorView];
		[sponsorView release];
		
		UILabel *descripView = [[UILabel alloc] initWithFrame:CGRectZero];
		descripView.backgroundColor = [UIColor clearColor];
		descripView.textColor = D_DESCRIP_COLOR;
		descripView.highlightedTextColor =[UIColor blackColor];
		descripView.font = D_DESCRIP_FONT;
		descripView.lineBreakMode = UILineBreakModeWordWrap;
		descripView.numberOfLines = 5;
		descripView.textAlignment = UITextAlignmentLeft;
		descripView.adjustsFontSizeToFitWidth = YES;
		[descripView setTag:eTAG_DESCRIP];
		[self addSubview:descripView];
		[descripView release];
		
		UILabel *statusLbl = [[UILabel alloc] initWithFrame:CGRectZero];
		statusLbl.backgroundColor = [UIColor clearColor];
		statusLbl.textColor = D_STATUS_COLOR;
		statusLbl.highlightedTextColor =[UIColor blackColor];
		statusLbl.font = D_STATUS_FONT;
		statusLbl.textAlignment = UITextAlignmentLeft;
		statusLbl.adjustsFontSizeToFitWidth = YES;
		[statusLbl setTag:eTAG_STATUSLABEL];
		[self addSubview:statusLbl];
		[statusLbl release];
		
		UILabel *voteView = [[UILabel alloc] initWithFrame:CGRectZero];
		voteView.backgroundColor = [UIColor clearColor];
		voteView.textColor = D_VOTE_COLOR;
		voteView.highlightedTextColor =[UIColor blackColor];
		voteView.font = D_VOTE_FONT;
		voteView.textAlignment = UITextAlignmentCenter;
		voteView.adjustsFontSizeToFitWidth = YES;
		[voteView setTag:eTAG_VOTESTATUS];
		[self addSubview:voteView];
		[voteView release];
		
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
	
	UILabel *billNumView = (UILabel *)[self viewWithTag:eTAG_BILLNUM];
	[billNumView setHighlighted:selected];
	UILabel *sponsorView = (UILabel *)[self viewWithTag:eTAG_SPONSOR];
	[sponsorView setHighlighted:selected];
	UILabel *descripView = (UILabel *)[self viewWithTag:eTAG_DESCRIP];
	[descripView setHighlighted:selected];
	UILabel *statusLbl = (UILabel *)[self viewWithTag:eTAG_STATUSLABEL];
	[statusLbl setHighlighted:selected];
	UILabel *voteView = (UILabel *)[self viewWithTag:eTAG_VOTESTATUS];
	[voteView setHighlighted:selected];
}


- (void)setContentFromBill:(BillContainer *)container
{
	[m_bill release]; m_bill = nil;
	
	if ( nil == container )
	{
		UIButton *detailButton = (UIButton *)[self viewWithTag:eTAG_DETAIL];
		[detailButton setHidden:YES];
		UILabel *billNumView = (UILabel *)[self viewWithTag:eTAG_BILLNUM];
		[billNumView setText:@""];
		UILabel *sponsorView = (UILabel *)[self viewWithTag:eTAG_SPONSOR];
		[sponsorView setText:@""];
		UILabel *descripView = (UILabel *)[self viewWithTag:eTAG_DESCRIP];
		[descripView setText:@""];
		UILabel *statusLbl = (UILabel *)[self viewWithTag:eTAG_STATUSLABEL];
		[statusLbl setText:@""];
		UILabel *voteView = (UILabel *)[self viewWithTag:eTAG_VOTESTATUS];
		[voteView setText:@""];
		return;
	}
	
	m_bill = [container retain];
	
	UIButton *detailButton = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	
	CGFloat cellWidth = 320.0f - CGRectGetWidth(detailButton.frame) - (3.0f*S_CELL_HPADDING);
	CGFloat cellY = S_CELL_VPADDING;
	
	// 
	// Bill Number 
	// 
	UILabel *billNumView = (UILabel *)[self viewWithTag:eTAG_BILLNUM];
	NSString *billNumStr = [m_bill getShortTitle];
	CGSize billNumSz = [billNumStr sizeWithFont:D_BILLNUM_FONT
								   constrainedToSize:CGSizeMake(S_BILLNUM_WIDTH,S_ROW_HEIGHT) 
								   lineBreakMode:UILineBreakModeTailTruncation];
	[billNumView setFrame:CGRectMake(S_CELL_HPADDING,cellY,billNumSz.width,S_ROW_HEIGHT)];
	[billNumView setText:billNumStr];
	
	// 
	// Sponsor
	// 
	LegislatorContainer *sponsor = [m_bill sponsor];
	UILabel *sponsorView = (UILabel *)[self viewWithTag:eTAG_SPONSOR];
	CGRect sponsorRect = CGRectMake(CGRectGetMaxX(billNumView.frame) + S_CELL_HPADDING,
									cellY,
									cellWidth - billNumSz.width - (2.0f*S_CELL_HPADDING),
									S_ROW_HEIGHT
	);
	[sponsorView setFrame:sponsorRect];
	
	NSString *sponsorTxt = [NSString stringWithFormat:@"%@ (%@, %@)",
											[sponsor shortName],
											[sponsor party],
											[sponsor state]
							];
	[sponsorView setText:sponsorTxt];
	sponsorView.textColor = [LegislatorContainer partyColor:[sponsor party]];
	
	// next row
	cellY = CGRectGetMaxY(sponsorRect) + S_CELL_VPADDING;
	
	// 
	// Bill title/description
	// 
	UILabel *descripView = (UILabel *)[self viewWithTag:eTAG_DESCRIP];
	// trim off the characters before the first space - they're the title...
	NSString *descripStr = [m_bill.m_title substringFromIndex:([m_bill.m_title rangeOfString:@" "].location + 1)];
	CGSize descSz = [descripStr sizeWithFont:D_DESCRIP_FONT 
								 constrainedToSize:CGSizeMake(cellWidth,S_DESCRIP_HEIGHT + S_ROW_HEIGHT) 
								 lineBreakMode:UILineBreakModeTailTruncation];
	[descripView setFrame:CGRectMake(S_CELL_HPADDING,cellY,descSz.width,descSz.height)];
	[descripView setText:descripStr];
	
	// next row
	cellY += descSz.height + S_CELL_VPADDING;
	
	// 
	// Bill Status
	// 
	UILabel *statusLbl = (UILabel *)[self viewWithTag:eTAG_STATUSLABEL];
	NSString *statusTxt = [NSString stringWithFormat:@"Status: %@ ",[m_bill.m_status capitalizedString]];
	CGSize statusSz = [statusTxt sizeWithFont:D_STATUS_FONT 
								 constrainedToSize:CGSizeMake(S_STATUS_WIDTH,S_ROW_HEIGHT) 
								 lineBreakMode:UILineBreakModeTailTruncation];
	[statusLbl setFrame:CGRectMake((2.0f*S_CELL_HPADDING),
								   cellY,
								   statusSz.width,
								   S_ROW_HEIGHT
								  )];
	[statusLbl setText:statusTxt];
	
	// 
	// Was there a vote?
	// 
	UILabel *voteView = (UILabel *)[self viewWithTag:eTAG_VOTESTATUS];
	if ( eVote_novote == [[m_bill lastBillAction] m_voteResult] )
	{
		voteView.text = @"";
		[voteView setFrame:CGRectZero];
	}
	else
	{
		CGRect voteRect = CGRectMake(CGRectGetMaxX(statusLbl.frame) + S_CELL_HPADDING,
									 cellY,
									 S_VOTE_WIDTH,
									 S_ROW_HEIGHT
		);
		[voteView setFrame:voteRect];
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
			voteColor = [UIColor darkGrayColor];
		}
		[voteView setText:voteTxt];
		voteView.textColor = voteColor;
	}

	cellY += S_ROW_HEIGHT + S_CELL_VPADDING;
	
	CGRect detailRect = CGRectMake(cellWidth + (2.0f*S_CELL_HPADDING),
								   cellY/2.0f - (CGRectGetHeight(detailButton.frame)/2.0f),
								   CGRectGetWidth(detailButton.frame),
								   CGRectGetHeight(detailButton.frame)
								   );
	[detailButton setFrame:detailRect];
}


@end

//
//  BillSummaryTableCell.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BillSummaryTableCell.h"
#import "BillContainer.h"

@implementation BillSummaryTableCell

@synthesize m_bill;

enum
{
	eTAG_TITLE,
	eTAG_STATUSLABEL,
	eTAG_STATUS,
	eTAG_VOTESTATUS,
	eTAG_HISTORYLABEL,
	eTAG_HISTORY,
};

static const CGFloat S_CELL_PADDING = 5.0f;
static const CGFloat S_TITLE_HEIGHT = 60.0f;
static const CGFloat S_LABEL_WIDTH = 50.0f;
static const CGFloat S_LABEL_HEIGHT = 15.0f;
static const CGFloat S_VOTE_WIDTH = 40.0f;

#define D_TITLE_FONT [UIFont systemFontOfSize:14.0f]
#define D_LABEL_FONT [UIFont boldSystemFontOfSize:12.0f]
#define D_STD_FONT   [UIFont systemFontOfSize:12.0f]


+ (CGFloat)getCellHeightForBill:(BillContainer *)bill
{
	NSString *title = bill.m_title;
	CGSize titleSz = [title sizeWithFont:D_TITLE_FONT 
							constrainedToSize:CGSizeMake(320.0f - (2.0f*S_CELL_PADDING),S_TITLE_HEIGHT) 
							lineBreakMode:UILineBreakModeTailTruncation];
	
	CGFloat height = titleSz.height + S_CELL_PADDING + 
					 S_LABEL_HEIGHT + S_CELL_PADDING;
	
	return height;
}


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier detailTarget:(id)tgt detailSelector:(SEL)sel
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		m_bill = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		CGFloat frameX = 10.0f;
		CGFloat frameY = 2.0f;
		CGFloat frameW = self.contentView.bounds.size.width - (frameX * 2.0f);
		//CGFloat frameH = self.contentView.bounds.size.height - (frameY * 2.0f);
		
		CGRect titleRect = CGRectMake(frameX,frameY,frameW,S_TITLE_HEIGHT);
		UILabel *titleView = [[UILabel alloc] initWithFrame:titleRect];
		titleView.backgroundColor = [UIColor clearColor];
		titleView.textColor = [UIColor blackColor];
		titleView.shadowColor = [UIColor darkGrayColor];
		titleView.font = D_TITLE_FONT;
		titleView.textAlignment = UITextAlignmentLeft;
		titleView.lineBreakMode = UILineBreakModeTailTruncation;
		titleView.numberOfLines = 5;
		[titleView setTag:eTAG_TITLE];
		
		frameY += CGRectGetMaxY(titleRect) + S_CELL_PADDING;
		
		CGRect labelRect = CGRectMake(frameX, 
									  frameY, 
									  S_LABEL_WIDTH,
									  S_LABEL_HEIGHT
		);
		UILabel *statusLbl = [[UILabel alloc] initWithFrame:labelRect];
		statusLbl.backgroundColor = [UIColor clearColor];
		statusLbl.textColor = [UIColor blackColor];
		statusLbl.font = D_LABEL_FONT;
		statusLbl.textAlignment = UITextAlignmentLeft;
		statusLbl.adjustsFontSizeToFitWidth = YES;
		statusLbl.text = @"Status:";
		[statusLbl setTag:eTAG_STATUSLABEL];
		
		CGRect voteRect = CGRectMake(frameW - S_VOTE_WIDTH,
									 frameY,
									 S_VOTE_WIDTH,
									 S_LABEL_HEIGHT
		);
		UILabel *voteView = [[UILabel alloc] initWithFrame:voteRect];
		voteView.backgroundColor = [UIColor clearColor];
		voteView.textColor = [UIColor blueColor];
		voteView.font = D_STD_FONT;
		voteView.textAlignment = UITextAlignmentCenter;
		voteView.adjustsFontSizeToFitWidth = YES;
		[voteView setTag:eTAG_VOTESTATUS];
		
		CGRect statusRect = CGRectMake(CGRectGetMaxX(labelRect) + S_CELL_PADDING,
									   frameY,
									   CGRectGetMinX(voteRect) - CGRectGetMaxX(labelRect) - (2.0f*S_CELL_PADDING),
									   S_LABEL_HEIGHT
		);
		UILabel *statusView = [[UILabel alloc] initWithFrame:statusRect];
		statusView.backgroundColor = [UIColor clearColor];
		statusView.textColor = [UIColor darkGrayColor];
		statusView.textAlignment = UITextAlignmentLeft;
		statusView.adjustsFontSizeToFitWidth = YES;
		[statusView setTag:eTAG_STATUS];
		
		[self addSubview:titleView];
		[self addSubview:statusLbl];
		[self addSubview:statusView];
		[self addSubview:voteView];
		
		[titleView release];
		[statusLbl release];
		[statusView release];
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
}


- (void)setContentFromBill:(BillContainer *)container
{
	[m_bill release];
	m_bill = [container retain];
	
	UILabel *titleView = (UILabel *)[self viewWithTag:eTAG_TITLE];
	[titleView setText:m_bill.m_title];
	[titleView sizeToFit];
	
	CGRect titleRect = titleView.frame;
	CGFloat statusY = CGRectGetMaxY(titleRect) + S_CELL_PADDING;
	
	CGRect tmpRect = CGRectMake(CGRectGetMinX(titleRect), statusY, S_LABEL_WIDTH, S_LABEL_HEIGHT);
	UILabel *statusLbl = (UILabel *)[self viewWithTag:eTAG_STATUSLABEL];
	[statusLbl setFrame:tmpRect];
	
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
	
	CGFloat statusWidth = (CGRectGetMinX(voteView.frame) > 0) ? 
							CGRectGetMinX(voteView.frame) - CGRectGetMaxX(statusLbl.frame) - (2.0f*S_CELL_PADDING) :
							CGRectGetMaxX(titleRect) - CGRectGetMaxX(statusLbl.frame) - (2.0f*S_CELL_PADDING);
	tmpRect = CGRectMake(CGRectGetMaxX(statusLbl.frame) + S_CELL_PADDING,
						 statusY,
						 statusWidth,
						 S_LABEL_HEIGHT);
	UILabel *statusView = (UILabel *)[self viewWithTag:eTAG_STATUS];
	[statusView setFrame:tmpRect];
	[statusView setText:m_bill.m_status];
	
}


@end

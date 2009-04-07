//
//  ContractorSpendingTableCell.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ContractorSpendingTableCell.h"
#import "ContractorSpendingData.h"

@implementation ContractorSpendingTableCell

enum
{
	eTAG_DETAIL   = 999,
	eTAG_NAME     = 998,
	eTAG_DOLLARS  = 997, 
	eTAG_ACTIVITY = 996,
};

static const CGFloat S_CELL_OFFSET = 7.0f;
static const CGFloat S_DOLLARS_TEXT_WIDTH = 60.0f;
//static const CGFloat S_NAME_TEXT_WIDTH = 180.0f;

- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)identifier detailTarget:(id)tgt detailSelector:(SEL)sel
{
	if ( self = [super initWithFrame:frame reuseIdentifier:identifier] ) 
	{
		m_contractor = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		CGFloat frameX = S_CELL_OFFSET;
		CGFloat frameY = 0.0f;
		CGFloat frameW = 320.0f;
		CGFloat frameH = self.contentView.bounds.size.height - (frameY * 2.0f);
		
		// 
		// Detail button (next to table index)
		// 
		UIButton *detail = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[detail setTag:eTAG_DETAIL];
		//detail.showsTouchWhenHighlighted = YES;
		CGRect detailRect = CGRectMake( frameW - CGRectGetWidth(detail.frame) - S_CELL_OFFSET,
									    frameY + (frameH - CGRectGetHeight(detail.frame))/2.0f,
									    CGRectGetWidth(detail.frame),
									    CGRectGetHeight(detail.frame) );
		[detail setFrame:detailRect];
		
		// 
		// Dollars text field 
		// 
		CGRect dollarsRect = CGRectMake(CGRectGetMinX(detailRect) - S_DOLLARS_TEXT_WIDTH - (2.0f*S_CELL_OFFSET),
										frameY, 
										S_DOLLARS_TEXT_WIDTH, 
										frameH);
		UILabel *dollarsView = [[UILabel alloc] initWithFrame:dollarsRect];
		dollarsView.backgroundColor = [UIColor clearColor];
		dollarsView.textColor = [UIColor redColor];
		dollarsView.font = [UIFont boldSystemFontOfSize:14.0f];
		dollarsView.textAlignment = UITextAlignmentRight;
		dollarsView.adjustsFontSizeToFitWidth = YES;
		[dollarsView setTag:eTAG_DOLLARS];
		
		
		// 
		// Contractor name text field (on the left side of the cell)
		// 
		CGRect ctrRect = CGRectMake(frameX,
									frameY, 
									CGRectGetMinX(dollarsRect) - S_CELL_OFFSET,
									frameH);
		UILabel *ctrView = [[UILabel alloc] initWithFrame:ctrRect];
		ctrView.backgroundColor = [UIColor clearColor];
		ctrView.textColor = [UIColor blackColor];
		ctrView.font = [UIFont systemFontOfSize:14.0f];
		ctrView.textAlignment = UITextAlignmentLeft;
		ctrView.adjustsFontSizeToFitWidth = YES;
		[ctrView setTag:eTAG_NAME];
		
		// set delegate for detail button press!
		[detail addTarget:tgt action:sel forControlEvents:UIControlEventTouchUpInside];
		
		// add views to cell view
		[self addSubview:dollarsView];
		[self addSubview:ctrView];
		[self addSubview:detail];
		
		[dollarsView release];
		[ctrView release];
	}
	return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];

	// Configure the view for the selected state
}


- (void)dealloc 
{
	[m_contractor release];
	[super dealloc];
}


- (void)setContractor:(ContractorInfo *)contractor
{
	UILabel *ctrView = (UILabel *)[self viewWithTag:eTAG_NAME];
	UILabel *dollarsView = (UILabel *)[self viewWithTag:eTAG_DOLLARS];
	UIButton *detailButton = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	
	if ( nil == contractor ) 
	{
		// render a UIActivityView!
		[ctrView setText:@"Downloading..."];
		[dollarsView setText:@""];
		[detailButton setHidden:YES];
		
		if ( nil == aiView )
		{
			CGFloat cellHeight = CGRectGetHeight(ctrView.frame);
			
			aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			aiView.hidesWhenStopped = YES;
			[aiView setFrame:CGRectMake(0.0f, 0.0f, cellHeight/2.0f, cellHeight/2.0f)];
			[aiView setCenter:CGPointMake(CGRectGetMaxX(ctrView.frame) + S_CELL_OFFSET + cellHeight/2.0f, cellHeight/2.0f)];
			[aiView setTag:eTAG_ACTIVITY];
			[self addSubview:aiView];
			[aiView release];
		}
		[aiView startAnimating];
		return;
	}
	
	if ( nil != aiView ) [aiView stopAnimating];
	
	[m_contractor release];
	m_contractor = [contractor retain];
	
	CGFloat millionsOfDollars = m_contractor.m_obligatedAmount / 1000000;
	NSString *dollarsTxt = [[NSString alloc] initWithFormat:@"$%.1fM",millionsOfDollars];
	
	[ctrView setText:m_contractor.m_parentCompany];
	[dollarsView setText:dollarsTxt];
	[detailButton setHidden:NO];
}


@end
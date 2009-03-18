//
//  LegislatorNameCell.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LegislatorNameCell.h"
#import "LegislatorContainer.h"


@implementation LegislatorNameCell

@synthesize m_legislator;

static const CGFloat S_TABLE_TITLE_WIDTH = 15.0f;
static const CGFloat S_INFO_OFFSET = 10.0f;
static const CGFloat S_PARTY_INDICATOR_WIDTH = 40.0f;


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier detailTarget:(id)tgt detailSelector:(SEL)sel
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		m_legislator = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		CGFloat frameX = 10.0f;
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
		
		CGRect nameRect = CGRectMake(frameX, 
									 frameY, 
									 frameW - S_TABLE_TITLE_WIDTH - S_PARTY_INDICATOR_WIDTH - CGRectGetWidth(detailRect) - 5.0f, 
									 frameH/1.5);
		UILabel *nameView = [[UILabel alloc] initWithFrame:nameRect];
		nameView.backgroundColor = [UIColor clearColor];
		nameView.textColor = [UIColor blackColor];
		nameView.font = [UIFont boldSystemFontOfSize:18.0f];
		nameView.textAlignment = UITextAlignmentLeft;
		nameView.adjustsFontSizeToFitWidth = YES;
		[nameView setTag:999];
		
		CGRect partyRect = CGRectMake(CGRectGetMinX(detailRect) - S_PARTY_INDICATOR_WIDTH,
									  frameY, 
									  S_PARTY_INDICATOR_WIDTH, 
									  frameH/1.5);
		UILabel *partyView = [[UILabel alloc] initWithFrame:partyRect];
		partyView.backgroundColor = [UIColor clearColor];
		partyView.textColor = [UIColor darkGrayColor];
		partyView.font = [UIFont systemFontOfSize:18.0f];
		partyView.textAlignment = UITextAlignmentCenter;
		partyView.adjustsFontSizeToFitWidth = YES;
		[partyView setTag:998];
		
		CGRect infoRect = CGRectMake( frameX + S_INFO_OFFSET, 
									  frameY + CGRectGetHeight(nameRect),
									  frameW - S_INFO_OFFSET - S_PARTY_INDICATOR_WIDTH,
									  frameH - CGRectGetHeight(nameRect) );
		UILabel *infoView = [[UILabel alloc] initWithFrame:infoRect];
		infoView.backgroundColor = [UIColor clearColor];
		infoView.textColor = [UIColor darkGrayColor];
		infoView.font = [UIFont systemFontOfSize:14.0f];
		infoView.textAlignment = UITextAlignmentLeft;
		infoView.adjustsFontSizeToFitWidth = YES;
		[infoView setTag:997];
		
		
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
	UILabel *nameView = (UILabel *)[self viewWithTag:999];
	nameView.highlighted = selected;
	
	UILabel *partyView = (UILabel *)[self viewWithTag:998];
	partyView.highlighted = selected;
	
	UILabel *infoView = (UILabel *)[self viewWithTag:997];
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
	
	UILabel *nameView = (UILabel *)[self viewWithTag:999];
	[nameView setText:name];
	
	UILabel *partyView = (UILabel *)[self viewWithTag:998];
	[partyView setText:party];
	//[partyView setTextColor:([party isEqualToString:@"D"] ? [UIColor blueColor] : [UIColor redColor])];
	
	UILabel *infoView = (UILabel *)[self viewWithTag:997];
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


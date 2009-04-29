//
//  CommunityItemVTabelCell.m
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//  Copyright 2009 U.S. PIRG. All rights reserved.
//

#import "CommunityItem.h"
#import "CommunityItemTableCell.h"


@interface CommunityItemTableCell (private)
	- (void)updateLayout;
@end


@implementation CommunityItemTableCell

@synthesize m_item;

enum
{
	eTAG_DETAIL     = 999,
	eTAG_TITLE      = 998,
	eTAG_COMMENTS   = 997,
	eTAG_SUMMARY    = 996,
	eTAG_IMAGE      = 995,
};

static const CGFloat S_CELL_HOFFSET = 7.0f;
static const CGFloat S_CELL_VOFFSET = 5.0f;
static const CGFloat S_TITLE_HEIGHT = 20.0f;
static const CGFloat S_TITLE_MAX_WIDTH = 140.0f;
static const CGFloat S_MAX_IMG_WIDTH = 64.0f;

static const CGFloat S_MIN_HEIGHT = 64.0f;
static const CGFloat S_MAX_HEIGHT = 84.0f;
static const CGFloat S_MAX_WIDTH_PORTRAIT = 320.0f;

#define TITLE_FONT  [UIFont boldSystemFontOfSize:14.0f]
#define TITLE_COLOR [UIColor blackColor]

#define COMMENTS_FONT  [UIFont systemFontOfSize:14.0f]
#define COMMENTS_COLOR [UIColor darkGrayColor]

#define SUMMARY_FONT  [UIFont systemFontOfSize:12.0f]
#define SUMMARY_COLOR [UIColor darkGrayColor]


+ (CGFloat)getCellHeightForItem:(CommunityItem *)item
{
	NSString *descrip = item.m_summary;
	CGSize descripSz = [descrip sizeWithFont:SUMMARY_FONT 
						   constrainedToSize:CGSizeMake(S_MAX_WIDTH_PORTRAIT - (3.0f*S_CELL_HOFFSET) - 32.0f, S_MAX_HEIGHT - S_TITLE_HEIGHT - (2.0f*S_CELL_VOFFSET)) 
							   lineBreakMode:UILineBreakModeWordWrap];
	
	CGFloat height = S_TITLE_HEIGHT + S_CELL_VOFFSET + 
					 descripSz.height + S_CELL_VOFFSET;
	
	if ( height > S_MIN_HEIGHT ) return height;
	
	return S_MIN_HEIGHT;
}



- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)identifier
{
	if ( self = [super initWithFrame:frame reuseIdentifier:identifier] ) 
	{
		m_item = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		// 
		// Detail button (next to table index)
		// 
		UIButton *detail = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
		[detail setTag:eTAG_DETAIL];
		[self addSubview:detail];
		
		UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectZero];
		titleView.backgroundColor = [UIColor clearColor];
		titleView.textColor = TITLE_COLOR;
		titleView.font = TITLE_FONT;
		titleView.textAlignment = UITextAlignmentLeft;
		titleView.adjustsFontSizeToFitWidth = YES;
		[titleView setTag:eTAG_TITLE];
		[self addSubview:titleView];
		[titleView release];
		
		UILabel *commentsView = [[UILabel alloc] initWithFrame:CGRectZero];
		commentsView.backgroundColor = [UIColor clearColor];
		commentsView.textColor = COMMENTS_COLOR;
		commentsView.font = COMMENTS_FONT;
		commentsView.textAlignment = UITextAlignmentLeft;
		commentsView.adjustsFontSizeToFitWidth = YES;
		[commentsView setTag:eTAG_COMMENTS];
		[self addSubview:commentsView];
		[commentsView release];
		
		UILabel *summaryView = [[UILabel alloc] initWithFrame:CGRectZero];
		summaryView.backgroundColor = [UIColor clearColor];
		summaryView.textColor = SUMMARY_COLOR;
		summaryView.font = SUMMARY_FONT;
		summaryView.textAlignment = UITextAlignmentLeft;
		summaryView.numberOfLines = 4;
		summaryView.lineBreakMode = UILineBreakModeWordWrap;
		[summaryView setTag:eTAG_SUMMARY];
		[self addSubview:summaryView];
		[summaryView release];
		
		UIImageView *imgView = [[UIImageView alloc] init];
		imgView.userInteractionEnabled = NO;
		[imgView setTag:eTAG_IMAGE];
		[self addSubview:imgView];
		[imgView release];
	}
	return self;
}


- (void)dealloc 
{
	[m_item release];
	[super dealloc];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];

	UILabel *lbl;
	
	UIButton *detail = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	detail.highlighted = selected;
	
	lbl = (UILabel *)[self viewWithTag:eTAG_TITLE];
	lbl.highlighted = selected;
	lbl = (UILabel *)[self viewWithTag:eTAG_COMMENTS];
	lbl.highlighted = selected;
	lbl = (UILabel *)[self viewWithTag:eTAG_SUMMARY];
	lbl.highlighted = selected;
	
/**
	UILabel *billNumView = (UILabel *)[self viewWithTag:eTAG_BILLNUM];
	[billNumView setHighlighted:selected];
**/
}


- (void)setDetailTarget:(id)target andSelector:(SEL)selector
{
	UIButton *detail = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	
	// set delegate for detail button press!
	[detail addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
}


- (void)setCommunityItem:(CommunityItem *)newItem 
{
	if ( m_item != newItem ) 
	{
		[m_item release];
		m_item = [newItem retain];
	}
	[self updateLayout];
	[self setNeedsDisplay];
}


#pragma mark CommunityItemTableCell Private 


- (void)updateLayout
{
	// 
	// Do something dumb for now... 
	// 
	CGFloat cellHeight = [CommunityItemTableCell getCellHeightForItem:m_item];
	
	// set the detail button geometry: aligned right, middle of the cell
	UIButton *detailButton = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	CGRect detailRect = CGRectMake( S_MAX_WIDTH_PORTRAIT - CGRectGetWidth(detailButton.frame) - S_CELL_HOFFSET,
								    (cellHeight - CGRectGetHeight(detailButton.frame))/2.0f,
								    CGRectGetWidth(detailButton.frame),
								    CGRectGetHeight(detailButton.frame) );
	[detailButton setFrame:detailRect];
	
	// image view: aligned left, middle of the cell
	UIImageView *imgView = (UIImageView *)[self viewWithTag:eTAG_IMAGE];
	imgView.image = m_item.m_image;
	CGFloat imgHeight = ((m_item.m_image.size.height < cellHeight) ? m_item.m_image.size.height : cellHeight);
	CGFloat imgWidth = ((m_item.m_image.size.width < S_MAX_IMG_WIDTH) ? m_item.m_image.size.width : S_MAX_IMG_WIDTH);
	CGRect imgRect = CGRectMake( S_CELL_HOFFSET,
								 (cellHeight - imgHeight)/2.0f,
								 imgWidth, imgHeight );
	[imgView setFrame:imgRect];
	
	// title view: top-aligned, left-aligned against photo
	UILabel *titleView = (UILabel *)[self viewWithTag:eTAG_TITLE];
	
	CGSize titleSz = [m_item.m_title sizeWithFont:TITLE_FONT 
								constrainedToSize:CGSizeMake(S_TITLE_MAX_WIDTH, S_TITLE_HEIGHT) 
									lineBreakMode:UILineBreakModeWordWrap];
	CGRect titleRect = CGRectMake( CGRectGetMaxX(imgRect) + S_CELL_HOFFSET,
								   S_CELL_VOFFSET,
								   titleSz.width, S_TITLE_HEIGHT );
	[titleView setFrame:titleRect];
	titleView.text = m_item.m_title;
	
	// comments view: left-aligned against title view
	UILabel *commentView = (UILabel *)[self viewWithTag:eTAG_COMMENTS];
	CGRect commentsRect = CGRectMake( CGRectGetMaxX(titleRect) + S_CELL_HOFFSET,
									  S_CELL_VOFFSET,
									  CGRectGetMinX(detailRect) - CGRectGetMaxX(titleRect) - (2.0f*S_CELL_HOFFSET),
									  S_TITLE_HEIGHT );
	[commentView setFrame:commentsRect];
	commentView.text = [NSString stringWithFormat:@"(%0d)", [[m_item comments] count]];
	
	// summary view: just below title and comments views
	UILabel *summaryView = (UILabel *)[self viewWithTag:eTAG_SUMMARY];
	CGRect summaryRect = CGRectMake( CGRectGetMinX(titleRect),
									 CGRectGetMaxY(titleRect) + S_CELL_VOFFSET,
									 CGRectGetMaxX(commentsRect) - CGRectGetMinX(titleRect),
									 cellHeight - CGRectGetHeight(titleRect) - (3.0f*S_CELL_VOFFSET) );
	[summaryView setFrame:summaryRect];
	summaryView.text = m_item.m_summary;
	
}


@end

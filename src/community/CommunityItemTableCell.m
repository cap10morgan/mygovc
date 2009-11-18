/*
 File: CommunityItemVTabelCell.m
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
#import "myGovAppDelegate.h"
#import "CommunityItem.h"
#import "CommunityItemTableCell.h"
#import "MyGovUserData.h"

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
	eTAG_USERNAME   = 994,
	eTAG_OVERLAYVIEW = 888,
};

static       CGFloat S_CELL_INITIAL_HOFFSET = 7.0f;
static const CGFloat S_CELL_HOFFSET = 7.0f;
static const CGFloat S_CELL_VOFFSET = 4.0f;
static const CGFloat S_DETAIL_BUTTON_WIDTH = 16.0f;
static const CGFloat S_DETAIL_BUTTON_HEIGHT = 32.0f;
static const CGFloat S_TITLE_HEIGHT = 16.0f;
static const CGFloat S_TITLE_MAX_WIDTH = 204.0f;
static const CGFloat S_MAX_IMG_WIDTH = 38.0f;
static const CGFloat S_MAX_IMG_HEIGHT = 38.0f;

static const CGFloat S_MIN_HEIGHT = 64.0f + (2.0f * 5.0f);
static const CGFloat S_MAX_HEIGHT = 120.0f;
static const CGFloat S_MAX_WIDTH_PORTRAIT = 320.0f;

#define TITLE_FONT     [UIFont boldSystemFontOfSize:14.0f]
#define TITLE_COLOR    [UIColor blackColor]

#define USERNAME_FONT  [UIFont boldSystemFontOfSize:12.0f]
#define USERNAME_COLOR [UIColor colorWithRed:0.32f green:0.32f blue:1.0f alpha:1.0f]

#define COMMENTS_FONT  [UIFont systemFontOfSize:14.0f]
#define COMMENTS_COLOR [UIColor colorWithRed:0.32f green:0.32f blue:1.0f alpha:0.85f]

#define SUMMARY_FONT   [UIFont systemFontOfSize:13.0f]
#define SUMMARY_COLOR  [UIColor darkGrayColor]

#define NEW_ITEM_BACKGROUND_COLOR [UIColor colorWithRed:1.0f green:1.0f blue:0.8f alpha:0.9f];
#define OLD_ITEM_BACKGROUND_COLOR [UIColor whiteColor];


+ (CGFloat)getCellHeightForItem:(CommunityItem *)item
{
	NSString *descrip = item.m_summary;
	CGSize descripSz = [descrip sizeWithFont:SUMMARY_FONT 
						   constrainedToSize:CGSizeMake(S_MAX_WIDTH_PORTRAIT - (3.0f*S_CELL_HOFFSET) - S_CELL_INITIAL_HOFFSET - S_DETAIL_BUTTON_WIDTH, S_MAX_HEIGHT - (2.0f*S_TITLE_HEIGHT) - (4.0f*S_CELL_VOFFSET)) 
							   lineBreakMode:UILineBreakModeWordWrap];
	
	CGFloat txtHeight = S_CELL_VOFFSET + 
						S_TITLE_HEIGHT + S_CELL_VOFFSET + 
						S_TITLE_HEIGHT + S_CELL_VOFFSET + 
						descripSz.height + S_CELL_VOFFSET;
	
	CGFloat imgHeight = S_CELL_VOFFSET + 
						S_MAX_IMG_HEIGHT + S_CELL_VOFFSET +
						S_TITLE_HEIGHT + S_CELL_VOFFSET;
	
	CGFloat height = (txtHeight > imgHeight) ? txtHeight : imgHeight;
	
	if ( height > S_MIN_HEIGHT ) return height;
	
	return S_MIN_HEIGHT;
}



- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)identifier
{
	if ( self = [super initWithFrame:frame reuseIdentifier:identifier] ) 
	{
		m_item = nil;
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		self.shouldIndentWhileEditing = NO;
		//self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
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
		titleView.lineBreakMode = UILineBreakModeTailTruncation;
		//titleView.adjustsFontSizeToFitWidth = YES;
		[titleView setTag:eTAG_TITLE];
		[self addSubview:titleView];
		[titleView release];
		
		UILabel *commentsView = [[UILabel alloc] initWithFrame:CGRectZero];
		commentsView.backgroundColor = [UIColor clearColor];
		commentsView.textColor = COMMENTS_COLOR;
		commentsView.font = COMMENTS_FONT;
		commentsView.textAlignment = UITextAlignmentRight;
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
		//imgView.userInteractionEnabled = YES;
		imgView.backgroundColor = [UIColor clearColor];
		[imgView setTag:eTAG_IMAGE];
		[self addSubview:imgView];
		[imgView release];
		
		UILabel *unameView = [[UILabel alloc] initWithFrame:CGRectZero];
		unameView.backgroundColor = [UIColor clearColor];
		unameView.textColor = USERNAME_COLOR;
		unameView.font = USERNAME_FONT;
		unameView.textAlignment = UITextAlignmentLeft;
		unameView.lineBreakMode = UILineBreakModeMiddleTruncation;
		//titleView.adjustsFontSizeToFitWidth = YES;
		[unameView setTag:eTAG_USERNAME];
		[self addSubview:unameView];
		[unameView release];
		
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
	
	UIImageView *imgView = (UIImageView *)[self viewWithTag:eTAG_IMAGE];
	imgView.highlighted = selected;
	
	lbl = (UILabel *)[self viewWithTag:eTAG_TITLE];
	lbl.highlighted = selected;
	lbl = (UILabel *)[self viewWithTag:eTAG_COMMENTS];
	lbl.highlighted = selected;
	lbl = (UILabel *)[self viewWithTag:eTAG_SUMMARY];
	lbl.highlighted = selected;
	lbl = (UILabel *)[self viewWithTag:eTAG_USERNAME];
	lbl.highlighted = selected;
}


- (void)setEditing:(BOOL)isEditing animated:(BOOL)animated
{
	[super setEditing:isEditing animated:animated];
	
	if ( isEditing )
	{
		S_CELL_INITIAL_HOFFSET = 44.0f;
	}
	else 
	{
		S_CELL_INITIAL_HOFFSET = 7.0f;
	}

}


- (void)willTransitionToState:(UITableViewCellStateMask)state
{
	[super willTransitionToState:state];
	
	UIView *overlayView = (UIView *)[self viewWithTag:eTAG_OVERLAYVIEW];
	
	if ( state & UITableViewCellStateShowingDeleteConfirmationMask )
	{
		if ( nil != overlayView )
		{
			CGRect viewRect = self.contentView.frame;
			UIView *overlayView = [[UIView alloc] initWithFrame:CGRectMake(0.0f,0.0f,CGRectGetWidth(viewRect),CGRectGetHeight(viewRect))];
			overlayView.backgroundColor = [UIColor colorWithRed:0.25f green:0.25f blue:0.25f alpha:0.7f]; 
			[overlayView setTag:eTAG_OVERLAYVIEW];
			[self addSubview:overlayView];
			[overlayView release];
		}
	}
	else 
	{
		if ( nil != overlayView )
		{
			[overlayView removeFromSuperview];
		}
	}

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
	if ( ![self isEditing] )
	{
		UIView *overlayView = (UIView *)[self viewWithTag:eTAG_OVERLAYVIEW];
		if ( nil != overlayView )
		{
			// get rid of this!
			[overlayView removeFromSuperview];
		}
	}
	
	// 
	// Do something dumb for now... 
	// 
	CGFloat cellHeight = [CommunityItemTableCell getCellHeightForItem:m_item];
	
	// set the background color
	if ( eCommunityItem_New == m_item.m_uiStatus )
	{
		self.contentView.backgroundColor = NEW_ITEM_BACKGROUND_COLOR;
	}
	else
	{
		self.contentView.backgroundColor = OLD_ITEM_BACKGROUND_COLOR;
	}

	CGRect detailRect = CGRectMake( S_MAX_WIDTH_PORTRAIT - S_DETAIL_BUTTON_WIDTH - S_CELL_HOFFSET,
								   (cellHeight - S_DETAIL_BUTTON_HEIGHT)/2.0f,
								   S_DETAIL_BUTTON_WIDTH,
								   S_DETAIL_BUTTON_HEIGHT );
	
	// set the detail button geometry: aligned right, middle of the cell
	UIButton *detailButton = (UIButton *)[self viewWithTag:eTAG_DETAIL];
	[detailButton setFrame:detailRect];
	
	// image view: aligned left, middle of the cell
	UIImageView *imgView = (UIImageView *)[self viewWithTag:eTAG_IMAGE];
	
	// check for a user image
	MyGovUser *creator = [[myGovAppDelegate sharedUserData] userFromUsername:m_item.m_creator];
	if ( nil != [creator m_avatar] )
	{
		imgView.image = creator.m_avatar;
	}
	else 
	{
		// default icon
		imgView.image = [UIImage imageWithContentsOfFile:[[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"personIcon.png"]];
	}
	
	CGSize imgSz = imgView.image.size;
	if ( imgSz.height > S_MAX_IMG_HEIGHT ) imgSz.height = S_MAX_IMG_HEIGHT;
	if ( imgSz.width > S_MAX_IMG_WIDTH ) imgSz.width = S_MAX_IMG_WIDTH;
	CGRect imgRect = CGRectMake( S_CELL_INITIAL_HOFFSET,
								 S_CELL_VOFFSET,
								 imgSz.width, 
								 imgSz.height );
	[imgView setFrame:imgRect];
	
	CGFloat contentStartX = S_CELL_INITIAL_HOFFSET + S_MAX_IMG_WIDTH + S_CELL_HOFFSET;
	CGFloat contentStartY = S_CELL_VOFFSET;
	
	// username view top-aligned
	CGRect unameRect = CGRectMake( contentStartX, 
								   contentStartY, 
								   CGRectGetMinX(detailRect) - (2.0f*S_CELL_HOFFSET), 
								   S_TITLE_HEIGHT);
	UILabel *unameView = (UILabel *)[self viewWithTag:eTAG_USERNAME];
	[unameView setFrame:unameRect];
	unameView.text = [NSString stringWithFormat:@"%@ says:",m_item.m_creator];
	
	// title view: top-aligned just below uname, left-aligned against side of frame
	UILabel *titleView = (UILabel *)[self viewWithTag:eTAG_TITLE];
	
	CGSize titleSz;
	CGRect titleRect;
	CGFloat commentsViewVOffset;
	NSString *cleanTitle = [m_item.m_title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if ( [cleanTitle length] > 0 )
	{
		titleSz = [m_item.m_title sizeWithFont:TITLE_FONT 
									constrainedToSize:CGSizeMake(S_TITLE_MAX_WIDTH, S_TITLE_HEIGHT) 
										lineBreakMode:UILineBreakModeTailTruncation];
		titleRect = CGRectMake( contentStartX,
									   CGRectGetMaxY(unameRect) + S_CELL_VOFFSET,
									   titleSz.width, S_TITLE_HEIGHT );
		commentsViewVOffset = S_CELL_VOFFSET;
	}
	else 
	{
		//titleSz = CGSizeMake(S_TITLE_MAX_WIDTH,2);
		//titleRect = CGRectMake(contentStartX, CGRectGetMaxY(unameRect) + S_CELL_VOFFSET, S_TITLE_MAX_WIDTH, 2);
		titleSz = unameRect.size;
		titleRect.origin = unameRect.origin;
		titleRect.size.width = S_TITLE_MAX_WIDTH;
		titleRect.size.height = 2;
		commentsViewVOffset = -4;
	}
	
	[titleView setFrame:titleRect];
	titleView.text = cleanTitle;
	
	// comments view: right-aligned against title view
	UILabel *commentView = (UILabel *)[self viewWithTag:eTAG_COMMENTS];
	CGRect commentsRect = CGRectMake( CGRectGetMaxX(titleRect) + S_CELL_HOFFSET,
									  CGRectGetMinY(titleRect) - commentsViewVOffset,
									  CGRectGetMinX(detailRect) - CGRectGetMaxX(titleRect) - (2.0f*S_CELL_HOFFSET),
									  S_TITLE_HEIGHT );
	[commentView setFrame:commentsRect];
	commentView.text = [NSString stringWithFormat:@"(%0d)", [[m_item comments] count]];
	
	// summary view: just below title and comments views
	UILabel *summaryView = (UILabel *)[self viewWithTag:eTAG_SUMMARY];
	CGRect summaryRect = CGRectMake( CGRectGetMinX(titleRect),
									 CGRectGetMaxY(titleRect) + S_CELL_VOFFSET,
									 CGRectGetMaxX(commentsRect) - CGRectGetMinX(titleRect),
									 cellHeight - CGRectGetMaxY(titleRect) - S_CELL_VOFFSET );
	[summaryView setFrame:summaryRect];
	summaryView.text = m_item.m_summary;
}


@end

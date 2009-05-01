//
//  CustomTableCell.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CustomTableCell.h"
#import "TableDataManager.h"

@implementation CustomTableCell

static const CGFloat CELL_XSTART = 16.0f;
static const CGFloat CELL_HPADDING = 6.0f;
static const CGFloat CELL_VPADDING = 8.0f;

static const CGFloat TITLE_WIDTH = 65.0f;
static const CGFloat CELL_DISCLOSURE_WIDTH = 18.0f;

static const CGFloat CELL_MAX_WIDTH_PORTRAIT = 306.0f;
static const CGFloat CELL_MAX_WIDTH_LANDSCAPE = 466.0f;
static const CGFloat CELL_MAX_HEIGHT = 190.0f;
static const CGFloat CELL_MIN_HEIGHT = 30.0f;

#define TITLE_COLOR [UIColor blackColor]
#define TITLE_FONT  [UIFont boldSystemFontOfSize:14.0f]

#define LINE1_COLOR [UIColor darkGrayColor]
#define LINE1_FONT  [UIFont systemFontOfSize:14.0f]

#define LINE2_COLOR LINE1_COLOR
#define LINE2_FONT  LINE1_FONT

enum
{
	eTAG_TITLE = 888,
	eTAG_LINE1 = 887,
	eTAG_LINE2 = 886,
};


+ (CGFloat)line1HeightForRow:(TableRowData *)rd withOrientation:(UIDeviceOrientation)orientation
{
	// prepare the title string
	NSString *titleTxt;
	NSArray *fldArray = [rd.title componentsSeparatedByString:@"_"];
	if ( [fldArray count] > 1 )
	{
		titleTxt = [fldArray objectAtIndex:([fldArray count]-1)];
	}
	else
	{
		titleTxt = rd.title;
	}
	
	// 
	// Line 1, either:
	//  
	//  {Title}  {Line1}
	//
	//  OR
	// 
	//  {-----Line1----}
	// 
	CGSize line1Sz;
	if ( [rd.line1 length] > 0 )
	{
		if ( [rd.title length] > 0 )
		{
			// put title on the left side, the height is then determined
			// by the line1 data fitting into the right-hand-side
			CGFloat maxWidth = (UIDeviceOrientationPortrait == orientation) ? CELL_MAX_WIDTH_PORTRAIT : CELL_MAX_WIDTH_LANDSCAPE;
			maxWidth -= (TITLE_WIDTH + (4.0f*CELL_HPADDING) + CELL_DISCLOSURE_WIDTH);
			line1Sz = [rd.line1 sizeWithFont:(rd.line1Font == nil ? LINE1_FONT : rd.line1Font)
					   constrainedToSize:CGSizeMake(maxWidth,CELL_MAX_HEIGHT) 
					   lineBreakMode:UILineBreakModeMiddleTruncation];
		}
		else
		{
			// full-width of the cell for line1
			CGFloat maxWidth = (UIDeviceOrientationPortrait == orientation) ? CELL_MAX_WIDTH_PORTRAIT : CELL_MAX_WIDTH_LANDSCAPE;
			maxWidth -= ((2.0f*CELL_HPADDING) + CELL_DISCLOSURE_WIDTH);
			line1Sz = [rd.line1 sizeWithFont:(rd.line1Font == nil ? LINE1_FONT : rd.line1Font)
					   constrainedToSize:CGSizeMake(maxWidth,CELL_MAX_HEIGHT) 
					   lineBreakMode:UILineBreakModeMiddleTruncation];
		}
	}
	else if ( [titleTxt length] > 0 )
	{
		// use the title for the entire line!
		CGFloat maxWidth = (UIDeviceOrientationPortrait == orientation) ? CELL_MAX_WIDTH_PORTRAIT : CELL_MAX_WIDTH_LANDSCAPE;
		maxWidth -= ((2.0f*CELL_HPADDING) + CELL_DISCLOSURE_WIDTH);
		line1Sz = [rd.title sizeWithFont:(rd.titleFont == nil ? TITLE_FONT : rd.titleFont)
				   constrainedToSize:CGSizeMake(maxWidth,CELL_MAX_HEIGHT) 
				   lineBreakMode:UILineBreakModeMiddleTruncation];
	}
	else
	{
		line1Sz = CGSizeMake(1.0f, CELL_MIN_HEIGHT);
	}
	
	return line1Sz.height;
}


+ (CGFloat)line2HeightForRow:(TableRowData *)rd withOrientation:(UIDeviceOrientation)orientation
{
	// 
	// Line 2
	// 
	CGSize line2Sz;
	if ( [rd.line2 length] > 0 )
	{
		// use the entire cell width
		CGFloat maxWidth = (UIDeviceOrientationPortrait == orientation) ? CELL_MAX_WIDTH_PORTRAIT : CELL_MAX_WIDTH_LANDSCAPE;
		maxWidth -= ((2.0f*CELL_HPADDING) + CELL_DISCLOSURE_WIDTH);
		line2Sz = [rd.line2 sizeWithFont:(rd.line2Font == nil ? LINE2_FONT : rd.line2Font)
		                    constrainedToSize:CGSizeMake(maxWidth,CELL_MAX_HEIGHT/2.0f) 
		                    lineBreakMode:UILineBreakModeMiddleTruncation];
	}
	else
	{
		line2Sz = CGSizeMake(0.0f, 0.0f);
	}
	
	return line2Sz.height;
}


+ (CGFloat)cellHeightForRow:(TableRowData *)rd
{
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	if ( UIDeviceOrientationUnknown == orientation ) orientation = UIDeviceOrientationPortrait;
	
	CGFloat line1Height = [CustomTableCell line1HeightForRow:rd withOrientation:orientation];
	CGFloat line2Height = [CustomTableCell line2HeightForRow:rd withOrientation:orientation];
	
	CGFloat total = CELL_VPADDING;
	if ( line1Height > 0.0f )
	{
		total += line1Height + CELL_VPADDING;
	}
	if ( line2Height > 0.0f )
	{
		total += line2Height + CELL_VPADDING;
	}
	
	// return a padded height :-)
	return total;
}


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier 
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		UILabel *titleView = [[UILabel alloc] initWithFrame:CGRectZero];
		titleView.backgroundColor = [UIColor clearColor];
		titleView.highlightedTextColor = [UIColor blackColor];
		titleView.textColor = TITLE_COLOR;
		titleView.font = TITLE_FONT;
		titleView.textAlignment = UITextAlignmentLeft;
		titleView.adjustsFontSizeToFitWidth = YES;
		titleView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		[titleView setTag:eTAG_TITLE];
		[self addSubview:titleView];
		
		UILabel *line1View = [[UILabel alloc] initWithFrame:CGRectZero];
		line1View.backgroundColor = [UIColor clearColor];
		line1View.highlightedTextColor = [UIColor blackColor];
		line1View.textColor = LINE1_COLOR;
		line1View.font = LINE1_FONT;
		line1View.textAlignment = UITextAlignmentLeft;
		line1View.lineBreakMode = UILineBreakModeMiddleTruncation;
		line1View.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		line1View.numberOfLines = 0;
		[line1View setTag:eTAG_LINE1];
		[self addSubview:line1View];
		
		UILabel *line2View = [[UILabel alloc] initWithFrame:CGRectZero];
		line2View.backgroundColor = [UIColor clearColor];
		line2View.highlightedTextColor = [UIColor blackColor];
		line2View.textColor = LINE2_COLOR;
		line2View.font = LINE2_FONT;
		line2View.textAlignment = UITextAlignmentLeft;
		line2View.lineBreakMode = UILineBreakModeMiddleTruncation;
		line2View.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		line2View.numberOfLines = 0;
		[line2View setTag:eTAG_LINE2];
		[self addSubview:line2View];
	}
	return self;
}


- (void)dealloc 
{
	[super dealloc];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	
	// Configure the view for the selected state
	UILabel *titleView = (UILabel *)[self viewWithTag:eTAG_TITLE];
	titleView.highlighted = selected;
	
	UILabel *lineView;
	lineView = (UILabel *)[self viewWithTag:eTAG_LINE1];
	lineView.highlighted = selected;
	lineView = (UILabel *)[self viewWithTag:eTAG_LINE2];
	lineView.highlighted = selected;
}


- (void)setRowData:(TableRowData *)rd
{
	UILabel *titleView = (UILabel *)[self viewWithTag:eTAG_TITLE];
	UILabel *line1View = (UILabel *)[self viewWithTag:eTAG_LINE1];
	UILabel *line2View = (UILabel *)[self viewWithTag:eTAG_LINE2];
	
	if ( nil == rd )
	{
		[titleView setText:@""];
		[line1View setText:@""];
		[line2View setText:@""];
		self.accessoryType = UITableViewCellAccessoryNone;
		return;
	}
	
	// accessory type
	SEL none = @selector(rowActionNone:);
	if ( rd.action == none )
	{
		self.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	// setup the title text
	NSString *titleTxt = @"";
	if ( [rd.title length] > 0 )
	{
		// strip out any leading "{XX}_"
		NSArray *fldArray = [rd.title componentsSeparatedByString:@"_"];
		if ( [fldArray count] > 1 )
		{
			titleTxt = [fldArray objectAtIndex:([fldArray count]-1)];
		}
		else
		{
			titleTxt = rd.title;
		}
	}
	
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	if ( UIDeviceOrientationUnknown == orientation ) orientation = UIDeviceOrientationPortrait;
	
	CGFloat line1Height = [CustomTableCell line1HeightForRow:rd withOrientation:orientation];
	CGFloat line2Height = [CustomTableCell line2HeightForRow:rd withOrientation:orientation];
	
	CGFloat cellMinX = CELL_XSTART;
	CGFloat cellWidth = (UIDeviceOrientationPortrait == orientation ? CELL_MAX_WIDTH_PORTRAIT : CELL_MAX_WIDTH_LANDSCAPE);
	cellWidth -= (CELL_DISCLOSURE_WIDTH + (3.0f*CELL_HPADDING));
	
	CGRect titleFrame = CGRectMake(cellMinX,
								   CELL_VPADDING,
								   ([rd.line1 length] > 0 ? TITLE_WIDTH : cellWidth),
								   line1Height);
	
	// Line1 : if we're not passed a title, use the whole cell!
	CGRect line1Frame;
	if ( [titleTxt length] < 1 )
	{
		line1Frame = CGRectMake(cellMinX, CELL_VPADDING, cellWidth, line1Height);
	}
	else
	{
		// make sure the value rectangle is in its proper place
		line1Frame = CGRectMake(CGRectGetMaxX(titleFrame) + CELL_HPADDING,
							    CELL_VPADDING,
							    cellWidth - CGRectGetWidth(titleFrame) - CELL_HPADDING,
							    line1Height);
	}
	
	CGRect line2Frame;
	if ( [rd.line2 length] > 0 )
	{
		line2Frame = CGRectMake(cellMinX,
								CELL_VPADDING + line1Height + CELL_VPADDING,
								cellWidth,
								line2Height);
	}
	else
	{
		line2Frame = CGRectZero;
	}
	
	// set UILabel fonts
	titleView.font = (nil == rd.titleFont ? TITLE_FONT : rd.titleFont);
	titleView.textColor = (nil == rd.titleColor ? TITLE_COLOR : rd.titleColor);
	titleView.textAlignment = rd.titleAlignment;
	
	line1View.font = (nil == rd.line1Font ? LINE1_FONT : rd.line1Font);
	line1View.textColor = (nil == rd.line1Color ? LINE1_COLOR : rd.line1Color);
	line1View.textAlignment = rd.line1Alignment;
	
	line2View.font = (nil == rd.line2Font ? LINE2_FONT : rd.line2Font);
	line2View.textColor = (nil == rd.line2Color ? LINE2_COLOR : rd.line2Color);
	line2View.textAlignment = rd.line2Alignment;
	
	[titleView setFrame:titleFrame];
	[titleView setText:titleTxt];
	
	[line1View setFrame:line1Frame];
	[line1View setText:rd.line1];
	
	[line2View setFrame:line2Frame];
	[line2View setText:rd.line2];
}


@end

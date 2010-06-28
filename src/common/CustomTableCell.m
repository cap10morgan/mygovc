/*
 File: CustomTableCell.m
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

#import "CustomTableCell.h"
#import "TableDataManager.h"

@implementation CustomTableCell

static const CGFloat CELL_XSTART = 16.0f;
static const CGFloat CELL_HPADDING = 6.0f;
static const CGFloat CELL_VPADDING = 8.0f;

static const CGFloat TITLE_WIDTH = 65.0f;
static const CGFloat CELL_DISCLOSURE_WIDTH = 18.0f;

static CGFloat CELL_MAX_WIDTH_PORTRAIT = -1; //306.0f;
static CGFloat CELL_MAX_WIDTH_LANDSCAPE = -1; //466.0f;
static const CGFloat CELL_MAX_HEIGHT = 480.0f;
static const CGFloat CELL_MIN_HEIGHT = 30.0f;

#define TITLE_COLOR [UIColor blackColor]
#define TITLE_FONT  [UIFont boldSystemFontOfSize:14.0f]

#define LINE1_COLOR [UIColor darkGrayColor]
#define LINE1_FONT  [UIFont systemFontOfSize:14.0f]

#define LINE2_COLOR LINE1_COLOR
#define LINE2_FONT  LINE1_FONT


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
	
	if ( -1 == CELL_MAX_WIDTH_PORTRAIT )
	{
		if ( UIDeviceOrientationPortrait == orientation || UIDeviceOrientationPortraitUpsideDown == orientation )
		{
			CELL_MAX_WIDTH_PORTRAIT = CGRectGetWidth([UIScreen mainScreen].bounds) - (2.0f * CELL_HPADDING);
		}
		else
		{
			CELL_MAX_WIDTH_PORTRAIT = CGRectGetHeight([UIScreen mainScreen].bounds) - (2.0f * CELL_HPADDING);
		}
	}
	if ( -1 == CELL_MAX_WIDTH_LANDSCAPE )
	{
		if ( UIDeviceOrientationPortrait == orientation || UIDeviceOrientationPortraitUpsideDown == orientation )
		{
			CELL_MAX_WIDTH_LANDSCAPE = CGRectGetHeight([UIScreen mainScreen].bounds) - (2.0f * CELL_HPADDING);
		}
		else
		{
			CELL_MAX_WIDTH_LANDSCAPE = CGRectGetWidth([UIScreen mainScreen].bounds) - (2.0f * CELL_HPADDING);
		}
	}
	
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


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
	if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) 
	{
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		m_rd = nil;
		
		m_title = [[UILabel alloc] initWithFrame:CGRectZero];
		m_title.backgroundColor = [UIColor clearColor];
		m_title.highlightedTextColor = [UIColor blackColor];
		m_title.textColor = TITLE_COLOR;
		m_title.font = TITLE_FONT;
		m_title.textAlignment = UITextAlignmentLeft;
		m_title.adjustsFontSizeToFitWidth = YES;
		m_title.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		[self addSubview:m_title];
		
		m_line1 = [[UILabel alloc] initWithFrame:CGRectZero];
		m_line1.backgroundColor = [UIColor clearColor];
		m_line1.highlightedTextColor = [UIColor blackColor];
		m_line1.textColor = LINE1_COLOR;
		m_line1.font = LINE1_FONT;
		m_line1.textAlignment = UITextAlignmentLeft;
		m_line1.lineBreakMode = UILineBreakModeMiddleTruncation;
		m_line1.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		m_line1.numberOfLines = 0;
		[self addSubview:m_line1];
		
		m_line2 = [[UILabel alloc] initWithFrame:CGRectZero];
		m_line2.backgroundColor = [UIColor clearColor];
		m_line2.highlightedTextColor = [UIColor blackColor];
		m_line2.textColor = LINE2_COLOR;
		m_line2.font = LINE2_FONT;
		m_line2.textAlignment = UITextAlignmentLeft;
		m_line2.lineBreakMode = UILineBreakModeMiddleTruncation;
		m_line2.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		m_line2.numberOfLines = 0;
		[self addSubview:m_line2];
	}
	return self;
}


- (void)dealloc 
{
	[m_title release];
	[m_line1 release];
	[m_line2 release];
	[m_rd release];
	[super dealloc];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];
	
	// Configure the view for the selected state
	m_title.highlighted = selected;
	m_line1.highlighted = selected;
	m_line2.highlighted = selected;
}


- (void)setRowData:(TableRowData *)rd
{
	if ( nil == rd )
	{
		[m_title setText:@""];
		[m_line1 setText:@""];
		[m_line2 setText:@""];
		self.accessoryType = UITableViewCellAccessoryNone;
		return;
	}
	
	m_rd = [rd retain];
	
	[self updateCell];
}


- (void)updateCell
{
	UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
	if ( UIDeviceOrientationUnknown == orientation ) orientation = UIDeviceOrientationPortrait;
	
	if ( -1 == CELL_MAX_WIDTH_PORTRAIT )
	{
		if ( UIDeviceOrientationPortrait == orientation || UIDeviceOrientationPortraitUpsideDown == orientation )
		{
			CELL_MAX_WIDTH_PORTRAIT = CGRectGetWidth([UIScreen mainScreen].bounds) - (2.0f * CELL_HPADDING);
		}
		else
		{
			CELL_MAX_WIDTH_PORTRAIT = CGRectGetHeight([UIScreen mainScreen].bounds) - (2.0f * CELL_HPADDING);
		}
	}
	if ( -1 == CELL_MAX_WIDTH_LANDSCAPE )
	{
		if ( UIDeviceOrientationPortrait == orientation || UIDeviceOrientationPortraitUpsideDown == orientation )
		{
			CELL_MAX_WIDTH_LANDSCAPE = CGRectGetHeight([UIScreen mainScreen].bounds) - (2.0f * CELL_HPADDING);
		}
		else
		{
			CELL_MAX_WIDTH_LANDSCAPE = CGRectGetWidth([UIScreen mainScreen].bounds) - (2.0f * CELL_HPADDING);
		}
	}
	
	
	// accessory type
	SEL none = @selector(rowActionNone:);
	if ( m_rd.action == none )
	{
		self.accessoryType = UITableViewCellAccessoryNone;
	}
	else
	{
		self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	}
	
	// setup the title text
	NSString *titleTxt = @"";
	if ( [m_rd.title length] > 0 )
	{
		// strip out any leading "{XX}_"
		NSArray *fldArray = [m_rd.title componentsSeparatedByString:@"_"];
		if ( [fldArray count] > 1 )
		{
			titleTxt = [fldArray objectAtIndex:([fldArray count]-1)];
		}
		else
		{
			titleTxt = m_rd.title;
		}
	}
	
	CGFloat line1Height = [CustomTableCell line1HeightForRow:m_rd withOrientation:orientation];
	CGFloat line2Height = [CustomTableCell line2HeightForRow:m_rd withOrientation:orientation];
	
	CGFloat cellMinX = CELL_XSTART;
	CGFloat cellWidth = CGRectGetWidth(self.contentView.frame) - (2.0f*CELL_HPADDING);
	//CGFloat cellWidth = (UIDeviceOrientationPortrait == orientation ? CELL_MAX_WIDTH_PORTRAIT : CELL_MAX_WIDTH_LANDSCAPE);
	//CGFloat cellWidth = CELL_MAX_WIDTH_PORTRAIT;
	//cellWidth -= (CELL_DISCLOSURE_WIDTH + (3.0f*CELL_HPADDING));
	
	CGRect titleFrame = CGRectMake(cellMinX,
								   CELL_VPADDING,
								   ([m_rd.line1 length] > 0 ? TITLE_WIDTH : cellWidth),
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
	if ( [m_rd.line2 length] > 0 )
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
	m_title.font = (nil == m_rd.titleFont ? TITLE_FONT : m_rd.titleFont);
	m_title.textColor = (nil == m_rd.titleColor ? TITLE_COLOR : m_rd.titleColor);
	m_title.textAlignment = m_rd.titleAlignment;
	
	m_line1.font = (nil == m_rd.line1Font ? LINE1_FONT : m_rd.line1Font);
	m_line1.textColor = (nil == m_rd.line1Color ? LINE1_COLOR : m_rd.line1Color);
	m_line1.textAlignment = m_rd.line1Alignment;
	
	m_line2.font = (nil == m_rd.line2Font ? LINE2_FONT : m_rd.line2Font);
	m_line2.textColor = (nil == m_rd.line2Color ? LINE2_COLOR : m_rd.line2Color);
	m_line2.textAlignment = m_rd.line2Alignment;

	[m_title setFrame:titleFrame];
	[m_title setText:titleTxt];
	
	[m_line1 setFrame:line1Frame];
	[m_line1 setText:m_rd.line1];
	
	[m_line2 setFrame:line2Frame];
	[m_line2 setText:m_rd.line2];
}


@end

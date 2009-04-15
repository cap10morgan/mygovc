//
//  LegislatorInfoCell.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LegislatorInfoCell.h"


@implementation LegislatorInfoCell

static const CGFloat KEYNAME_WIDTH = 65.0f;
static const CGFloat CELL_XSTART = 16.0f;
static const CGFloat CELL_HPADDING = 6.0f;
static const CGFloat CELL_VPADDING = 5.0f;

static const CGFloat CELL_DISCLOSURE_WIDTH = 15.0f;

static const CGFloat CELL_MAX_WIDTH = 306.0f;
static const CGFloat VALUE_MAX_HEIGHT = 150.0f;

#define FIELD_COLOR [UIColor blackColor]
#define FIELD_FONT  [UIFont boldSystemFontOfSize:13.0f]

#define VALUE_COLOR [UIColor darkGrayColor]
#define VALUE_FONT  [UIFont systemFontOfSize:13.0f]

#define VALUE_COLOR_FULL [UIColor blackColor]
#define VALUE_FONT_FULL  [UIFont boldSystemFontOfSize:14.0f]


enum
{
	eTAG_FIELD = 999,
	eTAG_VALUE = 998,
};

+ (CGFloat) cellHeightForText:(NSString *)text withKeyname:(NSString *)field
{
	
	CGSize cellSz;
	if ( [field length] > 0 )
	{
		CGFloat maxWidth = CELL_MAX_WIDTH - KEYNAME_WIDTH - (4.0f*CELL_HPADDING) - CELL_DISCLOSURE_WIDTH;
		cellSz = [text sizeWithFont:VALUE_FONT
					   constrainedToSize:CGSizeMake(maxWidth,VALUE_MAX_HEIGHT) 
					   lineBreakMode:UILineBreakModeMiddleTruncation];
	}
	else
	{
		CGFloat maxWidth = CELL_MAX_WIDTH - CELL_DISCLOSURE_WIDTH - CELL_HPADDING;
		cellSz = [text sizeWithFont:VALUE_FONT_FULL
					   constrainedToSize:CGSizeMake(maxWidth,VALUE_MAX_HEIGHT) 
					   lineBreakMode:UILineBreakModeMiddleTruncation];
	}
	
	// return a padded height :-)
	return (cellSz.height + (4.0f*CELL_VPADDING));
}


- (void)dealloc 
{
	[super dealloc];
}


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier 
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		self.selectionStyle = UITableViewCellSelectionStyleGray;
		
		UILabel *fieldView = [[UILabel alloc] initWithFrame:CGRectZero];
		fieldView.backgroundColor = [UIColor clearColor];
		fieldView.highlightedTextColor = [UIColor blackColor];
		fieldView.textColor = FIELD_COLOR;
		fieldView.font = FIELD_FONT;
		fieldView.textAlignment = UITextAlignmentLeft;
		fieldView.adjustsFontSizeToFitWidth = YES;
		fieldView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		[fieldView setTag:eTAG_FIELD];
		[self addSubview:fieldView];
		
		UILabel *valView = [[UILabel alloc] initWithFrame:CGRectZero];
		valView.backgroundColor = [UIColor clearColor];
		valView.highlightedTextColor = [UIColor blackColor];
		valView.textColor = VALUE_COLOR;
		valView.font = VALUE_FONT;
		valView.textAlignment = UITextAlignmentLeft;
		valView.lineBreakMode = UILineBreakModeMiddleTruncation;
		valView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		valView.numberOfLines = 5;
		[valView setTag:eTAG_VALUE];
		[self addSubview:valView];
	}
	return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
    [super setSelected:selected animated:animated];
	
    // Configure the view for the selected state
	UILabel *fieldView = (UILabel *)[self viewWithTag:eTAG_FIELD];
	fieldView.highlighted = selected;
	
	UILabel *valView = (UILabel *)[self viewWithTag:eTAG_VALUE];
	valView.highlighted = selected;
}


- (void)setField:(NSString *)field withValue:(NSString *)value
{
	UILabel *fieldView = (UILabel *)[self viewWithTag:eTAG_FIELD];
	
	// set the field (keyname) text 
	NSString *fieldTxt = @"";
	if ( nil != field )
	{
		// strip out any leading "{XX}_"
		NSArray *fldArray = [field componentsSeparatedByString:@"_"];
		if ( [fldArray count] > 1 )
		{
			fieldTxt = [[field componentsSeparatedByString:@"_"] objectAtIndex:([fldArray count]-1)];
		}
		else
		{
			fieldTxt = field;
		}
	}
	
	// set the value
	UILabel *valView = (UILabel *)[self viewWithTag:eTAG_VALUE];
	
	
	// adjust the height of each view
	CGFloat cellHeight = [LegislatorInfoCell cellHeightForText:value withKeyname:field];
	
	CGFloat cellMinX = CELL_XSTART;
	CGFloat cellWidth = CGRectGetWidth(self.contentView.frame) - (3.0f*CELL_HPADDING) - CELL_DISCLOSURE_WIDTH;
	
	CGRect fieldFrame = CGRectMake(cellMinX,
								   CELL_VPADDING,
								   KEYNAME_WIDTH,
								   cellHeight);
	CGRect valFrame;
	
	// if we weren't passed a field name, extend the value rectangle to
	// fill the entire cell
	if ( [fieldTxt length] < 1 )
	{
		valFrame = CGRectMake(cellMinX, CELL_VPADDING, cellWidth, cellHeight);
		
		valView.font = VALUE_FONT_FULL;
		valView.textColor = VALUE_COLOR_FULL;
	}
	else
	{
		// make sure the value rectangle is in its proper place
		valFrame = CGRectMake(CGRectGetMaxX(fieldFrame) + CELL_HPADDING,
							  CELL_VPADDING,
							  cellWidth - CGRectGetWidth(fieldFrame) - (3.0f*CELL_HPADDING),
							  cellHeight);
		valView.font = VALUE_FONT;
		valView.textColor = VALUE_COLOR;
	}
	
	[fieldView setFrame:fieldFrame];
	[fieldView setText:fieldTxt];
	
	[valView setFrame:valFrame];
	[valView setText:value];
}


@end

//
//  LegislatorInfoCell.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LegislatorInfoCell.h"


@implementation LegislatorInfoCell

static const CGFloat KEYNAME_WIDTH = 60.0f;
static const CGFloat VALUE_WIDTH = 225.0f;
static const CGFloat CELL_OFFSET = 15.0f;
static const CGFloat CELL_PADDING = 5.0f;

+ (CGFloat) cellHeightForText:(NSString *)text
{
	CGSize cellSz = [text sizeWithFont:[UIFont systemFontOfSize:14.0f]
						constrainedToSize:CGSizeMake(225.0f,200.0f) 
						lineBreakMode:UILineBreakModeMiddleTruncation];
	
	return (cellSz.height + 18.0f); // the 18 is for padding on top and bottom :-)
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
		
		CGFloat frameX = CELL_OFFSET;
		CGFloat frameY = 0.0f;
	//	CGFloat frameW = self.contentView.bounds.size.width - (frameX * 2.0f);
		CGFloat frameH = (CGRectGetHeight(frame) > 0) ? 
							CGRectGetHeight(frame) : 
							self.contentView.bounds.size.height - (frameY * 2.0f);
		
		CGRect fieldRect = CGRectMake(frameX, frameY, KEYNAME_WIDTH, frameH);
		UILabel *fieldView = [[UILabel alloc] initWithFrame:fieldRect];
		fieldView.backgroundColor = [UIColor clearColor];
		fieldView.textColor = [UIColor blackColor];
		fieldView.font = [UIFont boldSystemFontOfSize:15.0f];
		fieldView.textAlignment = UITextAlignmentLeft;
		//fieldView.numberOfLines = 2;
		fieldView.adjustsFontSizeToFitWidth = YES;
		[fieldView setTag:999];
		
		CGRect valRect = CGRectMake(frameX + CGRectGetWidth(fieldRect) + CELL_PADDING, 
									frameY, 
									VALUE_WIDTH, 
									frameH);
		UILabel *valView = [[UILabel alloc] initWithFrame:valRect];
		valView.backgroundColor = [UIColor clearColor];
		valView.textColor = [UIColor darkGrayColor];
		valView.font = [UIFont systemFontOfSize:14.0f];
		valView.textAlignment = UITextAlignmentLeft;
		valView.lineBreakMode = UILineBreakModeMiddleTruncation;
		valView.baselineAdjustment = UIBaselineAdjustmentAlignCenters;
		valView.numberOfLines = 5;
		[valView setTag:998];
		
		[self addSubview:fieldView];
		[self addSubview:valView];
		
		[fieldView release];
		[valView release];
	}
	return self;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
	UILabel *fieldView = (UILabel *)[self viewWithTag:999];
	fieldView.highlighted = selected;
	
	UILabel *valView = (UILabel *)[self viewWithTag:998];
	valView.highlighted = selected;
}


- (void)setField:(NSString *)field withValue:(NSString *)value
{
	// adjust the height of each view
	CGFloat height = [LegislatorInfoCell cellHeightForText:value];
	
	UILabel *fieldView = (UILabel *)[self viewWithTag:999];
	
	NSString *fieldTxt = @"";
	if ( nil != field )
	{
		// strip out the leading "XX_"
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
	[fieldView setText:fieldTxt];
	
	
	UILabel *valView = (UILabel *)[self viewWithTag:998];
	[valView setText:value];
	
	CGRect fieldFrame = CGRectMake(CGRectGetMinX(fieldView.frame),
											 CGRectGetMinY(fieldView.frame),
											 KEYNAME_WIDTH,
											 height );
	CGRect valFrame;
	
	// if we weren't passed a field name, extend the value rectangle to
	// fill the entire cell
	if ( [fieldTxt length] < 1 )
	{
		CGFloat minX = CGRectGetMinX(fieldView.frame);
		CGFloat minY = CGRectGetMinY(fieldView.frame);
		valFrame = CGRectMake(minX, minY, KEYNAME_WIDTH + CELL_PADDING + VALUE_WIDTH, height);
		
		valView.font = [UIFont boldSystemFontOfSize:15.0f];
	}
	else
	{
		// make sure the value rectangle is in its proper place
		valFrame = CGRectMake(CGRectGetMaxX(fieldFrame) + CELL_PADDING,
							   CGRectGetMinY(fieldFrame),
							   VALUE_WIDTH,
							   height);
		valView.font = [UIFont systemFontOfSize:14.0f];
	}
	
	[fieldView setFrame:fieldFrame];
	[valView setFrame:valFrame];
}


@end

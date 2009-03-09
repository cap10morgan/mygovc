//
//  LegislatorInfoCell.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LegislatorInfoCell.h"


@implementation LegislatorInfoCell

- (void)dealloc 
{
	[super dealloc];
}


- (id)initWithFrame:(CGRect)frame reuseIdentifier:(NSString *)reuseIdentifier 
{
	if (self = [super initWithFrame:frame reuseIdentifier:reuseIdentifier]) 
	{
		CGFloat frameX = 15.0f;
		CGFloat frameY = 0.0f;
		CGFloat frameW = self.contentView.bounds.size.width - (frameX * 2.0f);
		CGFloat frameH = self.contentView.bounds.size.height - (frameY * 2.0f);
		CGRect fieldRect = CGRectMake(frameX, frameY, frameW/3.0f, frameH);
		UILabel *fieldView = [[UILabel alloc] initWithFrame:fieldRect];
		fieldView.backgroundColor = [UIColor clearColor];
		fieldView.textColor = [UIColor blackColor];
		fieldView.font = [UIFont boldSystemFontOfSize:18.0f];
		fieldView.textAlignment = UITextAlignmentLeft;
		fieldView.adjustsFontSizeToFitWidth = YES;
		[fieldView setTag:999];
		
		CGRect valRect = CGRectMake(frameX + CGRectGetWidth(fieldRect)+5.0f, 
									frameY, 
									frameW - CGRectGetWidth(fieldRect) - 10.0f, 
									frameH);
		UILabel *valView = [[UILabel alloc] initWithFrame:valRect];
		valView.backgroundColor = [UIColor clearColor];
		valView.textColor = [UIColor darkGrayColor];
		valView.font = [UIFont systemFontOfSize:14.0f];
		valView.textAlignment = UITextAlignmentLeft;
		valView.lineBreakMode = UILineBreakModeMiddleTruncation;
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
	UILabel *fieldView = (UILabel *)[self viewWithTag:999];
	// strip out the leading "XX_"
	[fieldView setText:[[field componentsSeparatedByString:@"_"] objectAtIndex:1]];
	
	UILabel *valView = (UILabel *)[self viewWithTag:998];
	[valView setText:value];
}


@end

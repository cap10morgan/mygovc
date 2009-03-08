//
//  LegislatorHeaderView.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LegislatorHeaderView.h"
#import "LegislatorContainer.h"

@implementation LegislatorHeaderView


- (void)dealloc 
{
	[m_legislator release];
	[super dealloc];
}


- (id)initWithFrame:(CGRect)frame 
{
	if (self = [super initWithFrame:frame]) 
	{
		self.backgroundColor = [UIColor blackColor];
		
		// Initialization code - setup subviews...
		CGRect nameRect = CGRectMake(105.0f, 0.0, self.bounds.size.width-110.0f, 40);
		UILabel *nameView = [[UILabel alloc] initWithFrame:nameRect];
		nameView.backgroundColor = [UIColor clearColor];
		nameView.textColor = [UIColor whiteColor];
		nameView.font = [UIFont boldSystemFontOfSize:22.0f];
		nameView.textAlignment = UITextAlignmentCenter;
		nameView.adjustsFontSizeToFitWidth = YES;
		[nameView setTag:999];
		
		CGRect buttonRect = CGRectMake(105.0f, 45, self.bounds.size.width-105.0f, 20.0f);
		UILabel *buttonView = [[UILabel alloc] initWithFrame:buttonRect];
		buttonView.backgroundColor = [UIColor clearColor];
		buttonView.textColor = [UIColor whiteColor];
		buttonView.font = [UIFont boldSystemFontOfSize:14.0f];
		buttonView.textAlignment = UITextAlignmentCenter;
		buttonView.adjustsFontSizeToFitWidth = YES;
		buttonView.text = @"Add To Contacts...";
		[buttonView setTag:998];
		
		CGRect imgRect = CGRectMake(2.0f, 2.0f, 100.0f, 120.0f);
		UIImageView *imgView = [[UIImageView alloc] initWithFrame:imgRect];
		[imgView setTag:997];
		
		[self addSubview:nameView];
		[self addSubview:buttonView];
		[self addSubview:imgView];
		
		[nameView release];
		[buttonView release];
		[imgView release];
	}
	return self;
}


- (void)setLegislator:(LegislatorContainer *)legislator
{
	[m_legislator release];
	m_legislator = [legislator retain];
	
	UILabel *nameView = (UILabel *)[self viewWithTag:999];
	// strip out the leading "XX_"
	NSString *fname = [m_legislator firstname];
	NSString *mname = [m_legislator middlename];
	NSString *lname = [m_legislator lastname];
	NSString *nm = [[NSString alloc] initWithFormat:@"%@. %@ %@%@%@",[m_legislator title],fname,(mname ? mname : @""),(mname ? @" " : @""),lname];
	[nameView setText:nm];
	
	// XXX - replace with actual image of legislator!
	UIImage *legImg = [[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"eagleIcon" ofType:@"png" inDirectory:@"/"]];
	
	UIImageView *imgView = (UIImageView *)[self viewWithTag:997];
	imgView.image = legImg;
}


- (void)drawRect:(CGRect)rect 
{
	// Drawing code
}


@end

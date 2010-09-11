/*
 File: ContractorSpendingTableCell.m
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

#import "ContractorSpendingTableCell.h"
#import "ContractorSpendingData.h"

@implementation ContractorSpendingTableCell

@synthesize m_dollarsView;
@synthesize m_ctrView;
@synthesize m_detailButton;
@synthesize m_contractor;

enum
{
	eTAG_ACTIVITY = 996,
};


- (void)setDetailTarget:(id)tgt withSelector:(SEL)sel
{
	// set delegate for detail button press!
	[m_detailButton addTarget:tgt action:sel forControlEvents:UIControlEventTouchUpInside];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
	[super setSelected:selected animated:animated];

	m_dollarsView.highlighted = selected;
	m_ctrView.highlighted = selected;
}


- (void)dealloc 
{
	[m_contractor release];
	[super dealloc];
}


- (void)setContractor:(ContractorInfo *)contractor
{
	UIActivityIndicatorView *aiView	= (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	
	if ( nil == contractor ) 
	{
		if ( ![myGovAppDelegate networkIsAvailable:NO]  )
		{
			[m_ctrView setText:@"No network!"];
			[m_dollarsView setText:@""];
			[m_detailButton setHidden:YES];
		}
		else
		{
			// render a UIActivityView!
			[m_ctrView setText:@"Downloading..."];
			[m_dollarsView setText:@""];
			[m_detailButton setHidden:YES];
			
			if ( nil == aiView )
			{
				CGFloat cellHeight = CGRectGetHeight(m_ctrView.frame);
				
				aiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
				aiView.hidesWhenStopped = YES;
				[aiView setFrame:CGRectMake(0.0f, 0.0f, cellHeight/2.0f, cellHeight/2.0f)];
				[aiView setCenter:CGPointMake(CGRectGetMaxX(m_ctrView.frame) + cellHeight/2.0f, cellHeight/2.0f)];
				[aiView setTag:eTAG_ACTIVITY];
				[self addSubview:aiView];
				[aiView release];
			}
			[aiView startAnimating];
		}
		return;
	}
	
	if ( nil != aiView ) [aiView stopAnimating];
	
	[m_contractor release];
	m_contractor = [contractor retain];
	
	CGFloat millionsOfDollars = m_contractor.m_obligatedAmount / 1000000;
	NSString *dollarsTxt = [[NSString alloc] initWithFormat:@"$%.1fM",millionsOfDollars];
	
	[m_ctrView setText:m_contractor.m_parentCompany];
	[m_dollarsView setText:dollarsTxt];
	[m_detailButton setHidden:NO];
}


@end

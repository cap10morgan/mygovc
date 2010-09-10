/*
 File: LegislatorNameCell.m
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

#import "LegislatorNameCell.h"
#import "LegislatorContainer.h"
#import "myGovAppDelegate.h"

@implementation LegislatorNameCell

@synthesize m_nameView, m_partyView, m_infoView, m_detailButton;
@synthesize m_tableRange, m_legislator;


- (void)dealloc
{
	[m_legislator release];
	[super dealloc];
}


- (void)setDetailTarget:(id)tgt withSelector:(SEL)sel
{
	// set delegate for detail button press!
	[m_detailButton addTarget:tgt action:sel forControlEvents:UIControlEventTouchUpInside];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
{
    [super setSelected:selected animated:animated];
	
    // Configure the view for the selected state
	m_nameView.highlighted = selected;
	m_partyView.highlighted = selected;
	m_infoView.highlighted = selected;
	//m_detailButton.highlighted = selected;
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
	
	[m_nameView setText:name];
	[m_partyView setText:party];
	[m_partyView setTextColor:[LegislatorContainer partyColor:[legislator party]]];
	[m_infoView setText:info];
}


@end

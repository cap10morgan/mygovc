/*
 File: LocateAlertView.m
 Project: myGovernment
 Org: iPhoneFLOSS
 
 Copyright (C) 2010 Jeremy C. Andrus <jeremyandrus@iphonefloss.com>
 
 Props to CodeSofa for this trick:
 http://codesofa.com/blog/archive/2009/07/15/look-uialertview-is-dating-uitableview.html
 
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

#import "LocateAlertView.h"

// Shhhh
@interface UIAlertView (private)
	- (void)layoutAnimated:(BOOL)fp8;
@end

@implementation LocateAlertView

@synthesize m_zip;

static CGFloat kElementPadding = 5.0f;

- (void)dealloc 
{
	[m_zip release];
    [super dealloc];
}

- (void)prepare 
{
	if ( 0 == m_tfHeight ) 
	{
		m_tfHeight = 31;
	}
	
	// Calculate the TableViewHeight with padding
	m_tfExtraHeight = m_tfHeight + 2 * kElementPadding;
	
	m_zip = [[UITextField alloc] initWithFrame:CGRectZero];
	m_zip.clearButtonMode = UITextFieldViewModeWhileEditing;
	m_zip.keyboardType = UIKeyboardTypeNumberPad;
	m_zip.keyboardAppearance = UIKeyboardAppearanceAlert;
	m_zip.autocorrectionType = UITextAutocorrectionTypeNo;
	m_zip.borderStyle = UITextBorderStyleRoundedRect;
	m_zip.autocapitalizationType = UITextAutocapitalizationTypeNone;
	[m_zip setPlaceholder:@"Enter Zip"];
	
	// Insert it as the first subview
	[self insertSubview:m_zip atIndex:0];
}


- (void)layoutAnimated:(BOOL)fp8 
{
	[super layoutAnimated:fp8];
	[self setFrame:CGRectMake(self.frame.origin.x, self.frame.origin.y - m_tfExtraHeight/2, self.frame.size.width, self.frame.size.height + m_tfExtraHeight)];
	
	// We get the lowest non-control view (i.e. Labels) so we can place the table view just below
	UIView *lowestView = [self.subviews objectAtIndex:0];
	int i = 0;
	while (![[self.subviews objectAtIndex:i] isKindOfClass:[UIControl class]]) 
	{
		UIView *v = [self.subviews objectAtIndex:i];
		if (lowestView.frame.origin.y + lowestView.frame.size.height < v.frame.origin.y + v.frame.size.height) 
		{
			lowestView = v;
		}
		
		i++;
	}
	
	// calculate the text field width
	CGFloat zipWidth = self.frame.size.width - 22;
	
	m_zip.frame = CGRectMake(11.0f, lowestView.frame.origin.y + lowestView.frame.size.height + 2 * kElementPadding, zipWidth, m_tfHeight);
	
	for ( UIView *sv in self.subviews ) 
	{
		// Move all Controls down
		if ( [sv isKindOfClass:[UIControl class]] )
		{
			sv.frame = CGRectMake(sv.frame.origin.x, sv.frame.origin.y + m_tfExtraHeight, sv.frame.size.width, sv.frame.size.height);
		}
	}
}

@end

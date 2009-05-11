/*
 File: ProgressOverlayViewController.m
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

#import "ProgressOverlayViewController.h"
#import <QuartzCore/CAAnimation.h>

// 
// HUD Text parameters 
// 
#define HUD_FONT             [UIFont boldSystemFontOfSize:20.0f]
#define HUD_TXTCOLOR         [UIColor whiteColor]
#define HUD_TXTSHADOW_COLOR  [UIColor blackColor]
#define HUD_MAX_SIZE         CGSizeMake(200.0f,200.0f)
#define HUD_TXT_MARGIN       32.0f

enum
{
	eTAG_LABEL    = 111,
	eTAG_ACTIVITY = 222,
};


// UIView subclass to draw rounded corners :-)
@interface ProgressOverlayView : UIView
{
@private
	BOOL m_shouldAnimate;
	BOOL m_animating;
	BOOL m_needsToHide;
	//NSInteger m_framePlacementHack;
	NSMutableArray *m_txtArray;
	NSString *m_hackTxtDisplay;
}
	- (void)setShouldAnimate:(BOOL)yesOrNo;
	- (void)setupLabelAndActivityViews;
	- (void)setNewText:(id)txt;
	- (void)hideView;
@end



@implementation ProgressOverlayViewController

@synthesize m_window;


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning];
}


- (void)dealloc 
{
	[m_window release];
	[super dealloc];
}


- (id)initWithWindow:(UIView *)window
{
	if ( self = [super init] )
	{
		m_window = [window retain];
		
		ProgressOverlayView *overlayView = [[ProgressOverlayView alloc] initWithFrame:m_window.frame];
		overlayView.backgroundColor = [UIColor clearColor];
		self.view = overlayView;
		[overlayView release];
		
		[self.view setNeedsDisplay];
	}
	return self;
}


- (void)show:(BOOL)yesOrNo
{	
	if ( nil != m_window )
	{
		if ( yesOrNo )
		{
			if ( ![self.view isDescendantOfView:m_window] )
			{
				[m_window addSubview:self.view];
			}
			self.view.hidden = NO;			
			[self.view setNeedsDisplay];
		}
		else
		{
			[self.view setNeedsDisplay];
			[self.view performSelector:@selector(hideView)];
		}
	}
}


- (void)setText:(NSString *)text andIndicateProgress:(BOOL)shouldAnimate
{
	ProgressOverlayView *pov = (ProgressOverlayView *)(self.view);
	[pov setShouldAnimate:shouldAnimate];
	[pov setNewText:text];
	[pov setNeedsDisplay];
}


- (NSString *)currentText
{
	UILabel *lbl = (UILabel *)[self.view viewWithTag:eTAG_LABEL];
	if ( nil != lbl )
	{
		return lbl.text;
	}
	else
	{
		return nil;
	}
}


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	return YES;
}


@end


#pragma mark ProgressOverlayView


@implementation ProgressOverlayView


- (id)initWithFrame:(CGRect)frame
{
	if ( self = [super initWithFrame:frame] )
	{
		m_animating = NO;
		m_txtArray = [[NSMutableArray alloc] init];
		//m_framePlacementHack = 1;
		m_hackTxtDisplay = nil;
		[self setupLabelAndActivityViews];
	}
	return self;
}


- (void)dealloc
{
	[m_txtArray release];
	[m_hackTxtDisplay release];
    [super dealloc];
}


- (void)fillRoundedRect:(CGRect)rect inContext:(CGContextRef)context
{
    float radius = 7.0f;
    
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.1f, 0.9f);
    CGContextMoveToPoint(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect));
    CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMinY(rect) + radius, radius, 3 * M_PI / 2, 0, 0);
    CGContextAddArc(context, CGRectGetMaxX(rect) - radius, CGRectGetMaxY(rect) - radius, radius, 0, M_PI / 2, 0);
    CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMaxY(rect) - radius, radius, M_PI / 2, M_PI, 0);
    CGContextAddArc(context, CGRectGetMinX(rect) + radius, CGRectGetMinY(rect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
    
    CGContextClosePath(context);
    CGContextFillPath(context);
}


- (void)drawRect:(CGRect)rect
{
    // draw a box with rounded corners to fill the view -
    CGRect boxRect = self.bounds;
    CGContextRef ctxt = UIGraphicsGetCurrentContext();    
    boxRect = CGRectInset(boxRect, 1.0f, 1.0f);
    [self fillRoundedRect:boxRect inContext:ctxt];
}


- (void)setShouldAnimate:(BOOL)yesOrNo
{
	m_shouldAnimate = yesOrNo;
}


- (void)setupLabelAndActivityViews
{
	UILabel *lbl = (UILabel *)[self viewWithTag:eTAG_LABEL];
	UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	
	if ( nil == activity )
	{
		activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		activity.hidesWhenStopped = YES;
		[activity setFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
		[activity setCenter:CGPointMake(100.0f, 20.0f)];
		[activity setTag:eTAG_ACTIVITY];
		[self addSubview:activity];
		//[activity release];
	}
	
	if ( nil == lbl )
	{
		lbl = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,40.0f,200.0f,160.0f)];
		lbl.font = HUD_FONT;
		lbl.adjustsFontSizeToFitWidth = YES;
		lbl.numberOfLines = 4;
		lbl.backgroundColor = [UIColor clearColor];
		lbl.lineBreakMode = UILineBreakModeWordWrap;
		lbl.textAlignment = UITextAlignmentCenter;
		lbl.textColor = HUD_TXTCOLOR;
		lbl.shadowColor = HUD_TXTSHADOW_COLOR;
		lbl.shadowOffset = CGSizeMake(0.0f, -1.0f);
		[lbl setTag:eTAG_LABEL];
		[self addSubview:lbl];
		//[lbl release];
	}
}


- (void)animateNextMessage
{
	if ( ([m_txtArray count] < 1) && (nil == m_hackTxtDisplay) )
	{
		m_animating = NO;
		return;
	}
	
	[self setHidden:NO];
	m_animating = YES;
	
	NSString *text;
	if ( nil != m_hackTxtDisplay )
	{
		text = m_hackTxtDisplay;
		m_hackTxtDisplay = nil;
	}
	else
	{
		text = [[m_txtArray objectAtIndex:0] retain];
		[m_txtArray removeObjectAtIndex:0];
		if ( [m_txtArray count] < 1 )
		{
			// HACK: animate the last element twice
			[m_hackTxtDisplay release];
			m_hackTxtDisplay = [text retain];
		}
	}
	
	UILabel *lbl = (UILabel *)[self viewWithTag:eTAG_LABEL];
	UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	
	// get a rectangle which can minimally contain the text
	CGSize fontSz = [text sizeWithFont:lbl.font constrainedToSize:HUD_MAX_SIZE lineBreakMode:UILineBreakModeWordWrap];
	CGRect fontRect = CGRectMake(20.0f, 50.0f, fontSz.width, fontSz.height);
	CGRect parentRect = ([self superview] ? [self superview].frame : CGRectMake(0.0f,0.0f,320.0f,480.0f));
	if ( CGRectGetWidth(parentRect) < 1 || CGRectGetHeight(parentRect) < 1 )
	{
		parentRect = CGRectMake(0.0f, 0.0f, 320.0f, 480.0f);
	}
	
	// create a rectangle for the view which can minimally contain the whole text
	// (with a 20 pixel margin on all sides)
	CGFloat dx = CGRectGetWidth(parentRect) - fontSz.width - HUD_TXT_MARGIN;
	CGFloat dy = CGRectGetHeight(parentRect) - fontSz.height - 50.0f - HUD_TXT_MARGIN;
	CGRect viewRect = CGRectInset(parentRect, dx/2.0f, dy/2.0f );
	if ( CGRectGetMinX(viewRect) <= 0 || CGRectGetMinY(viewRect) > 480.0f )
	{
		viewRect = CGRectMake(100.0f,180.0f,120.0f,120.0f);
	}
	
	// re-center the activity indicator
	//[activity setFrame:CGRectMake(0.0f,0.0f,CGRectGetWidth(viewRect),CGRectGetHeight(viewRect))];
	
	// animate the transition!
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:0.27f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(textAnimationFinished:finished:context:)];
	
	// set the text
	[lbl setText:text];
	
	// re-size the label and the view based on the input text
	[lbl setFrame:fontRect];
	[self setFrame:viewRect];
	
	[activity setHidden:YES];
	
	[UIView commitAnimations];
	
	[text release];
}

- (void)textAnimationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
	if ( [m_txtArray count] > 0 || (nil != m_hackTxtDisplay) )
	{
		// start the next animation!
		[self animateNextMessage];
	}
	else
	{
		m_animating = NO;
		
		// set the activity indicator here to avoid
		// a crazy-looking flicker in the main animation :-)
		UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
		[activity stopAnimating];
		[activity setFrame:CGRectMake(0.0f,0.0f,32.0f,32.0f)];
		[activity setCenter:CGPointMake(CGRectGetWidth(self.frame)/2.0f, 30.0f)];
		
		if ( m_shouldAnimate ) { [activity startAnimating]; [activity setHidden:NO]; }
		
		if ( m_needsToHide )
		{
			m_needsToHide = NO;
			[self hideView];
		}
		
		[self setNeedsDisplay];
	}
	
	[[self superview] setNeedsDisplay];
}


- (void)hideAnimationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
	self.hidden = YES;
}


- (void)setNewText:(id)txt
{
	if ( nil == txt ) return;
	
	NSString *myTxtCopy = [[NSString alloc] initWithString:txt];
	[m_txtArray addObject:myTxtCopy];
	[myTxtCopy release];
	
	if ( !m_animating )
	{
		[self animateNextMessage];
	}
	[self setNeedsDisplay];
}

- (void)hideView
{
	if ( m_animating )
	{
		m_needsToHide = YES;
		return;
	}
	
	UILabel *lbl = (UILabel *)[self viewWithTag:eTAG_LABEL];
	UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:0.15f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(hideAnimationFinished:finished:context:)];
	
	[lbl setFrame:CGRectZero];
	[activity setFrame:CGRectZero];
	[self setFrame:CGRectZero];
	
	[UIView commitAnimations];
	
	[self setNeedsDisplay];
}



@end


//
//  ProgressOverlayViewController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ProgressOverlayViewController.h"

// UIView subclass to draw rounded corners :-)
@interface ProgressOverlayView : UIView
{
	BOOL m_shouldAnimate;
}
	- (void)setShouldAnimate:(BOOL)yesOrNo;
	- (void)setNewText:(id)txt;
	- (void)hideView:(id)sender;
@end


enum
{
	eTAG_LABEL    = 111,
	eTAG_ACTIVITY = 222,
};


@interface ProgressOverlayViewController (private)
	- (void)setupLabelAndActivityViews;
@end


@implementation ProgressOverlayViewController

@synthesize m_activityWheel;
@synthesize m_label;
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
		//[overlayView setFrame:m_window.frame];
		self.view = overlayView;
		[overlayView release];
		
		m_label = nil;
		m_activityWheel = nil;
		[self setupLabelAndActivityViews];
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
			[self.view performSelector:@selector(hideView:) withObject:self];
			//self.view.hidden = YES;
		}
	}
}


- (void)setText:(NSString *)text andIndicateProgress:(BOOL)shouldAnimate
{
	self.view.hidden = NO;
	ProgressOverlayView *pov = (ProgressOverlayView *)(self.view);
	[pov setShouldAnimate:shouldAnimate];
	
	[self setupLabelAndActivityViews];
	
	[pov performSelector:@selector(setNewText:) withObject:text];
	[pov setNeedsDisplay];
}


/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
/*
- (void)viewDidLoad 
{
	[super viewDidLoad];
}
*/

// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}


#pragma mark ProgressOverlayViewController Private


- (void)setupLabelAndActivityViews
{
	// 
	// XXX - use a critical section here!
	// 
	[m_label removeFromSuperview];
	[m_activityWheel removeFromSuperview];
	
	m_activityWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	m_activityWheel.hidesWhenStopped = YES;
	[m_activityWheel setFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
	[m_activityWheel setCenter:CGPointMake(100.0f, 20.0f)];
	[m_activityWheel setTag:eTAG_ACTIVITY];
	[self.view addSubview:m_activityWheel];
	[m_activityWheel release];
	
	m_label = [[UILabel alloc] initWithFrame:CGRectMake(0.0f,40.0f,200.0f,160.0f)];
	m_label.font = [UIFont boldSystemFontOfSize:26.0f];
	m_label.adjustsFontSizeToFitWidth = YES;
	m_label.numberOfLines = 3;
	m_label.backgroundColor = [UIColor clearColor];
	m_label.lineBreakMode = UILineBreakModeWordWrap;
	m_label.textAlignment = UITextAlignmentCenter;
	m_label.textColor = [UIColor whiteColor];
	m_label.shadowColor = [UIColor blackColor];
	m_label.shadowOffset = CGSizeMake(0.0f, -1.0f);
	[m_label setTag:eTAG_LABEL];
	[self.view addSubview:m_label];
	[m_label release];
}

@end


#pragma mark ProgressOverlayView


@implementation ProgressOverlayView


- (void)dealloc
{
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


- (void)setNewText:(id)txt
{
	if ( nil == txt ) return;
	
	// 
	// XXX - use a critical section!
	// 
	
	NSString *text = [[NSString alloc] initWithString:(NSString *)txt];
	
	UILabel *lbl = (UILabel *)[self viewWithTag:eTAG_LABEL];
	UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	
	// set the text
	[lbl setText:text];
	[lbl setNeedsDisplay];
	
	// get a rectangle which can minimally contain the text
	CGSize fontSz = [text sizeWithFont:lbl.font constrainedToSize:CGSizeMake(200.0f,200.0f) lineBreakMode:UILineBreakModeWordWrap];
	CGRect fontRect = CGRectMake(20.0f, 50.0f, fontSz.width, fontSz.height);
	CGRect parentRect = ([self superview] ? [self superview].frame : CGRectZero);
	
	// create a rectangle for the view which can minimally contain the whole text
	// (with a 20 pixel margin on all sides)
	static CGFloat S_MARGIN = 40.0f;
	CGFloat dx = CGRectGetWidth(parentRect) - fontSz.width - S_MARGIN;
	CGFloat dy = CGRectGetHeight(parentRect) - fontSz.height - 50.0f - S_MARGIN;
	CGRect viewRect = CGRectInset(parentRect, dx/2.0f, dy/2.0f );
	
	// animate the transition!
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView beginAnimations:nil context:UIGraphicsGetCurrentContext()];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:0.20f];
	
	// re-center the activity indicator
	[activity setFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
	[activity setCenter:CGPointMake(CGRectGetWidth(viewRect)/2.0f, 30.0f)];
	
	// re-size the label and the view based on the input text
	[lbl setFrame:fontRect];
	[self setFrame:viewRect];
	
	[UIView commitAnimations];
	
	if ( m_shouldAnimate )
	{
		[activity startAnimating];
	}
	else
	{
		[activity stopAnimating];
	}
	
	[text release];
}


- (void)hideView:(id)sender
{
	UILabel *lbl = (UILabel *)[self viewWithTag:eTAG_LABEL];
	UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[self viewWithTag:eTAG_ACTIVITY];
	
	if ( self == sender )
	{
		[self setHidden:YES];
	}
	else
	{
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView beginAnimations:nil context:UIGraphicsGetCurrentContext()];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
		[UIView setAnimationDuration:0.20f];
		
		[lbl setFrame:CGRectZero];
		[activity setFrame:CGRectZero];
		[self setFrame:CGRectZero];
		
		[UIView commitAnimations];
	
		[self performSelector:@selector(hideView:) withObject:self afterDelay:0.30f];
		//[self setNeedsDisplay];
	}
}



@end


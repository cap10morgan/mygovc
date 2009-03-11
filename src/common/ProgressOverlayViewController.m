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
{}
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


// The designated initializer. Override to perform setup that is required before the view is loaded.
/*
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	if ( self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] ) 
	{
		// Custom initialization
	}
	return self;
}
*/

- (id)initWithWindow:(UIView *)window
{
	if ( self = [super init] )
	{
		m_window = [window retain];
		
		CGRect appFrame = [[UIScreen mainScreen] applicationFrame];
		ProgressOverlayView *overlayView = [[ProgressOverlayView alloc] initWithFrame:appFrame];
		//overlayView.backgroundColor = [UIColor colorWithRed:0.1f green:0.05f blue:0.1f alpha:0.90f];
		overlayView.backgroundColor = [UIColor clearColor];
		overlayView.frame = m_window.frame;
		self.view = overlayView;
		[overlayView release];
		
		m_activityWheel = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		m_activityWheel.hidesWhenStopped = YES;
		[m_activityWheel setFrame:CGRectMake(0.0f, 0.0f, 32.0f, 32.0f)];
		[m_activityWheel setCenter:CGPointMake(100.0f, 20.0f)];
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
		[self.view addSubview:m_label];
		[m_label release];
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
			self.view.hidden = YES;
		}
	}
}


- (void)setText:(NSString *)text andIndicateProgress:(BOOL)shouldAnimate
{
	m_label.text = text;
	[self.view setNeedsDisplay];
	
	// get a rectangle which can minimally contain the text
	CGSize fontSz = [text sizeWithFont:m_label.font constrainedToSize:CGSizeMake(200.0f,200.0f) lineBreakMode:UILineBreakModeWordWrap];
	CGRect fontRect = CGRectMake(20.0f, 50.0f, fontSz.width, fontSz.height);
	
	// create a rectangle for the view which can minimally contain the whole text
	// (with a 20 pixel margin on all sides)
	static CGFloat S_MARGIN = 40.0f;
	CGFloat dx = CGRectGetWidth(m_window.frame) - fontSz.width - S_MARGIN;
	CGFloat dy = CGRectGetHeight(m_window.frame) - fontSz.height - 50.0f - S_MARGIN;
	CGRect viewRect = CGRectInset(m_window.frame, dx/2.0f, dy/2.0f );
	
	// re-center the activity indicator
	[m_activityWheel setCenter:CGPointMake(CGRectGetWidth(viewRect)/2.0f, 30.0f)];
	
	// animate the transition!
	CGContextRef ctx = UIGraphicsGetCurrentContext();
	[UIView beginAnimations:nil context:ctx];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseIn];
	[UIView setAnimationDuration:0.25];
	
	// re-size the label and the view based on the input text
	[m_label setFrame:fontRect];
	[self.view setFrame:viewRect];
	
	[UIView commitAnimations];
	
	if ( shouldAnimate )
	{
		[m_activityWheel startAnimating];
	}
	else
	{
		[m_activityWheel stopAnimating];
	}
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


@end


@implementation ProgressOverlayView

- (void)dealloc
{
    [super dealloc];
}

- (void)fillRoundedRect:(CGRect)rect inContext:(CGContextRef)context
{
    float radius = 7.0f;
    
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.1, 0.9);
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

@end


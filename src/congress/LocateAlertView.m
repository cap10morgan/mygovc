    //
//  LocateAlertView.m
//  myGovernment
//
//  Created by Andrus, Jeremy on 6/28/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "LocateAlertView.h"


@implementation LocateAlertView

@synthesize m_zip, m_useZipButton, m_useLocationButton, m_cancelButton;

- (id)init
{
	if ( self = [super self] )
	{
	}
	return self;
}

- (void)dealloc 
{
    [super dealloc];
}

- (IBAction) useZipButtonPressed
{
	[self dismissWithClickedButtonIndex:1 animated:YES];
}

- (IBAction) useLocationButtonPressed
{
	[self dismissWithClickedButtonIndex:2 animated:YES];
}

- (IBAction) cancelButtonPressed
{
	[self dismissWithClickedButtonIndex:0 animated:YES];
}

- (void)show:(UIView *)parent
{
	[self setFrame:CGRectMake(50,30,240,240)];
	[super show];
	[m_zip becomeFirstResponder];
	[(UIAlertView *)super setFrame:CGRectMake(50,40,250,230)];
	
	/*
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:0.8f];
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(animationFinished:finished:context:)];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	*/
	/*
	if ( [UIDevice currentDevice].orientation == UIDeviceOrientationPortrait || 
			[UIDevice currentDevice].orientation == UIDeviceOrientationPortraitUpsideDown )
	{
		[UIView setAnimationTransition:UIViewAnimationTransitionFlipFromRight forView:topView cache:NO];
	}
	else 
	{
		[UIView setAnimationTransition:UIViewAnimationTransitionCurlUp forView:topView cache:NO];
	}
	*/
	
//	[parent addSubview:self];
	
	//[self setFrame:[self convertRect:parent.frame fromView:nil]];
	//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
	
	//[UIView commitAnimations];
}

- (void)animationFinished:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
}

@end

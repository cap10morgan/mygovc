//
//  ProgressOverlayViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ProgressOverlayViewController : UIViewController 
{
	UIActivityIndicatorView *m_activityWheel;
	UILabel *m_label;
	
	UIView *m_window;
}

@property (nonatomic, retain) UILabel *m_label;
@property (nonatomic, retain) UIActivityIndicatorView *m_activityWheel;
@property (nonatomic, retain) UIView *m_window;

- (id)initWithWindow:(UIView *)window;
- (void)show:(BOOL)yesOrNo;
- (void)setText:(NSString *)text andIndicateProgress:(BOOL)shouldAnimate;

@end
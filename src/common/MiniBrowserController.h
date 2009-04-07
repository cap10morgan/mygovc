//
//  MiniBrowserController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface MiniBrowserController : UIViewController <UIWebViewDelegate>
{
	IBOutlet UIToolbar *m_toolBar;
	IBOutlet UIWebView *m_webView;
	BOOL m_shouldStopLoadingOnHide;
@private
	BOOL m_loadingInterrupted;
	NSURL *m_urlToLoad;
	UIActivityIndicatorView *m_activity;
}

@property (nonatomic,retain) IBOutlet UIToolbar *m_toolBar;
@property (nonatomic,retain) IBOutlet UIWebView *m_webView;
@property (nonatomic) BOOL m_shouldStopLoadingOnHide;

+ (MiniBrowserController *)sharedBrowserWithURL:(NSURL *)urlOrNil;


- (IBAction)backButtonPressed:(id)button;
- (IBAction)fwdButtonPressed:(id)button;
- (IBAction)refreshButtonPressed:(id)button;

- (void)loadURL:(NSURL *)url;
- (void)stopLoading;

@end

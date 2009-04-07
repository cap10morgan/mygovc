//
//  MiniBrowserController.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/6/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MiniBrowserController.h"

@interface MiniBrowserController (private)
	- (void)enableBackButton:(BOOL)enable;
	- (void)enableFwdButton:(BOOL)enable;
@end


@implementation MiniBrowserController

@synthesize m_toolBar, m_webView, m_shouldStopLoadingOnHide;

static MiniBrowserController *s_browser = NULL;


+ (MiniBrowserController *)sharedBrowserWithURL:(NSURL *)urlOrNil
{
	if ( NULL == s_browser )
	{
		s_browser = [[MiniBrowserController alloc] initWithNibName:@"MiniBrowserView" bundle:nil];
		s_browser.m_webView.detectsPhoneNumbers = YES;
		s_browser.m_webView.scalesPageToFit = YES;
	}
	
	if ( nil != urlOrNil )
	{
		[s_browser loadURL:urlOrNil];
	}
	
	// let the caller take care of making this window visible...
	
	return s_browser;
}


// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) 
	{
		m_shouldStopLoadingOnHide = YES;
		m_loadingInterrupted = NO;
		m_urlToLoad = nil;
		m_activity = nil;
		[self enableBackButton:NO];
		[self enableFwdButton:NO];
	}
	return self;
}


- (void)didReceiveMemoryWarning 
{
	[super didReceiveMemoryWarning]; // Releases the view if it doesn't have a superview
	// Release anything that's not essential, such as cached data
}


- (void)dealloc 
{
	[super dealloc];
}


// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad 
{
	[super viewDidLoad];
	
	CGRect actFrame = CGRectMake( CGRectGetWidth(self.m_webView.frame)/2.0f - 16.0f,
								 CGRectGetHeight(self.m_webView.frame)/2.0f - 16.0f,
								 32.0f, 32.0f
								 );
	m_activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	[m_activity setFrame:actFrame];
	m_activity.hidesWhenStopped = YES;
	[self.m_webView addSubview:m_activity];
	[m_activity release];
	[m_activity stopAnimating];
}



- (void)viewWillAppear:(BOOL)animated
{
	[self enableBackButton:m_webView.canGoBack];
	[self enableFwdButton:m_webView.canGoForward];
	
	if ( nil != m_urlToLoad )
	{
		[self loadURL:m_urlToLoad];
		[m_urlToLoad release]; m_urlToLoad = nil;
	}
	else if ( m_loadingInterrupted )
	{
		[m_webView reload];
	}
	m_loadingInterrupted = NO;
	
	[super viewWillAppear:animated];
}


- (void)viewWillDisappear:(BOOL)animated 
{
	if ( m_shouldStopLoadingOnHide )
	{
		if ( m_webView.loading )
		{
			m_loadingInterrupted = YES;
		}
		[self stopLoading];
	}
	
	[super viewWillDisappear:animated];
}
 


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
	return YES;
}


- (IBAction)backButtonPressed:(id)button
{
	if ( m_webView.canGoBack ) [m_webView goBack];
}


- (IBAction)fwdButtonPressed:(id)button
{
	if ( m_webView.canGoForward ) [m_webView goForward];
}


- (IBAction)refreshButtonPressed:(id)button
{
	[m_webView reload];
}


- (void)loadURL:(NSURL *)url
{
	if ( nil == url ) return;
	
	// cancel any transaction currently taking place
	if ( m_webView.loading ) [m_webView stopLoading];
	
	if ( nil != m_webView )
	{
		[m_webView loadRequest:[NSURLRequest requestWithURL:url]];
	}
	else
	{
		[m_urlToLoad release];
		m_urlToLoad = [[NSURL alloc] initWithString:[url absoluteString]];
	}
}


- (void)stopLoading
{
	if ( m_webView.loading ) [m_webView stopLoading];
}


#pragma mark MiniBrowserController Private


- (void)enableBackButton:(BOOL)enable
{
	NSEnumerator *e = [m_toolBar.items objectEnumerator];
	id bb;
	while ( bb = [e nextObject] )
	{
		UIBarButtonItem *backButton = (UIBarButtonItem *)bb;
		if ( 999 == [backButton tag] )
		{
			[backButton setEnabled:enable];
			return;
		}
	}
}


- (void)enableFwdButton:(BOOL)enable
{
	NSEnumerator *e = [m_toolBar.items objectEnumerator];
	id bb;
	while ( bb = [e nextObject] )
	{
		UIBarButtonItem *fwdButton = (UIBarButtonItem *)bb;
		if ( 997 == [fwdButton tag] )
		{
			[fwdButton setEnabled:enable];
			return;
		}
	}
}


#pragma mark UIWebViewDelegate Methods 


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	// notify of an error?
}


- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	// always start loading - we're not real restrictive here...
	[m_activity startAnimating];
	
	return YES;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
	[m_activity stopAnimating];
	[self enableBackButton:m_webView.canGoBack];
	[self enableFwdButton:m_webView.canGoForward];
	
	// set the navigation bar title based on URL
	NSArray *urlComponents = [[[webView.request URL] absoluteString] componentsSeparatedByString:@"/"];
	if ( [urlComponents count] > 0 )
	{
		NSString *str = [urlComponents objectAtIndex:([urlComponents count]-1)];
		self.title = [[str substringToIndex:[str rangeOfString:@"."].location] uppercaseString];
	}
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	[m_activity startAnimating];
	self.title = @"loading...";
}


@end

/*
 File: MiniBrowserController.h
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

#import <UIKit/UIKit.h>


@interface MiniBrowserController : UIViewController <UIWebViewDelegate>
{
	IBOutlet UIToolbar *m_toolBar;
	IBOutlet UIWebView *m_webView;
	IBOutlet UIBarButtonItem *m_backButton;
	IBOutlet UIBarButtonItem *m_reloadButton;
	IBOutlet UIBarButtonItem *m_fwdButton;
	
	BOOL m_shouldStopLoadingOnHide;
	BOOL m_shouldUseParentsView;
@private
	BOOL m_loadingInterrupted;
	NSURLRequest *m_urlRequestToLoad;
	
	UIActivityIndicatorView *m_activity;
	UILabel                 *m_loadingLabel;
	
	NSArray *m_normalItemList;
	NSArray *m_loadingItemList;
	
	BOOL m_shouldDisplayOnViewLoad;
	id m_parentCtrl;
	SEL m_authCallback;
}

@property (nonatomic,retain) IBOutlet UIToolbar *m_toolBar;
@property (nonatomic,retain) IBOutlet UIWebView *m_webView;
@property (nonatomic) BOOL m_shouldUseParentsView;
@property (nonatomic) BOOL m_shouldStopLoadingOnHide;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *m_backButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *m_reloadButton;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *m_fwdButton;

+ (MiniBrowserController *)sharedBrowser;
+ (MiniBrowserController *)sharedBrowserWithURL:(NSURL *)urlOrNil;

- (void)display:(id)parentController;

- (IBAction)closeButtonPressed:(id)button;
- (IBAction)backButtonPressed:(id)button;
- (IBAction)fwdButtonPressed:(id)button;
- (IBAction)refreshButtonPressed:(id)button;
- (IBAction)openInSafariPressed:(id)button;

- (void)loadURL:(NSURL *)url;
- (void)LoadRequest:(NSURLRequest *)urlRequest;
- (void)stopLoading;

- (void)setAuthCallback:(SEL)callback;
- (void)authCompleteCallback;

@end

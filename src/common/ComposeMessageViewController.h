/*
 File: ComposeMessageViewController.h
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
#import "MyGovLoginViewController.h"
#import "ProgressOverlayViewController.h"
#import "TwitterLoginViewController.h"


typedef enum
{
	eMT_Invalid = 0,
	eMT_SendTwitterDM,
	eMT_SendTweet,
	eMT_Email,
	eMT_MyGov,
	eMT_MyGovUserComment,
	eMT_PhoneCall,
} MessageTransport;

@interface MessageData : NSObject
{
@private
	MessageTransport m_transport;
	NSString *m_to;
	NSString *m_subject;
	NSString *m_body;
	
	NSURL    *m_appURL;
	NSString *m_appURLTitle;
	NSURL    *m_webURL;
	NSString *m_webURLTitle;
	
	// equivalent to the 'm_id' of the CommunityItem that 
	// this message is associated with (perhaps in reply)
	NSString *m_communityThreadID; 
	
	// associated image
	UIImage  *m_image;
}

@property (nonatomic) MessageTransport m_transport;
@property (nonatomic,retain) NSString *m_to;
@property (nonatomic,retain) NSString *m_subject;
@property (nonatomic,retain) NSString *m_body;
@property (nonatomic,retain) NSURL    *m_appURL;
@property (nonatomic,retain) NSString *m_appURLTitle;
@property (nonatomic,retain) NSURL    *m_webURL;
@property (nonatomic,retain) NSString *m_webURLTitle;
@property (nonatomic,retain) NSString *m_communityThreadID;
@property (nonatomic,retain) UIImage  *m_image;

@end


@interface ComposeMessageView : UIView
{
	id m_parentController;
}
@property (nonatomic,retain) id m_parentController;
@end


@interface ComposeMessageViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate>
{
	IBOutlet ComposeMessageView *m_msgView;
	
	IBOutlet UIBarButtonItem *m_titleButton;
	IBOutlet UILabel         *m_labelTo;
	IBOutlet UITextField     *m_fieldTo;
	IBOutlet UILabel         *m_labelSubject;
	IBOutlet UITextField     *m_fieldSubject;
	
	IBOutlet UILabel         *m_labelMessage;
	IBOutlet UITextView      *m_fieldMessage;
	IBOutlet UIButton        *m_buttonMessage;
	
	IBOutlet UIButton        *m_infoButton;
	
	IBOutlet UILabel         *m_labelURL;
	IBOutlet UITextField     *m_fieldURL;
	IBOutlet UILabel         *m_labelURLTitle;
	IBOutlet UITextField     *m_fieldURLTitle;
	
@private
	MessageData *m_message;
	TwitterLoginViewController *m_twitterLoginView;
	MyGovLoginViewController   *m_mygovLoginView;
	ProgressOverlayViewController *m_hud;
	
	int m_alertType;
	
	id   m_activeTextField;
	BOOL m_keyboardVisible;
	BOOL m_shouldRespondToKbdEvents;
	id m_parentCtrl;
}

@property (nonatomic,retain) IBOutlet ComposeMessageView *m_msgView;
@property (nonatomic,retain) IBOutlet UIBarButtonItem *m_titleButton;
@property (nonatomic,retain) IBOutlet UILabel         *m_labelTo;
@property (nonatomic,retain) IBOutlet UITextField     *m_fieldTo;
@property (nonatomic,retain) IBOutlet UILabel         *m_labelSubject;
@property (nonatomic,retain) IBOutlet UITextField     *m_fieldSubject;
@property (nonatomic,retain) IBOutlet UILabel         *m_labelMessage;
@property (nonatomic,retain) IBOutlet UITextView      *m_fieldMessage;
@property (nonatomic,retain) IBOutlet UIButton        *m_buttonMessage;
@property (nonatomic,retain) IBOutlet UIButton        *m_infoButton;
@property (nonatomic,retain) IBOutlet UITextField     *m_fieldURL;
@property (nonatomic,retain) IBOutlet UILabel         *m_labelURL;
@property (nonatomic,retain) IBOutlet UITextField     *m_fieldURLTitle;
@property (nonatomic,retain) IBOutlet UILabel         *m_labelURLTitle;


+ (ComposeMessageViewController *)sharedComposer;

- (void)display:(MessageData *)data fromParent:(id)parentController;

- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)sendButtonPressed:(id)sender;
- (IBAction)infoButtonPressed:(id)sender;

@end

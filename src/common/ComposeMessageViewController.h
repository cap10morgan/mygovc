//
//  ComposeMessageViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ProgressOverlayViewController.h"
#import "TwitterLoginViewController.h"

typedef enum
{
	eMT_Invalid = 0,
	eMT_Twitter,
	eMT_Email,
	eMT_MyGov,
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


@interface ComposeMessageViewController : UIViewController <UITextFieldDelegate, UITextViewDelegate, UIAlertViewDelegate>
{
	IBOutlet UIBarButtonItem *m_titleButton;
	IBOutlet UITextField     *m_fieldTo;
	IBOutlet UILabel         *m_labelSubject;
	IBOutlet UITextField     *m_fieldSubject;
	IBOutlet UITextView      *m_fieldMessage;
	IBOutlet UIButton        *m_infoButton;
@private
	MessageData *m_message;
	TwitterLoginViewController *m_twitterLoginView;
	ProgressOverlayViewController *m_hud;
	
	id m_parentCtrl;
}

@property (nonatomic,retain) IBOutlet UIBarButtonItem *m_titleButton;
@property (nonatomic,retain) IBOutlet UITextField     *m_fieldTo;
@property (nonatomic,retain) IBOutlet UILabel         *m_labelSubject;
@property (nonatomic,retain) IBOutlet UITextField     *m_fieldSubject;
@property (nonatomic,retain) IBOutlet UITextView      *m_fieldMessage;
@property (nonatomic,retain) IBOutlet UIButton        *m_infoButton;

+ (ComposeMessageViewController *)sharedComposer;

- (void)display:(MessageData *)data fromParent:(id)parentController;

- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)sendButtonPressed:(id)sender;
- (IBAction)infoButtonPressed:(id)sender;

@end

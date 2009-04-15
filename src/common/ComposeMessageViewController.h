//
//  ComposeMessageViewController.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

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
}

@property (nonatomic) MessageTransport m_transport;
@property (nonatomic,retain) NSString *m_to;
@property (nonatomic,retain) NSString *m_subject;
@property (nonatomic,retain) NSString *m_body;

@end


@interface ComposeMessageViewController : UIViewController <UITextViewDelegate>
{
	IBOutlet UIBarButtonItem *m_titleButton;
	IBOutlet UITextField *m_fieldTo;
	IBOutlet UILabel *m_labelSubject;
	IBOutlet UITextField *m_fieldSubject;
	IBOutlet UITextView  *m_fieldMessage;
@private
	MessageData *m_message;
	
	id m_parentCtrl;
}

@property (nonatomic,retain) IBOutlet UIBarButtonItem *m_titleButton;
@property (nonatomic,retain) IBOutlet UITextField *m_fieldTo;
@property (nonatomic,retain) IBOutlet UILabel *m_labelSubject;
@property (nonatomic,retain) IBOutlet UITextField *m_fieldSubject;
@property (nonatomic,retain) IBOutlet UITextView  *m_fieldMessage;

+ (ComposeMessageViewController *)sharedComposer;

- (void)display:(MessageData *)data fromParent:(id)parentController;

- (IBAction)cancelButtonPressed:(id)sender;
- (IBAction)sendButtonPressed:(id)sender;

@end

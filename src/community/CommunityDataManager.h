//
//  CommunityDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CommunityDataManager : NSObject 
{
@private
	BOOL isDataAvailable;
	BOOL isBusy;
	
	NSMutableString *m_currentStatusMessage;
	id m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

+ (NSString *)dataCachePath;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (NSString *)currentStatusMessage;


@end

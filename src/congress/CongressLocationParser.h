//
//  CongressLocationParser.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CongressDataManager;

@interface CongressLocationParser : NSObject 
{
@private
	CongressDataManager *m_data;
	
	BOOL m_parsingResponse;
	BOOL m_storingCharacters;
	NSMutableString *m_currentString;
	
	NSString   *m_currentState;
	NSUInteger  m_currentDistrict;
	
	id m_notifyTarget;
	SEL m_notifySelector;
}

- (id)initWithCongressData:(CongressDataManager *)data;

- (void)setNotifyTarget:(id)target andSelector:(SEL)sel;

@end

//
//  CongressDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLParserOperation.h"

@class LegislatorContainer;

@interface CongressDataManager : NSObject <XMLParserOperationDelegate>
{
	BOOL isDataAvailable;
	
@private
	BOOL parsingLegislator;
	BOOL storingCharacters;
	NSMutableString *m_currentString;
	LegislatorContainer *m_currentLegislator;
	
	NSMutableArray *m_states;
	NSMutableDictionary *m_house;
	NSMutableDictionary *m_senate;
	
	id m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (NSArray *)states;
- (NSArray *)houseMembersInState:(NSString *)state;
- (NSArray *)senateMembersInState:(NSString *)state;

@end

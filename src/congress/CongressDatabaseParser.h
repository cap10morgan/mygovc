//
//  CongressDatabaseParser.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CongressDataManager;
@class LegislatorContainer;

@interface CongressDatabaseParser : NSObject 
{
@private
	CongressDataManager *m_data;
	
	BOOL m_parsingLegislator;
	BOOL m_storingCharacters;
	NSMutableString *m_currentString;
	LegislatorContainer *m_currentLegislator;
	
	id m_notifyTarget;
	SEL m_notifySelector;
}

- (id)initWithCongressData:(CongressDataManager *)data;

- (void)setNotifyTarget:(id)target andSelector:(SEL)sel;

@end

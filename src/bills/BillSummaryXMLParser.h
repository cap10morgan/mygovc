//
//  BillSummaryXMLParser.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class BillsDataManager;
@class BillContainer;
@class BillAction;

@interface BillSummaryXMLParser : NSObject 
{
@private
	BillsDataManager *m_data;
	
	BOOL m_parsingResponse;
	BOOL m_parsingBill;
	BOOL m_parsingActionList;
	BOOL m_parsingAction;
	BOOL m_parsingCoSponsorList;
	BOOL m_parsingCoSponsor;
	BOOL m_parsingSponsor;
	
	BOOL m_storingCharacters;
	NSMutableString *m_currentString;
	
	BillContainer *m_currentBill;
	BillAction *m_currentAction;
	
	id m_notifyTarget;
	SEL m_notifySelector;
}

- (id)initWithBillsData:(BillsDataManager *)data;

- (void)setNotifyTarget:(id)target andSelector:(SEL)sel;

@end

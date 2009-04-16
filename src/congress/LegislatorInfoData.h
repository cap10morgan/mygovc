//
//  LegislatorInfoData.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLParserOperation.h"

@class LegislatorContainer;
@class LegislatorInfoCell;
@class SectionRowData;

@interface LegislatorInfoData : NSObject <XMLParserOperationDelegate>
{
@private
	id m_notifyTarget;
	SEL m_notifySelector;
	
	LegislatorContainer *m_legislator;
	
	NSMutableArray *m_data; // Array of Arrays of single-object-dictionaries (fieldname -> value pairs)
	
	BOOL m_activityDownloaded;
	NSMutableArray *m_activityData;
	
	id m_actionParent;
	
	BOOL m_parsingResponse;
	BOOL m_storingCharacters;
	NSMutableString *m_currentString;
	NSString *m_currentTitle;
	NSString *m_currentExcerpt;
	NSString *m_currentSource;
	SectionRowData *m_currentRowData;
	XMLParserOperation *m_xmlParser;
}


- (void)setNotifyTarget:(id)target andSelector:(SEL)sel;

- (void)setLegislator:(LegislatorContainer *)legislator;

- (NSInteger)numberOfSections;

- (NSString *)titleForSection:(NSInteger)section;

- (NSInteger)numberOfRowsInSection:(NSInteger)section;

- (CGFloat)heightForDataAtIndexPath:(NSIndexPath *)indexPath;

- (void)setInfoCell:(LegislatorInfoCell *)cell forIndex:(NSIndexPath *)indexPath;

- (void)performActionForIndex:(NSIndexPath *)indexPath withParent:(id)parent;

@end

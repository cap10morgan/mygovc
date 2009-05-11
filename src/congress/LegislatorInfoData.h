/*
 File: LegislatorInfoData.h
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

#import <Foundation/Foundation.h>
#import "XMLParserOperation.h"
#import "TableDataManager.h"

@class LegislatorContainer;
//@class LegislatorInfoCell;
//@class SectionRowData;

@interface LegislatorInfoData : TableDataManager <XMLParserOperationDelegate>
{
	LegislatorContainer *m_legislator;
	
	BOOL m_activityDownloaded;
	NSMutableArray *m_activityData;
	
	BOOL m_parsingResponse;
	BOOL m_storingCharacters;
	NSMutableString *m_currentString;
	NSString *m_currentTitle;
	NSString *m_currentExcerpt;
	NSString *m_currentSource;
	TableRowData *m_currentRowData;
	XMLParserOperation *m_xmlParser;
}

- (void)setLegislator:(LegislatorContainer *)legislator;

- (void)stopAnyWebActivity;

/*
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

- (void)stopAnyWebActivity;
*/

@end

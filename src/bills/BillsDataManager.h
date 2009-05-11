/*
 File: BillsDataManager.h
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

@class BillContainer;

@interface BillsDataManager : NSObject <XMLParserOperationDelegate>
{
@private
	BOOL isDataAvailable;
	BOOL isBusy;
	BOOL isDownloading;
	BOOL isReadingCache;
	
	NSMutableDictionary *m_billData; // all bill data: key = billIdent (TypeStr Number)
	
	NSMutableArray *m_houseSections; // array of 'm_houseBills' key values for easy sorting
	NSMutableDictionary *m_houseBills; // key=((year << 5) + month), Value=array of bill containers
	
	NSMutableArray *m_senateSections;
	NSMutableDictionary *m_senateBills;
	
	NSInteger  m_billsDownloaded;
	NSInteger  m_billDownloadPage;
	
	BOOL            m_searching;
	NSMutableArray *m_searchResults;
	NSString *m_currentSearchString;
	
	XMLParserOperation *m_xmlParser;
	NSTimer *m_timer;
	
	NSMutableString *m_currentStatusMessage;
	
	id m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

+ (NSString *)dataCachePath;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (NSString *)currentStatusMessage;

- (void)loadData;
- (void)loadDataByDownload;

- (NSInteger)totalBills;
- (BillContainer *)billWithIdentifier:(NSString *)billIdent;

- (NSInteger)houseBills;
- (NSInteger)houseBillSections;
- (NSInteger)houseBillsInSection:(NSInteger)section;
- (NSString *)houseSectionTitle:(NSInteger)section;
- (BillContainer *)houseBillAtIndexPath:(NSIndexPath *)indexPath;

- (NSInteger)senateBills;
- (NSInteger)senateBillSections;
- (NSInteger)senateBillsInSection:(NSInteger)section;
- (NSString *)senateSectionTitle:(NSInteger)section;
- (BillContainer *)senateBillAtIndexPath:(NSIndexPath *)indexPath;

- (void)searchForBillsLike:(NSString *)searchText;
- (NSString *)currentSearchString;
- (NSInteger)numSearchResults;
- (BillContainer *)searchResultAtIndexPath:(NSIndexPath *)indexPath;

@end

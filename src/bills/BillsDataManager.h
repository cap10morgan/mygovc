//
//  BillsDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLParserOperation.h"

@class BillContainer;

@interface BillsDataManager : NSObject <XMLParserOperationDelegate>
{
@private
	BOOL isDataAvailable;
	BOOL isBusy;
	
	NSMutableArray *m_billData; // all bill data (sorted by last action date)
	
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

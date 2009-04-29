//
//  CommunityDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/26/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CommunityDataSource.h"
#import "CommunityItem.h"


@interface CommunityDataManager : NSObject <CommunityDataSourceDelegate>
{
@private
	BOOL isDataAvailable;
	BOOL isBusy;
	
	id<CommunityDataSourceProtocol> m_dataSource;
	MyGovUserData *m_userData;
	
	NSDate *m_inMemoryStartDate;
	NSDate *m_inMemoryEndData;
	NSMutableArray *m_feedbackData; // array of CommunityItems of type eCommunity_Feedback
	NSMutableArray *m_eventData; // array of CommunityItems of type eCommunity_Event
	NSMutableArray *m_searchData; // array of CommunityItems that resulted from the last search operation
	
	NSMutableString *m_currentStatusMessage;
	id m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

+ (NSString *)dataCachePath;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (void)setDataSource:(id<CommunityDataSourceProtocol>)source;

- (id<CommunityDataSourceProtocol>)dataSource;

- (NSString *)currentStatusMessage;

// starts a possible data cache load, plus new data download
- (void)loadData;

// drop items from cache which are too old (defined in a user preference)
- (void)purgeOldItemsFromCache:(BOOL)blocking;

// Table data methods
- (NSInteger)numberOfSectionsForType:(CommunityItemType)type;
- (NSString *)sectionName:(NSInteger)section forType:(CommunityItemType)type;
- (NSInteger)numberOfRowsInSection:(NSInteger)section forType:(CommunityItemType)type;
- (CGFloat)heightForDataAtIndexPath:(NSIndexPath *)indexPath forType:(CommunityItemType)type;
- (CommunityItem *)itemForIndexPath:(NSIndexPath *)indexPath andType:(CommunityItemType)type;


@end

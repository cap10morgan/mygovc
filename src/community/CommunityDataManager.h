/*
 File: CommunityDataManager.h
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
#import "CommunityDataSource.h"
#import "CommunityItem.h"


@interface CommunityDataManager : NSObject <CommunityDataSourceDelegate>
{
@private
	BOOL isDataAvailable;
	BOOL isBusy;
	
	id<CommunityDataSourceProtocol> m_dataSource;
	MyGovUserData *m_userData;
	NSString *m_currentUserUID;
	
	NSDate *m_inMemoryStartDate;
	NSDate *m_inMemoryEndData;
	
	NSMutableArray *m_chatterData; // array of CommunityItems of type eCommunity_Chatter
	NSMutableDictionary *m_chatterIDDict; // same set of CommunityItem data, different index :-)
	
	NSMutableArray *m_eventData; // array of CommunityItems of type eCommunity_Event
	NSMutableDictionary *m_eventIDDict;
	
	NSMutableArray *m_searchData; // array of CommunityItems that resulted from the last search operation
	
	NSDate *m_latestItemDate;
	
	NSTimer *m_timer;
	NSMutableString *m_currentStatusMessage;
	id m_notifyTarget;
	SEL m_notifySelector;
	
	NSInteger m_numNewItems;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;
@property (retain) NSDate *m_latestItemDate;
@property NSInteger m_numNewItems;


+ (NSString *)dataCachePath;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (void)setDataSource:(id<CommunityDataSourceProtocol>)source;

- (id<CommunityDataSourceProtocol>)dataSource;

- (NSString *)currentStatusMessage;

- (NSString *)currentlyAuthenticatedUser;

- (NSURLRequest *)dataSourceLoginURLRequest;

// starts a possible data cache load, plus new data download
- (void)loadData;

// drop items from cache which are too old (defined in a user preference)
- (void)purgeOldItemsFromCache:(BOOL)blocking;

// completely drop all current data... (used for re-load)
- (void)purgeAllItemsFromCacheAndMemory;

// grab community items 
- (CommunityItem *)itemWithId:(NSString *)itemID;


// Table data methods
- (NSInteger)numberOfSectionsForType:(CommunityItemType)type;
- (NSString *)sectionName:(NSInteger)section forType:(CommunityItemType)type;
- (NSInteger)numberOfRowsInSection:(NSInteger)section forType:(CommunityItemType)type;
- (CGFloat)heightForDataAtIndexPath:(NSIndexPath *)indexPath forType:(CommunityItemType)type;
- (CommunityItem *)itemForIndexPath:(NSIndexPath *)indexPath andType:(CommunityItemType)type;

// be careful with this one!
- (void)removeCommunityItem:(CommunityItem *)item;

@end

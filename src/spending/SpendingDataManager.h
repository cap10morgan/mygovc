/*
 File: SpendingDataManager.h
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
#import "DataProviders.h"

@class PlaceSpendingData;
@class ContractorSpendingData;
@class ContractorInfo;
@class ContractorSpendingData;


@interface SpendingDataManager : NSObject 
{
	BOOL isDataAvailable;
	BOOL isBusy;
	
@private
	NSMutableDictionary *m_districtSpendingSummary;
	NSMutableDictionary *m_stateSpendingSummary;
	ContractorSpendingData *m_contractorSpendingSummary;
	
	NSOperationQueue *m_downloadOperations;
	NSTimer *m_timer;
	BOOL m_shouldStopDownloads;
	NSUInteger m_downloadsInFlight;
	
	id  m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

+ (NSString *)dataCachePath;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (void)cancelAllDownloads;
- (void)flushInMemoryCache;

- (NSArray *)congressionalDistricts; // sortedBy:(SpendingSortMethod)order;
- (NSInteger)numDistrictsInState:(NSString *)state; // sortedBy:(SpendingSortMethod)order;
- (NSArray *)topContractorsSortedBy:(SpendingSortMethod)order;


- (PlaceSpendingData *)getDistrictData:(NSString *)district andWaitForDownload:(BOOL)yesOrNo;
- (PlaceSpendingData *)getStateData:(NSString *)state andWaitForDownload:(BOOL)yesOrNo;
- (ContractorInfo *)contractorData:(NSInteger)idx whenSortedBy:(SpendingSortMethod)order;

@end

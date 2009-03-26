//
//  SpendingDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PlaceSpendingData;
@class ContractorSpendingData;
@class ContractorInfo;
@class ContractorSpendingData;

typedef enum
{
	eSpendingSortDate,
	eSpendingSortAgency,
	eSpendingSortContractor,
	eSpendingSortCategory,
	eSpendingSortDollars,
} SpendingSortMethod;


typedef enum
{
	eSpendingDetailSummary,
	eSpendingDetailLow,
	eSpendingDetailMed,
	eSpendingDetailHigh,
	eSpendingDetailComplete,
} SpendingDetail;


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
+ (NSURL *)getURLForDistrict:(NSString *)district forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order;
+ (NSURL *)getURLForState:(NSString *)state forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order;
+ (NSURL *)getURLForTopContractors:(NSInteger)year maxNumContractors:(NSInteger)maxRecords withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (void)cancelAllDownloads;

- (NSArray *)congressionalDistricts; // sortedBy:(SpendingSortMethod)order;
- (NSInteger)numDistrictsInState:(NSString *)state; // sortedBy:(SpendingSortMethod)order;
- (NSArray *)top100ContractorsSortedBy:(SpendingSortMethod)order;


- (PlaceSpendingData *)getDistrictData:(NSString *)district andWaitForDownload:(BOOL)yesOrNo;
- (PlaceSpendingData *)getStateData:(NSString *)state andWaitForDownload:(BOOL)yesOrNo;
- (ContractorInfo *)contractorData:(NSInteger)idx whenSortedBy:(SpendingSortMethod)order;

@end

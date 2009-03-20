//
//  SpendingDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DistrictSpendingData;


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
	NSMutableDictionary *m_contractorSpendingSummary;
	
	NSOperationQueue *m_downloadOperations;
	NSTimer *m_timer;
	
	id  m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

+ (NSString *)dataCachePath;
+ (NSURL *)getURLForDistrict:(NSString *)district forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order;
+ (NSURL *)getURLForState:(NSString *)state forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order;


- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (void)cancelAllDownloads;

- (NSArray *)congressionalDistricts;
- (NSInteger)numDistrictsInState:(NSString *)state;
- (DistrictSpendingData *)getDistrictData:(NSString *)district andWaitForDownload:(BOOL)yesOrNo;

// -(StateSpendingData *)getStateData:(NSString *)state andWaitForDownload:(BOOL)yesOrNo;
// -(ContractorSpendingData *)getContractorData:(NSString *)contractor andWaitForDownload:(BOOL)yesOrNo;

@end

//
//  DataProviders.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "BillContainer.h"
#import "CommunityItem.h"

@class LegislatorContainer;

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


@interface DataProviders : NSObject 
{}

+ (NSString *)OpenCongress_APIKey;
+ (NSString *)OpenCongress_BillsURLOnPage:(NSInteger)page;
+ (NSString *)OpenCongress_BillsURLIntroducedSinceDate:(NSDate *)date onPage:(NSInteger)page;
+ (NSString *)OpenCongress_PersonURL:(LegislatorContainer *)person;
+ (NSString *)OpenCongress_BillQueryURL:(NSString *)queryStr;
+ (NSInteger)OpenCongress_MaxBillsReturned;

+ (NSString *)SunlightLabs_APIKey;
+ (NSString *)SunlightLabs_LegislatorListURL;

+ (NSString *)Govtrack_DataDirURL;
+ (NSString *)Govtrack_CommitteeURL:(NSInteger)congressSession;
+ (NSString *)Govtrack_DistrictURLFromLocation:(CLLocation *)latLong;
+ (NSString *)Govtrack_FullBillTextURL:(NSInteger)number withBillType:(BillType)type;

+ (NSString *)USASpending_fpdsURL;
+ (NSString *)USASpending_districtURL:(NSString *)district 
							  forYear:(NSInteger)year 
						   withDetail:(SpendingDetail)detail 
							 sortedBy:(SpendingSortMethod)order 
							   xmlURL:(BOOL)xmldata;

+ (NSString *)USASpending_stateURL:(NSString *)state 
						   forYear:(NSInteger)year 
						withDetail:(SpendingDetail)detail 
						  sortedBy:(SpendingSortMethod)order 
							xmlURL:(BOOL)xmldata;

+ (NSString *)USASpending_topContractorURL:(NSInteger)year 
						 maxNumContractors:(NSInteger)maxRecords 
								withDetail:(SpendingDetail)detail 
								  sortedBy:(SpendingSortMethod)order 
									xmlURL:(BOOL)xmldata;

+ (NSString *)USASpending_contractorSearchURL:(NSString *)companyName 
									  forYear:(NSInteger)year 
								   withDetail:(SpendingDetail)detail 
									 sortedBy:(SpendingSortMethod)order 
									   xmlURL:(BOOL)xmldata;

+ (NSString *)Cholor_UserAuthURL;
+ (NSString *)Cholor_UserAddURL;
+ (NSString *)Cholor_UserAuthFailedStr;
+ (NSString *)Cholor_CommunityItemPOSTURL;
+ (NSString *)Cholor_CommunityCommentPOSTURL;
+ (NSString *)Cholor_CommunityItemPOSTSucess;
+ (NSString *)Cholor_DownloadURLFor:(CommunityItemType)type;


@end

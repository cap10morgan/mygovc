//
//  DataProviders.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

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
+ (NSString *)OpenCongress_BillsURL;
+ (NSString *)OpenCongress_PersonURL:(LegislatorContainer *)person;

+ (NSString *)SunlightLabs_APIKey;
+ (NSString *)SunlightLabs_LegislatorListURL;

+ (NSString *)Govtrack_DataDirURL;
+ (NSString *)Govtrack_CommitteeURL:(NSInteger)congressSession;
+ (NSString *)Govtrack_DistrictURLFromLocation:(CLLocation *)latLong;

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

@end

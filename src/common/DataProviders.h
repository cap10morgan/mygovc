/*
 File: DataProviders.h
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

+ (NSString *)postStringFromDictionary:(NSDictionary *)dict;


+ (NSString *)Bioguide_LegislatorBioURL:(LegislatorContainer *)legislator;

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


+ (NSString *)GAE_DownloadURLFor:(CommunityItemType)type;
+ (NSString *)GAE_CommunityItemPOSTURLFor:(CommunityItemType)type;
+ (NSString *)GAE_CommunityItemCommentsURLFor:(CommunityItem *)item;
+ (NSString *)GAE_CommunityReplyPOSTURLFor:(NSString *)itemID;
+ (NSString *)GAE_GoogleURLsDictKey;
+ (NSString *)GAE_GoogleLoginURLDictKey;
+ (NSString *)GAE_ItemsDictKey;
+ (NSString *)GAE_GoogleURLTitleDictKey;
+ (NSString *)GAE_GoogleLoginURLTitle;

+ (NSString *)Cholor_UserAuthURL;
+ (NSString *)Cholor_UserAddURL;
+ (NSString *)Cholor_UserLookupURL;
+ (NSString *)Cholor_UserAuthFailedStr;
+ (NSString *)Cholor_CommunityItemPOSTURL;
+ (NSString *)Cholor_CommunityCommentPOSTURL;
+ (NSString *)Cholor_CommunityItemPOSTSucess;
+ (NSString *)Cholor_DownloadURLFor:(CommunityItemType)type;


@end

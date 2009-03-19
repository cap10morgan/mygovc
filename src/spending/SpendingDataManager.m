//
//  SpendingDataManager.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"
#import "SpendingDataManager.h"
#import "DistrictSpendingData.h"

@implementation SpendingDataManager

@synthesize isDataAvailable;
@synthesize isBusy;

static NSString *kUSASpending_fpdsXML = @"http://www.usaspending.gov/fpds/fpds.php?datype=X";

static NSString *kDetailLevel_Summary = @"&detail=-1";
static NSString *kDetailLevel_Low = @"&detail=0";
static NSString *kDetailLevel_Medium = @"&detail=1";
static NSString *kDetailLevel_High = @"&detail=2";
static NSString *kDetailLevel_Complete = @"&detail=4";

static NSString *kSortByContractor = @"&sortby=r";
static NSString *kSortByDollars = @"&sortby=f";
static NSString *kSortByContractingAgency = @"&sortby=g";
static NSString *kSortByCategory = @"&sortby=p";
static NSString *kSortByDate = @"&sortby=d";

static NSString *kFiscalYearKey = @"&fiscal_year";
static NSString *kDistrictKey = @"&pop_cd2";
static NSString *kStateKey = @"&stateCode";
static NSString *kContractorKey = @"&company_name";


+ (NSString *)dataCachePath
{
	NSString *cachePath = [[myGovAppDelegate sharedAppCacheDir] stringByAppendingPathComponent:@"spending"];
	return cachePath;
}


+ (NSURL *)getURLForDistrict:(NSString *)district forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order
{
	NSString *sortStr;
	switch ( order )
	{
		case eSpendingSortDate:
			sortStr = kSortByDate;
			break;
		case eSpendingSortAgency:
			sortStr = kSortByContractingAgency;
			break;
		case eSpendingSortContractor:
			sortStr = kSortByContractor;
			break;
		case eSpendingSortCategory:
			sortStr = kSortByCategory;
			break;
		default:
		case eSpendingSortDollars:
			sortStr = kSortByDollars;
			break;
	}
	
	NSString *detailStr;
	switch ( detail )
	{
		default:
		case eSpendingDetailSummary:
			detailStr = kDetailLevel_Summary;
			break;
		case eSpendingDetailLow:
			detailStr = kDetailLevel_Low;
			break;
		case eSpendingDetailMed:
			detailStr = kDetailLevel_Medium;
			break;
		case eSpendingDetailHigh:
			detailStr = kDetailLevel_High;
			break;
		case eSpendingDetailComplete:
			detailStr = kDetailLevel_Complete;
			break;
	}
	
	NSString *urlStr = [kUSASpending_fpdsXML stringByAppendingFormat:@"%@=%@%@=%d%@%@",
												kDistrictKey,district,
												kFiscalYearKey,year,
												sortStr,
												detailStr
					   ];
	return [NSURL URLWithString:urlStr];
}


+ (NSURL *)getURLForState:(NSString *)state forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order
{
	NSString *sortStr;
	switch ( order )
	{
		case eSpendingSortDate:
			sortStr = kSortByDate;
			break;
		case eSpendingSortAgency:
			sortStr = kSortByContractingAgency;
			break;
		case eSpendingSortContractor:
			sortStr = kSortByContractor;
			break;
		case eSpendingSortCategory:
			sortStr = kSortByCategory;
			break;
		default:
		case eSpendingSortDollars:
			sortStr = kSortByDollars;
			break;
	}
	
	NSString *detailStr;
	switch ( detail )
	{
		default:
		case eSpendingDetailSummary:
			detailStr = kDetailLevel_Summary;
			break;
		case eSpendingDetailLow:
			detailStr = kDetailLevel_Low;
			break;
		case eSpendingDetailMed:
			detailStr = kDetailLevel_Medium;
			break;
		case eSpendingDetailHigh:
			detailStr = kDetailLevel_High;
			break;
		case eSpendingDetailComplete:
			detailStr = kDetailLevel_Complete;
			break;
	}
	
	NSString *urlStr = [kUSASpending_fpdsXML stringByAppendingFormat:@"%@=%@%@=%d%@%@",
												kStateKey,state,
												kFiscalYearKey,year,
												sortStr,
												detailStr
						];
	return [NSURL URLWithString:urlStr];
}



- (id)init
{
	if ( self == [super init] )
	{
		isDataAvailable = YES;
		
		DistrictSpendingData *dsd = [[DistrictSpendingData alloc] initWithDistrict:@"MI02"];
		[dsd downloadDataWithCallback:nil onObject:nil];
	}
	return self;
}


@end


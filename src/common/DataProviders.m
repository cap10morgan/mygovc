//
//  DataProviders.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
#import "myGovAppDelegate.h"
#import "DataProviders.h"
#import "CongressDataManager.h"
#import "LegislatorContainer.h"


@implementation DataProviders

// 
// API Keys
// 
static NSString *kOpenCongress_APIKey = @"32aea132a66093e9bf9ebe9fc2e2a4c66b888777";
static NSString *kSunlight_APIKey = @"345973d49743956706bb04030ee5713b";
//static NSString *kPVS_APIKey = @"e9c18da5999464958518614cfa7c6e1c";


// 
// OpenCongress.org 
// 
static NSString *kOpenCongress_BillsXMLFmt = @"http://www.opencongress.org/api/bills?key=%@&congress=%d";
static NSString *kOpenCongress_PersonXMLFmt = @"http://www.opencongress.org/api/people?key=%@&state=%@&first_name=%@&last_name=%@";

// 
// SunlightLabs 
// 
static NSString *kSunlight_getListXML = @"http://services.sunlightlabs.com/api/legislators.getList.xml";

// 
// govtrack.us
// 
static NSString *kGovtrack_dataDir = @"http://www.govtrack.us/data/us/";
static NSString *kGovtrack_committeeListXMLFmt = @"http://www.govtrack.us/data/us/%d/committees.xml";
static NSString *kGovtrack_latLongFmt = @"http://www.govtrack.us/perl/district-lookup.cgi?lat=%f&long=%f";

// 
// USASpending.gov
// 
static NSString *kUSASpending_fpdsURL = @"http://www.usaspending.gov/fpds/fpds.php?database=fpds&reptype=r&datype=X";

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
static NSString *kMaxRecordsKey = @"&max_records";
static NSString *kContractorKey = @"&company_name";



+ (NSString *)OpenCongress_APIKey
{
	return kOpenCongress_APIKey;
}


+ (NSString *)OpenCongress_BillsURL
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:kOpenCongress_BillsXMLFmt,
											kOpenCongress_APIKey,
											[[myGovAppDelegate sharedCongressData] currentCongressSession]
						] autorelease];
	return urlStr;
}


+ (NSString *)OpenCongress_PersonURL:(LegislatorContainer *)person
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:kOpenCongress_PersonXMLFmt,
											kOpenCongress_APIKey,
											[person state],
											[person firstname],
											[person lastname]
						 ] autorelease];
	return urlStr;
}


+ (NSString *)SunlightLabs_APIKey
{
	return kSunlight_APIKey;
}


+ (NSString *)SunlightLabs_LegislatorListURL
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:@"%@?apikey=%@",
											kSunlight_getListXML,
											kSunlight_APIKey
						] autorelease];
	return urlStr;
}


+ (NSString *)Govtrack_DataDirURL
{
	return kGovtrack_dataDir;
}


+ (NSString *)Govtrack_CommitteeURL:(NSInteger)congressSession
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:kGovtrack_committeeListXMLFmt,
											congressSession
						] autorelease];
	return urlStr;
}


+ (NSString *)Govtrack_DistrictURLFromLocation:(CLLocation *)latLong
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:kGovtrack_latLongFmt,
											latLong.coordinate.latitude,
											latLong.coordinate.longitude
						] autorelease];
	return urlStr;
}

+ (NSString *)USASpending_fpdsURL
{
	return kUSASpending_fpdsURL;
}


+ (NSString *)USASpending_districtURL:(NSString *)district forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order
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
	
	NSMutableString *urlStr = [[[NSMutableString alloc] initWithString:kUSASpending_fpdsURL] autorelease];
	[urlStr appendFormat:@"%@=%@%@=%0d%@%@",
							kDistrictKey,district,
							kFiscalYearKey,year,
							sortStr,
							detailStr
	];
	return (NSString *)urlStr;
}


+ (NSString *)USASpending_stateURL:(NSString *)state forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order
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
	
	NSMutableString *urlStr = [[[NSMutableString alloc] initWithString:kUSASpending_fpdsURL] autorelease];
	[urlStr appendFormat:@"%@=%@%@=%0d%@%@",
							kStateKey,state,
							kFiscalYearKey,year,
							sortStr,
							detailStr
	];
	return (NSString *)urlStr;
}


+ (NSString *)USASpending_topContractorURL:(NSInteger)year maxNumContractors:(NSInteger)maxRecords withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order
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
	
	NSMutableString *urlStr = [[[NSMutableString alloc] initWithString:kUSASpending_fpdsURL] autorelease];
	[urlStr appendFormat:@"%@=%0d%@=%0d%@%@",
							kMaxRecordsKey,maxRecords,
							kFiscalYearKey,year,
							detailStr,
							sortStr
	];
	return (NSString *)urlStr;
}


@end

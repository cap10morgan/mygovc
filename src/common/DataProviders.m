/*
 File: DataProviders.m
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

#import "myGovAppDelegate.h"
#import "BillContainer.h"
#import "CongressDataManager.h"
#import "DataProviders.h"
#import "LegislatorContainer.h"

@implementation DataProviders

// 
// API Keys
// 
static NSString *kOpenCongress_APIKey = @"32aea132a66093e9bf9ebe9fc2e2a4c66b888777";
static NSString *kSunlight_APIKey = @"345973d49743956706bb04030ee5713b";
//static NSString *kPVS_APIKey = @"e9c18da5999464958518614cfa7c6e1c";


// 
// Bioguide
// 
static NSString *kBioguideURLFmt = @"http://bioguide.congress.gov/scripts/biodisplay.pl?index=%@";


// 
// OpenCongress.org 
// 
static NSString *kOpenCongress_BillsXMLFmt = @"http://www.opencongress.org/api/bills?key=%@&congress=%d&per_page=15&page=%d";
static NSString *kOpenCongress_BillsSinceFmt = @"http://www.opencongress.org/api/bills_introduced_since?key=%@&per_page=15&page=%d&date=%@";
static NSString *kOpenCongress_PersonXMLFmt = @"http://www.opencongress.org/api/people?key=%@&state=%@&first_name=%@&last_name=%@";
static NSString *kOpenCongress_BillQueryFmt = @"http://www.opencongress.org/api/bills_by_query?key=%@&congress=%d&q=%@"; 
static NSInteger kOpenCongress_MaxBillsReturnedPerQuery = 15;

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
static NSString *kGovtrackBillTextURL_fmt = @"http://www.govtrack.us/data/us/bills.text/%d/%@/%@%d.html";
static NSString *kGovtrackDistrictMapURL_fmt = @"http://www.govtrack.us/congress/findyourreps.xpd?state=%@&district=%d";

// 
// USASpending.gov
// 
static NSString *kUSASpending_fpdsURL = @"http://www.usaspending.gov/fpds/fpds.php?database=fpds&reptype=r";

static NSString *kUSASpending_DataTypeXML = @"&datype=X";
static NSString *kUSASpending_DataTypeHTML = @"&datype=T";

static NSString *kUSASpending_DetailLevel_Summary = @"&detail=-1";
static NSString *kUSASpending_DetailLevel_Low = @"&detail=0";
static NSString *kUSASpending_DetailLevel_Medium = @"&detail=1";
static NSString *kUSASpending_DetailLevel_High = @"&detail=2";
static NSString *kUSASpending_DetailLevel_Complete = @"&detail=4";

static NSString *kUSASpending_SortByContractor = @"&sortby=r";
static NSString *kUSASpending_SortByDollars = @"&sortby=f";
static NSString *kUSASpending_SortByContractingAgency = @"&sortby=g";
static NSString *kUSASpending_SortByCategory = @"&sortby=p";
static NSString *kUSASpending_SortByDate = @"&sortby=d";

static NSString *kUSASpending_FiscalYearKey = @"&fiscal_year";
static NSString *kUSASpending_DistrictKey = @"&pop_cd2";
static NSString *kUSASpending_StateKey = @"&stateCode";
static NSString *kUSASpending_MaxRecordsKey = @"&max_records";
static NSString *kUSASpending_ContractorKey = @"&company_name";

static NSString *kUSASpending_SearchAppendKey = @"&mustrn=y";

// 
// GAE 
// 
static NSString *kGAE_downloadCommunityChatterURL = @"http://mygov-mobile.appspot.com/community/items.plist";
static NSString *kGAE_downloadCommunityEventsURL = @"http://mygov-mobile.appspot.com/community/events.plist";
static NSString *kGAE_postCommunityChatterURL = @"http://mygov-mobile.appspot.com/community/item/";
static NSString *kGAE_postCommunityEventsURL = @"http://mygov-mobile.appspot.com/community/events/";
static NSString *kGAE_downloadCommentsURL = @"http://mygov-mobile.appspot.com/community/item/%@/comments.plist";
static NSString *kGAE_postCommunityCommentURL = @"http://mygov-mobile.appspot.com/community/item/%@/comment";

static NSString *kGAE_GoogleURLsDictKey = @"google_urls";
static NSString *kGAE_GoogleLoginURLDictKey = @"url";
static NSString *kGAE_ItemsDictKey = @"items";
static NSString *kGAE_GoogleURLTitleDictKey = @"url_linktext";
static NSString *kGAE_GoogleLoginURLTitle = @"Login";

// 
// Cholor - cbell's PHP implementation of mygov server functionality :-)
// 
static NSString *kCholor_UserAuthURL = @"http://cholor.com/mygov/login.php";
static NSString *kCholor_UserAddURL = @"http://cholor.com/mygov/addUser.php";
static NSString *kCholor_UserLookupURL = @"http://cholor.com/mygov/userLookup.php";
static NSString *kCholor_CommunityItemPostURL = @"http://cholor.com/mygov/community.php";
static NSString *kCholor_CommunityCommentPostURL = @"http://cholor.com/mygov/comments.php";
static NSString *kCholor_CommunityItemPOSTSuccess = @"Posted";
static NSString *kCholor_UserAuthFailedStr = @"Failure";

static NSString *kCholor_downloadCommunityChatterURL = @"http://cholor.com/mygov/communityChatter.php";
static NSString *kCholor_downloadCommunityEventsURL = @"http://cholor.com/mygov/communityEvents.php";



+ (NSString *)postStringFromDictionary:(NSDictionary *)dict
{
	NSMutableString *postStr = [[[NSMutableString alloc] init] autorelease];
	
	NSEnumerator *keyEnum = [dict keyEnumerator];
	NSString *key;
	while ( key = [keyEnum nextObject] )
	{
		id obj = [dict objectForKey:key];
		NSString *valStr = nil;
		
		// NSString objects
		if ( [obj isKindOfClass:[NSString class]] )
		{
			valStr = (NSString *)obj;
		}
		// NSNumber objects
		else if ( [obj isKindOfClass:[NSNumber class]] )
		{
			valStr = [obj stringValue];
		}
		else if ( [obj isKindOfClass:[NSArray class]] )
		{
			// compile the array string
			if ( [obj count] > 0 )
			{
				NSMutableString *arrayStr = [[[NSMutableString alloc] init] autorelease];
				NSString *arrayAmp = @"";
				NSEnumerator *arrayEnum = [obj objectEnumerator];
				id arrayObj;
				while ( arrayObj = [arrayEnum nextObject] )
				{
					if ( [arrayObj isKindOfClass:[NSNumber class]] )
					{
						[arrayStr appendFormat:@"%@%@[]=%@",arrayAmp, key, [arrayObj stringValue]];
						arrayAmp = @"&"; // empty the first time through - set to ampersand when we need it!
					}
					else if ( [arrayObj isKindOfClass:[NSString class]] )
					{
						NSString *str = [arrayObj stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
						[arrayStr appendFormat:@"%@%@[]=%@", arrayAmp, key, str];
						arrayAmp = @"&"; // empty the first time through - set to ampersand when we need it!
					}
					//  - ignore this element: no nested arrays/dictionaries
				}
				
				if ( [arrayStr length] > 0 )
				{
					// XXX - do I need to [retain] this?!
					valStr = arrayStr;
					key = @""; // mash!
				}
			}
		}
		else
		{
			// no NSDictionary support!
			NSLog( @"Ignoring unsupported PList object '%@' in dictionary...", key );
		}
		
		if ( nil != valStr )
		{
			NSString *amp = @"";
			if ( 0 != [postStr length] )
			{
				amp = @"&";
			}
			if ( [key length] > 0 )
			{
				valStr = [valStr stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"];
				[postStr appendFormat:@"%@%@=%@", amp, key, valStr];
			}
			else
			{
				// just use the 'valStr' for arrays :-)
				[postStr appendString:valStr];
			}
		}
	}
	
	return postStr; //[postStr stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding];
}


+ (NSString *)Bioguide_LegislatorBioURL:(LegislatorContainer *)legislator
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:kBioguideURLFmt,
											[legislator bioguide_id]
						 ] autorelease];
	return urlStr;
}


+ (NSString *)OpenCongress_APIKey
{
	return kOpenCongress_APIKey;
}


+ (NSString *)OpenCongress_BillsURLOnPage:(NSInteger)page
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:kOpenCongress_BillsXMLFmt,
											kOpenCongress_APIKey,
											[[myGovAppDelegate sharedCongressData] currentCongressSession],
											page
						] autorelease];
	return urlStr;
}


+ (NSString *)OpenCongress_BillsURLIntroducedSinceDate:(NSDate *)date onPage:(NSInteger)page
{
	NSDateFormatter *dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	[dateFormatter setTimeStyle:NSDateFormatterNoStyle];
	
	NSString *formattedDateString = [[dateFormatter stringFromDate:date] stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding];
	
	NSString *urlStr = [[[NSString alloc] initWithFormat:kOpenCongress_BillsSinceFmt,
											kOpenCongress_APIKey,
											page,
											formattedDateString
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


+ (NSString *)OpenCongress_BillQueryURL:(NSString *)queryStr
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:kOpenCongress_BillQueryFmt,
											kOpenCongress_APIKey,
											[[myGovAppDelegate sharedCongressData] currentCongressSession],
											[queryStr stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding]
						] autorelease];
	return urlStr;
}


+ (NSInteger)OpenCongress_MaxBillsReturned
{
	return kOpenCongress_MaxBillsReturnedPerQuery;
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


+ (NSString *)Govtrack_FullBillTextURL:(NSInteger)number withBillType:(BillType)type
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:kGovtrackBillTextURL_fmt,
											[[myGovAppDelegate sharedCongressData] currentCongressSession],
											[BillContainer stringFromBillType:type],
											[BillContainer stringFromBillType:type],
											number,
											@"" // XXX - "ih", "eh" "ih.gen", "rfs", etc.
						] autorelease];
	return urlStr;
}


+ (NSString *)Govtrack_DistrictMapURL:(NSString *)stateAbbr forDistrict:(NSInteger)district
{
	NSString *urlStr = [[[NSString alloc] initWithFormat:kGovtrackDistrictMapURL_fmt, 
											stateAbbr, 
											district
						] autorelease];
	return urlStr;
}


+ (NSString *)USASpending_fpdsURL
{
	return kUSASpending_fpdsURL;
}


+ (NSString *)USASpending_districtURL:(NSString *)district 
							  forYear:(NSInteger)year 
						   withDetail:(SpendingDetail)detail 
							 sortedBy:(SpendingSortMethod)order 
							   xmlURL:(BOOL)xmldata
{
	NSString *sortStr;
	switch ( order )
	{
		case eSpendingSortDate:
			sortStr = kUSASpending_SortByDate;
			break;
		case eSpendingSortAgency:
			sortStr = kUSASpending_SortByContractingAgency;
			break;
		case eSpendingSortContractor:
			sortStr = kUSASpending_SortByContractor;
			break;
		case eSpendingSortCategory:
			sortStr = kUSASpending_SortByCategory;
			break;
		default:
		case eSpendingSortDollars:
			sortStr = kUSASpending_SortByDollars;
			break;
	}
	
	NSString *detailStr;
	switch ( detail )
	{
		default:
		case eSpendingDetailSummary:
			detailStr = kUSASpending_DetailLevel_Summary;
			break;
		case eSpendingDetailLow:
			detailStr = kUSASpending_DetailLevel_Low;
			break;
		case eSpendingDetailMed:
			detailStr = kUSASpending_DetailLevel_Medium;
			break;
		case eSpendingDetailHigh:
			detailStr = kUSASpending_DetailLevel_High;
			break;
		case eSpendingDetailComplete:
			detailStr = kUSASpending_DetailLevel_Complete;
			break;
	}
	
	NSMutableString *urlStr = [[[NSMutableString alloc] initWithString:kUSASpending_fpdsURL] autorelease];
	[urlStr appendFormat:@"%@%@=%@%@=%0d%@%@",
							(xmldata ? kUSASpending_DataTypeXML : kUSASpending_DataTypeHTML),
							kUSASpending_DistrictKey,district,
							kUSASpending_FiscalYearKey,year,
							sortStr,
							detailStr
	];
	return (NSString *)urlStr;
}


+ (NSString *)USASpending_stateURL:(NSString *)state 
						   forYear:(NSInteger)year 
						withDetail:(SpendingDetail)detail 
						  sortedBy:(SpendingSortMethod)order 
							xmlURL:(BOOL)xmldata
{
	NSString *sortStr;
	switch ( order )
	{
		case eSpendingSortDate:
			sortStr = kUSASpending_SortByDate;
			break;
		case eSpendingSortAgency:
			sortStr = kUSASpending_SortByContractingAgency;
			break;
		case eSpendingSortContractor:
			sortStr = kUSASpending_SortByContractor;
			break;
		case eSpendingSortCategory:
			sortStr = kUSASpending_SortByCategory;
			break;
		default:
		case eSpendingSortDollars:
			sortStr = kUSASpending_SortByDollars;
			break;
	}
	
	NSString *detailStr;
	switch ( detail )
	{
		default:
		case eSpendingDetailSummary:
			detailStr = kUSASpending_DetailLevel_Summary;
			break;
		case eSpendingDetailLow:
			detailStr = kUSASpending_DetailLevel_Low;
			break;
		case eSpendingDetailMed:
			detailStr = kUSASpending_DetailLevel_Medium;
			break;
		case eSpendingDetailHigh:
			detailStr = kUSASpending_DetailLevel_High;
			break;
		case eSpendingDetailComplete:
			detailStr = kUSASpending_DetailLevel_Complete;
			break;
	}
	
	NSMutableString *urlStr = [[[NSMutableString alloc] initWithString:kUSASpending_fpdsURL] autorelease];
	[urlStr appendFormat:@"%@%@=%@%@=%0d%@%@",
							(xmldata ? kUSASpending_DataTypeXML : kUSASpending_DataTypeHTML),
							kUSASpending_StateKey,state,
							kUSASpending_FiscalYearKey,year,
							sortStr,
							detailStr
	];
	return (NSString *)urlStr;
}


+ (NSString *)USASpending_topContractorURL:(NSInteger)year 
						 maxNumContractors:(NSInteger)maxRecords 
								withDetail:(SpendingDetail)detail 
								  sortedBy:(SpendingSortMethod)order 
									xmlURL:(BOOL)xmldata
{
	NSString *sortStr;
	switch ( order )
	{
		case eSpendingSortDate:
			sortStr = kUSASpending_SortByDate;
			break;
		case eSpendingSortAgency:
			sortStr = kUSASpending_SortByContractingAgency;
			break;
		case eSpendingSortContractor:
			sortStr = kUSASpending_SortByContractor;
			break;
		case eSpendingSortCategory:
			sortStr = kUSASpending_SortByCategory;
			break;
		default:
		case eSpendingSortDollars:
			sortStr = kUSASpending_SortByDollars;
			break;
	}
	
	NSString *detailStr;
	switch ( detail )
	{
		default:
		case eSpendingDetailSummary:
			detailStr = kUSASpending_DetailLevel_Summary;
			break;
		case eSpendingDetailLow:
			detailStr = kUSASpending_DetailLevel_Low;
			break;
		case eSpendingDetailMed:
			detailStr = kUSASpending_DetailLevel_Medium;
			break;
		case eSpendingDetailHigh:
			detailStr = kUSASpending_DetailLevel_High;
			break;
		case eSpendingDetailComplete:
			detailStr = kUSASpending_DetailLevel_Complete;
			break;
	}
	
	NSMutableString *urlStr = [[[NSMutableString alloc] initWithString:kUSASpending_fpdsURL] autorelease];
	[urlStr appendFormat:@"%@%@=%0d%@=%0d%@%@",
							(xmldata ? kUSASpending_DataTypeXML : kUSASpending_DataTypeHTML),
							kUSASpending_MaxRecordsKey,maxRecords,
							kUSASpending_FiscalYearKey,year,
							detailStr,
							sortStr
	];
	return (NSString *)urlStr;
}


+ (NSString *)USASpending_contractorSearchURL:(NSString *)companyName 
									  forYear:(NSInteger)year 
								   withDetail:(SpendingDetail)detail 
									 sortedBy:(SpendingSortMethod)order 
									   xmlURL:(BOOL)xmldata
{
	NSString *sortStr;
	switch ( order )
	{
		case eSpendingSortDate:
			sortStr = kUSASpending_SortByDate;
			break;
		case eSpendingSortAgency:
			sortStr = kUSASpending_SortByContractingAgency;
			break;
		case eSpendingSortContractor:
			sortStr = kUSASpending_SortByContractor;
			break;
		case eSpendingSortCategory:
			sortStr = kUSASpending_SortByCategory;
			break;
		default:
		case eSpendingSortDollars:
			sortStr = kUSASpending_SortByDollars;
			break;
	}
	
	NSString *detailStr;
	switch ( detail )
	{
		default:
		case eSpendingDetailSummary:
			detailStr = kUSASpending_DetailLevel_Summary;
			break;
		case eSpendingDetailLow:
			detailStr = kUSASpending_DetailLevel_Low;
			break;
		case eSpendingDetailMed:
			detailStr = kUSASpending_DetailLevel_Medium;
			break;
		case eSpendingDetailHigh:
			detailStr = kUSASpending_DetailLevel_High;
			break;
		case eSpendingDetailComplete:
			detailStr = kUSASpending_DetailLevel_Complete;
			break;
	}
	
	NSMutableString *urlStr = [[[NSMutableString alloc] initWithString:kUSASpending_fpdsURL] autorelease];
	[urlStr appendFormat:@"%@%@=%0d%@=%@%@%@%@",
				(xmldata ? kUSASpending_DataTypeXML : kUSASpending_DataTypeHTML),
				kUSASpending_FiscalYearKey,year,
				kUSASpending_ContractorKey,[companyName stringByAddingPercentEscapesUsingEncoding:NSMacOSRomanStringEncoding],
				detailStr,
				kUSASpending_SearchAppendKey,
				sortStr
	 ];
	return (NSString *)urlStr;
}


+ (NSString *)GAE_DownloadURLFor:(CommunityItemType)type
{
	switch ( type )
	{
		default:
			return nil;
			
		case eCommunity_Chatter:
			return kGAE_downloadCommunityChatterURL;
			
		case eCommunity_Event:
			return kGAE_downloadCommunityEventsURL;
	}
	
	return nil;
}


+ (NSString *)GAE_CommunityItemPOSTURLFor:(CommunityItemType)type
{
	switch ( type )
	{
		default:
			return nil;
			
		case eCommunity_Chatter:
			return kGAE_postCommunityChatterURL;
			
		case eCommunity_Event:
			return kGAE_postCommunityEventsURL;
	}
	
	return nil;
}


+ (NSString *)GAE_CommunityItemCommentsURLFor:(CommunityItem *)item
{
	if ( nil == item ) return nil;
	
	NSString *urlStr = [[[NSString alloc] initWithFormat:kGAE_downloadCommentsURL,
											item.m_id
						] autorelease];
	return urlStr;
}


+ (NSString *)GAE_CommunityReplyPOSTURLFor:(NSString *)itemID
{
	if ( nil == itemID ) return nil;
	NSString *urlStr = [[[NSString alloc] initWithFormat:kGAE_postCommunityCommentURL,
											itemID
						] autorelease];
	return urlStr;
}


+ (NSString *)GAE_GoogleURLsDictKey
{
	return kGAE_GoogleURLsDictKey;
}


+ (NSString *)GAE_GoogleLoginURLDictKey
{
	return kGAE_GoogleLoginURLDictKey;
}


+ (NSString *)GAE_ItemsDictKey
{
	return kGAE_ItemsDictKey;
}

+ (NSString *)GAE_GoogleURLTitleDictKey
{
	return kGAE_GoogleURLTitleDictKey;
}


+ (NSString *)GAE_GoogleLoginURLTitle
{
	return kGAE_GoogleLoginURLTitle;
}


+ (NSString *)Cholor_UserAuthURL
{
	return kCholor_UserAuthURL;
}


+ (NSString *)Cholor_UserAddURL
{
	return kCholor_UserAddURL;
}


+ (NSString *)Cholor_UserLookupURL
{
	return kCholor_UserLookupURL;
}


+ (NSString *)Cholor_UserAuthFailedStr
{
	return kCholor_UserAuthFailedStr;
}


+ (NSString *)Cholor_CommunityItemPOSTURL
{
	return kCholor_CommunityItemPostURL;
}


+ (NSString *)Cholor_CommunityCommentPOSTURL
{
	return kCholor_CommunityCommentPostURL;
}


+ (NSString *)Cholor_CommunityItemPOSTSucess
{
	return kCholor_CommunityItemPOSTSuccess;
}


+ (NSString *)Cholor_DownloadURLFor:(CommunityItemType)type
{
	switch ( type )
	{
		default:
			return nil;
		
		case eCommunity_Chatter:
			return kCholor_downloadCommunityChatterURL;
			
		case eCommunity_Event:
			return kCholor_downloadCommunityEventsURL;
	}
	
	return nil;
}


@end

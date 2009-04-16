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
static NSString *kGovtrack_locLookupXML = @"http://www.govtrack.us/perl/district-lookup.cgi?";
static NSString *kGovtrack_latLongFmt = @"lat=%f&long=%f";


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


@end

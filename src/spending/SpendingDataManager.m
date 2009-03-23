//
//  SpendingDataManager.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"

#import "CongressDataManager.h"
#import "PlaceSpendingData.h"
#import "SpendingDataManager.h"


@interface SpendingDataManager (private)
	- (void)timerFireMethod:(NSTimer *)timer;
	- (void)downloadPlaceData:(PlaceSpendingData *)psd;
	//- (void)downloadContractorData:(NSString *)contractor;
@end


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
		isDataAvailable = NO;
		isBusy = NO;
		
		m_notifyTarget = nil;
		m_districtSpendingSummary = [[NSMutableDictionary alloc] initWithCapacity:480];
		m_stateSpendingSummary = [[NSMutableDictionary alloc] initWithCapacity:50];
		m_contractorSpendingSummary = [[NSMutableDictionary alloc] initWithCapacity:100];
		
		m_downloadOperations = [[NSOperationQueue alloc] init];
		[m_downloadOperations setMaxConcurrentOperationCount:2]; // only 2 downloads at a time (for now...)
		
		m_timer = nil;
		
		CongressDataManager *cdm = [myGovAppDelegate sharedCongressData];
		if ( (nil == cdm) || (![cdm isDataAvailable]) )
		{
			// start a timer that will periodically check to see if
			// congressional data is ready... no this is not the most
			// efficient way of doing this...
			m_timer = [NSTimer timerWithTimeInterval:0.75 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
			[[NSRunLoop mainRunLoop] addTimer:m_timer forMode:NSDefaultRunLoopMode];
		}
	}
	return self;
}


- (void)dealloc
{
	[m_notifyTarget release];
	[m_districtSpendingSummary release];
	[m_stateSpendingSummary release];
	[m_contractorSpendingSummary release];
	
	[m_downloadOperations release]; // XXX - stop current operations gracefully? 
	
	if ( nil != m_timer ) [m_timer invalidate];
	
	[super dealloc];
}


- (void)setNotifyTarget:(id)target withSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = [target retain];
	m_notifySelector = sel;
}


- (void)cancelAllDownloads
{
	[m_downloadOperations cancelAllOperations];
}


- (NSArray *)congressionalDistricts
{
	if ( ![self isDataAvailable] ) return nil;
	
	CongressDataManager *cdm = [myGovAppDelegate sharedCongressData];
	return [cdm congressionalDistricts];
}


- (NSInteger)numDistrictsInState:(NSString *)state
{
	if ( ![self isDataAvailable] ) return 0;
	
	CongressDataManager *cdm = [myGovAppDelegate sharedCongressData];
	NSArray *representatives = [cdm houseMembersInState:state];
	if ( nil == representatives ) return 0;
	else return [representatives count];
}


- (PlaceSpendingData *)getDistrictData:(NSString *)district andWaitForDownload:(BOOL)yesOrNo
{
	PlaceSpendingData *dsd = [m_districtSpendingSummary objectForKey:district];
	
	if ( nil == dsd )
	{
		dsd = [[PlaceSpendingData alloc] initWithDistrict:district];
		[m_districtSpendingSummary setValue:dsd forKey:district];
		[dsd release]; // the dictionary holds the last reference...
	}
	
	if ( ![dsd isDataAvailable] && ![dsd isBusy] )
	{
		// kick off a download operation
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																	  selector:@selector(downloadPlaceData:) object:dsd];
		// Add the operation to our download management queue
		[m_downloadOperations addOperation:theOp];
		
		if ( YES == yesOrNo )
		{
			// XXX - somehow wait for data to be downloaded and parsed...
		}
	}
	
	return dsd;
}


- (PlaceSpendingData *)getStateData:(NSString *)state andWaitForDownload:(BOOL)yesOrNo
{
	PlaceSpendingData *psd = [m_stateSpendingSummary objectForKey:state];
	
	if ( nil == psd )
	{
		psd = [[PlaceSpendingData alloc] initWithState:state];
		[m_stateSpendingSummary setValue:psd forKey:state];
		[psd release]; // the dictionary holds the last reference...
	}
	
	if ( ![psd isDataAvailable] && ![psd isBusy] )
	{
		// kick off a download operation
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																	  selector:@selector(downloadPlaceData:) object:psd];
		// Add the operation to our download management queue
		[m_downloadOperations addOperation:theOp];
		
		if ( YES == yesOrNo )
		{
			// XXX - somehow wait for data to be downloaded and parsed...
		}
	}
	
	return psd;
}


// -(ContractorSpendingData *)getContractorData:(NSString *)contractor andWaitForDownload:(BOOL)yesOrNo;


#pragma mark SpendingDataManager Private 


- (void)timerFireMethod:(NSTimer *)timer
{
	if ( timer != m_timer ) return;
	
	CongressDataManager *cdm = [myGovAppDelegate sharedCongressData];
	if ( (nil != cdm) && ([cdm isDataAvailable]) )
	{
		// stop this timer, and start downloading some spending data!
		[timer invalidate];
		m_timer = nil;
		
		isDataAvailable = YES;
		if ( nil != m_notifyTarget )
		{
			[m_notifyTarget performSelector:m_notifySelector withObject:self];
		}
	}
}


- (void)downloadPlaceData:(PlaceSpendingData *)psd
{
	NSLog( @"SpendingDataManager: downloading data for %@...",psd.m_place );
	
	[psd downloadDataWithCallback:nil onObject:nil synchronously:YES];
	
	if ( nil == m_timer )
	{
		m_timer = [NSTimer timerWithTimeInterval:0.75 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
		[[NSRunLoop mainRunLoop] addTimer:m_timer forMode:NSDefaultRunLoopMode];
	}
}


//- (void)downloadStateData:(NSString *)state;
//- (void)downloadContractorData:(NSString *)contractor;


@end


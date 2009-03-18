//
//  SpendingDataManager.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "SpendingDataManager.h"


@implementation SpendingDataManager

@synthesize isDataAvailable;
@synthesize isBusy;

static NSString *kUSASpending_districtSummaryXML = @"http://www.usaspending.gov/fpds/fpds.php?reptype=r&database=fpds&fiscal_year=2009&mustcd=y&datype=X&sortby=f";

static NSString *kDetailLevel_Summary = @"&detail=-1";
static NSString *kDetailLevel_Low = @"&detail=0";
static NSString *kDetailLevel_Medium = @"&detail=1";
static NSString *kDetailLevel_High = @"&detail=2";
static NSString *kDetailLevel_Complete = @"&detail=4";

static NSString *kDistrictKey = @"&pop_cd2=";

@end

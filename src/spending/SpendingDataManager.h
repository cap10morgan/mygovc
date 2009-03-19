//
//  SpendingDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

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
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

+ (NSString *)dataCachePath;
+ (NSURL *)getURLForDistrict:(NSString *)district forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order;
+ (NSURL *)getURLForState:(NSString *)state forYear:(NSInteger)year withDetail:(SpendingDetail)detail sortedBy:(SpendingSortMethod)order;


@end

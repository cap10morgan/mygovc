//
//  PlaceSpendingData.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLParserOperation.h"


typedef enum
{
	eDSE_None,
	eDSE_Totals,
	eDSE_TopCongDistricts,
	eDSE_TopContractors,
	eDSE_TopAgencies,
	eDSE_TopCategories,
} DistrictSummaryElement;


typedef enum
{
	eSPT_District,
	eSPT_State,
} SpendingPlaceType;



@interface PlaceSpendingData : NSObject <XMLParserOperationDelegate>
{
	BOOL       isDataAvailable;
	BOOL       isBusy;
	
	NSString  *m_place;
	NSUInteger m_year;
	CGFloat    m_pctOfYear;
	NSUInteger m_rank;
	CGFloat    m_totalDollarsObligated;
	NSUInteger m_totalContractors;
	NSUInteger m_totalTransactions;
	
	SpendingPlaceType    m_placeType;
	
@private
	NSMutableDictionary *m_topCDists;
	NSMutableDictionary *m_topContractors;
	NSMutableDictionary *m_topAgencies;
	NSMutableDictionary *m_topCategories;
	
	NSURL *m_currentURL;
	XMLParserOperation *m_xmlParser;
	BOOL m_parsingData;
	BOOL m_parsingRecord;
	NSMutableString *m_currentXMLStr;
	CGFloat m_currentFloatVal;
	DistrictSummaryElement m_currentParseElement;
	
	BOOL m_tryAlternateURL;
	
	id  m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;
@property (readonly) NSString *m_place;
@property (readonly) NSUInteger m_year;
@property (readonly) CGFloat m_pctOfYear;
@property (readonly) NSUInteger m_rank;
@property (readonly) CGFloat m_totalDollarsObligated;
@property (readonly) NSUInteger m_totalContractors;
@property (readonly) NSUInteger m_totalTransactions;
@property (readonly) SpendingPlaceType m_placeType;

- (id)initWithDistrict:(NSString *)district;
- (id)initWithState:(NSString *)state;

- (NSArray *)placeLegislators:(BOOL)includeSenators;

- (NSString *)placeDescrip;
- (NSString *)fiscalYearDescrip;
- (NSString *)totalDollarsStr;
- (NSString *)rankStr;
- (NSString *)rankStrAlt;
- (BOOL)rankIsTop25Pct;
- (NSString *)totalContractorsStr;
- (NSString *)totalTransactionsStr;

- (NSDictionary *)topCDistsWhereWorkPerformed;
- (NSDictionary *)topContractors;
- (NSDictionary *)topAgencies;
- (NSDictionary *)topCategories;

- (NSURL *)getContractorListURL;
- (NSURL *)getTransactionListURL;
- (NSURL *)getSummaryURL;

- (void)downloadDataWithCallback:(SEL)sel onObject:(id)obj synchronously:(BOOL)waitForData;


@end


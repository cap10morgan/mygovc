//
//  DistrictSpendingData.h
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
	eDSE_TopContractors,
	eDSE_TopAgencies,
	eDSE_TopCategories,
} DistrictSummaryElement;


@interface DistrictSpendingData : NSObject <XMLParserOperationDelegate>
{
	BOOL       m_dataAvailable;
	
	NSString  *m_district;
	NSUInteger m_year;
	CGFloat    m_districtRank;
	CGFloat    m_totalDollarsObligated;
	NSUInteger m_totalContractors;
	NSUInteger m_totalTransactions;
	
@private
	NSMutableDictionary *m_topContractors;
	NSMutableDictionary *m_topAgencies;
	NSMutableDictionary *m_topCategories;
	
	XMLParserOperation *m_xmlParser;
	BOOL m_parsingData;
	BOOL m_parsingRecord;
	NSMutableString *m_currentXMLStr;
	CGFloat m_currentFloatVal;
	DistrictSummaryElement m_currentParseElement;
	
	id  m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL m_dataAvailable;
@property (readonly) NSString *m_district;
@property (readonly) NSUInteger m_year;
@property (readonly) CGFloat m_districtRank;
@property (readonly) CGFloat m_totalDollarsObligated;
@property (readonly) NSUInteger m_totalContractors;
@property (readonly) NSUInteger m_totalTransactions;

- (id)initWithDistrict:(NSString *)district;

- (NSDictionary *)topContractors;
- (NSDictionary *)topAgencies;
- (NSDictionary *)topCategories;

- (void)downloadDataWithCallback:(SEL)sel onObject:(id)obj;

@end


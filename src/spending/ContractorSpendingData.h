//
//  ContractorSpendingData.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/25/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SpendingDataManager.h"
#import "XMLParserOperation.h"


@interface ContractorInfo : NSObject 
{
	NSString   *m_parentCompany;
	NSArray    *m_additionalNames;
	NSInteger   m_fiscalYear;
	CGFloat     m_obligatedAmount;
	NSUInteger  m_parentDUNS;
}

@property (retain) NSString  *m_parentCompany;
@property          NSInteger  m_fiscalYear;
@property          CGFloat    m_obligatedAmount;
@property          NSUInteger m_parentDUNS;

- (NSArray *)additionalNames;
- (void)setAdditionalNamesFromString:(NSString *)namesSeparatedBySemiColon;

- (NSComparisonResult)compareDollarsWith:(ContractorInfo *)that;
- (NSComparisonResult)compareNameWith:(ContractorInfo *)that;

@end



@interface ContractorSpendingData : NSObject <XMLParserOperationDelegate>
{
	BOOL       isDataAvailable;
	BOOL       isBusy;

@private
	NSMutableArray *m_infoSortedByName;
	NSMutableArray *m_infoSortedByDollars;
	
	XMLParserOperation *m_xmlParser;
	BOOL m_parsingData;
	BOOL m_parsingRecord;
	ContractorInfo  *m_currentContractorInfo;
	NSMutableString *m_currentXMLStr;
	CGFloat m_currentFloatVal;
	
	id  m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly,getter=isDataAvailable) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

- (NSArray *)contractorsSortedBy:(SpendingSortMethod)order;
- (ContractorInfo *)contractorAtIndex:(NSInteger)idx whenSortedBy:(SpendingSortMethod)order;

- (void)downloadDataWithCallback:(SEL)sel onObject:(id)obj synchronously:(BOOL)waitForData;

@end

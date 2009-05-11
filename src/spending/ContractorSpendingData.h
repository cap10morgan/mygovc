/*
 File: ContractorSpendingData.h
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

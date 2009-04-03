//
//  BillsDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLParserOperation.h"

@class BillContainer;

@interface BillsDataManager : NSObject <XMLParserOperationDelegate>
{
@private
	BOOL isDataAvailable;
	BOOL isBusy;
	
	NSMutableArray *m_billData;
	
	XMLParserOperation *m_xmlParser;
	
	id m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

+ (NSString *)dataCachePath;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (void)beginBillSummaryDownload;

- (BillContainer *)billAtIndex:(NSInteger)index;

@end

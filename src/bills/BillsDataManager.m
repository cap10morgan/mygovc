//
//  BillsDataManager.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "myGovAppDelegate.h"

#import "BillContainer.h"
#import "BillsDataManager.h"
#import "BillSummaryXMLParser.h"
#import "CongressDataManager.h"
#import "XMLParserOperation.h"


@interface BillsDataManager (private)
	- (void)addNewBill:(BillContainer *)bill;
@end



@implementation BillsDataManager

static NSString *kOpenCongress_APIKey = @"32aea132a66093e9bf9ebe9fc2e2a4c66b888777";
static NSString *kOpenCongress_BillsXMLFmt = @"http://www.opencongress.org/api/bills?key=%@&congress=%d";


@synthesize isDataAvailable;
@synthesize isBusy;

+ (NSString *)dataCachePath
{
	NSString *congressDataPath = [[myGovAppDelegate sharedAppCacheDir] stringByAppendingPathComponent:@"bills"];
	return congressDataPath;
}


- (id)init
{
	if ( self = [super init] )
	{
		isDataAvailable = NO;
		isBusy = NO;
		
		m_notifyTarget = nil;
		m_notifySelector = nil;
		
		// initialize data arrays...
		m_billData = [[NSMutableArray alloc] initWithCapacity:4];
		
		m_xmlParser = nil;
	}
	return self;
}


- (void)dealloc
{
	isDataAvailable = NO;
	isBusy = NO;
	[m_notifyTarget release];
	[m_billData release];
	[m_xmlParser release];
	[super dealloc];
}


- (void)setNotifyTarget:(id)target withSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = [target retain];
	m_notifySelector = sel;
}


- (void)beginBillSummaryDownload
{
	isDataAvailable = NO;
	isBusy = YES;
	
	if ( nil != m_notifyTarget )
	{
		NSString *message = [NSString stringWithString:@"BILLS Downloading Bill Summary Data..."];
		[m_notifyTarget performSelector:m_notifySelector withObject:message];
	}
	
	NSString *xmlURL = [NSString stringWithFormat:kOpenCongress_BillsXMLFmt,
									kOpenCongress_APIKey,
									[[myGovAppDelegate sharedCongressData] currentCongressSession]
						];
	
	if ( nil != m_xmlParser )
	{
		// abort any previous attempt at parsing/downloading
		[m_xmlParser abort];
	}
	else
	{
		m_xmlParser = [[XMLParserOperation alloc] initWithOpDelegate:self];
	}
	m_xmlParser.m_opDelegate = self;
	
	BillSummaryXMLParser *bsxp = [[BillSummaryXMLParser alloc] initWithBillsData:self];
	[bsxp setNotifyTarget:m_notifyTarget andSelector:m_notifySelector];
	
	[m_xmlParser parseXML:[NSURL URLWithString:xmlURL] withParserDelegate:bsxp];
	[bsxp release];
}


- (BillContainer *)billAtIndex:(NSInteger)index;
{
	if ( index < [m_billData count] )
	{
		return (BillContainer *)[m_billData objectAtIndex:index];
	}
	return nil;
}


#pragma BillsDataManager Private 


- (void)addNewBill:(BillContainer *)bill
{
	[m_billData addObject:bill];
	
	// XXX - Order by date?
}


#pragma mark XMLParserOperationDelegate Methods


- (void)xmlParseOpStarted:(XMLParserOperation *)parseOp
{
	NSLog( @"BillsDataManager started XML download..." );
}


- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	isDataAvailable = success;
	
	if ( nil != m_notifyTarget )
	{
		NSString *message = [NSString stringWithFormat:@"BILLS %@",(success ? @"Download Complete." : @"ERROR")];
		[m_notifyTarget performSelector:m_notifySelector withObject:message];
	}
	NSLog( @"BillsDataManager XML parsing ended %@", (success ? @"successfully." : @" in failure!") );
	
	if ( isDataAvailable )
	{
		// XXX - archive the bill summary data !
		/*
		isBusy = YES; // we're writing the cache!
		
		// kick off the caching of this data
		NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
																			selector:@selector(writeLegislatorDataToCache:) object:self];
		
		// Add the operation to the internal operation queue managed by the application delegate.
		[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
		
		[theOp release];
		*/
	}
	else
	{
		isBusy = NO;
	}
	
}


@end

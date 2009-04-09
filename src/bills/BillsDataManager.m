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
		m_houseSections = [[NSMutableArray alloc] initWithCapacity:12];
		m_houseBills = [[NSMutableDictionary alloc] initWithCapacity:12];
		m_senateSections = [[NSMutableArray alloc] initWithCapacity:12];
		m_senateBills = [[NSMutableDictionary alloc] initWithCapacity:12];
		
		m_xmlParser = nil;
		m_timer = nil;
	}
	return self;
}


- (void)dealloc
{
	isDataAvailable = NO;
	isBusy = NO;
	[m_notifyTarget release];
	[m_houseSections release];
	[m_houseBills release];
	[m_senateSections release];
	[m_senateBills release];
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
	
	// make sure we have congress data before downloading bill data - 
	// this ensures that we grab the right congressional session!
	if ( ![[myGovAppDelegate sharedCongressData] isDataAvailable] )
	{
		// start a timer that will periodically check to see if
		// congressional data is ready... no this is not the most
		// efficient way of doing this...
		if ( nil == m_timer )
		{
			m_timer = [NSTimer timerWithTimeInterval:0.75 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
			[[NSRunLoop mainRunLoop] addTimer:m_timer forMode:NSDefaultRunLoopMode];
		}
		return;
	}
	
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
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


- (NSInteger)totalBills
{
	return ([self houseBills] + [self senateBills]);
}

/*
- (BillContainer *)billAtIndex:(NSInteger)index;
{
	if ( index < [m_billData count] )
	{
		return (BillContainer *)[m_billData objectAtIndex:index];
	}
	return nil;
}
*/

- (NSInteger)houseBills
{
	NSInteger numBills = 0;
	
	NSEnumerator *henum = [m_houseBills objectEnumerator];
	id obj;
	while ( obj = [henum nextObject] )
	{
		numBills += [obj count];
	}
	
	return numBills;
}


- (NSInteger)houseBillSections
{
	return [m_houseSections count];
}


- (NSInteger)houseBillsInSection:(NSInteger)section
{
	if ( section >= [m_houseSections count] ) return 0;
	return [[m_houseBills objectForKey:[m_houseSections objectAtIndex:section]] count];
}


- (NSString *)houseSectionTitle:(NSInteger)section
{
	if ( section >= [m_houseSections count] ) return nil;
	
	NSNumber *key = [m_houseSections objectAtIndex:section];
	NSInteger year = 3000 - ([key integerValue] >> 5);
	NSInteger month = 12 - ([key integerValue] & 0x1F);
	{
		// return the name of the month in which these 
		// bills were last acted upon
		
		NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
		
		NSString *title = [NSString stringWithFormat:@"%@ %4d",
										[[dateFmt monthSymbols] objectAtIndex:month],
										year
						   ];
		return title;
	}
}


- (BillContainer *)houseBillAtIndexPath:(NSIndexPath *)indexPath
{
	if ( indexPath.section >= [m_houseSections count] ) return nil;
	
	NSArray *monthBills = [m_houseBills objectForKey:[m_houseSections objectAtIndex:indexPath.section]];
	if ( indexPath.row >= [monthBills count] ) return nil;
	
	return [monthBills objectAtIndex:indexPath.row];
}


- (NSInteger)senateBills
{
	NSInteger numBills = 0;
	
	NSEnumerator *henum = [m_senateBills objectEnumerator];
	id obj;
	while ( obj = [henum nextObject] )
	{
		numBills += [obj count];
	}
	
	return numBills;
}


- (NSInteger)senateBillSections
{
	return [m_senateSections count];
}


- (NSInteger)senateBillsInSection:(NSInteger)section
{
	if ( section >= [m_senateSections count] ) return 0;
	return [[m_senateBills objectForKey:[m_senateSections objectAtIndex:section]] count];
}


- (NSString *)senateSectionTitle:(NSInteger)section
{
	if ( section >= [m_senateSections count] ) return nil;
	
	NSNumber *key = [m_senateSections objectAtIndex:section];
	NSInteger year = 3000 - ([key integerValue] >> 5);
	NSInteger month = 12 - ([key integerValue] & 0x1F);
	{
		// return the name of the month in which these 
		// bills were last acted upon
		
		NSDateFormatter *dateFmt = [[NSDateFormatter alloc] init];
		
		NSString *title = [NSString stringWithFormat:@"%@ %4d",
						   [[dateFmt monthSymbols] objectAtIndex:month],
						   year
						   ];
		return title;
	}	
}


- (BillContainer *)senateBillAtIndexPath:(NSIndexPath *)indexPath
{
	if ( indexPath.section >= [m_senateSections count] ) return nil;
	
	NSArray *monthBills = [m_senateBills objectForKey:[m_senateSections objectAtIndex:indexPath.section]];
	if ( indexPath.row >= [monthBills count] ) return nil;
	
	return [monthBills objectAtIndex:indexPath.row];
}


#pragma BillsDataManager Private 


- (void)addNewBill:(BillContainer *)bill
{
	NSMutableDictionary *chamberDict;
	NSMutableArray *chamberSections;
	switch ( bill.m_type ) 
	{
		default:
		case eBillType_h:
		case eBillType_hj:
		case eBillType_hc:
		case eBillType_hr:
			chamberDict = m_houseBills;
			chamberSections = m_houseSections;
			break;
		case eBillType_s:
		case eBillType_sj:
		case eBillType_sc:
		case eBillType_sr:
			chamberDict = m_senateBills;
			chamberSections = m_senateSections;
			break;
	}
	
	NSInteger yearMonth = NSYearCalendarUnit | NSMonthCalendarUnit;
	NSDateComponents *keyComp = [[NSCalendar currentCalendar] components:yearMonth fromDate:[bill lastActionDate]];
	
	NSInteger keyVal = ((3000 - [keyComp year]) << 5) | ((12 - [keyComp month]) & 0x1F);
	NSNumber *key = [NSNumber numberWithInt:keyVal];
	NSMutableArray *monthArray = [chamberDict objectForKey:key];
	if ( nil == monthArray )
	{
		// This is a new month - add it to the dictionary, and update our section list
		monthArray = [[NSMutableArray alloc] initWithCapacity:20];
		[chamberDict setValue:monthArray forKey:(id)key];
		[chamberSections addObject:key];
		[chamberSections sortUsingSelector:@selector(compare:)];
	}
	else
	{
		[monthArray retain];
	}
	
	[monthArray addObject:bill];
	[monthArray sortUsingSelector:@selector(lastActionDateCompare:)];
	
	[monthArray release];
}


- (void)timerFireMethod:(NSTimer *)timer
{
	if ( timer != m_timer ) return;
	
	CongressDataManager *cdm = [myGovAppDelegate sharedCongressData];
	if ( (nil != cdm) && ([cdm isDataAvailable]) )
	{
		// stop this timer, and start downloading some spending data!
		[timer invalidate];
		m_timer = nil;
		
		[self beginBillSummaryDownload];
	}
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
		[m_notifyTarget performSelector:m_notifySelector withObject:self];
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

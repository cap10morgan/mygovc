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
#import "XMLParserOperation.h"


@implementation BillsDataManager

static NSString *kOpenCongress_APIKey = @"32aea132a66093e9bf9ebe9fc2e2a4c66b888777";
static NSString *kOpenCongress_BillsXMLFmt = @"http://www.opencongress.org/api/bills?key=%@&congress=%d";

static NSString *kOpenCongress_ResponseKey = @"bills";
static NSString *kOpenCongress_BillKey = @"bill";

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
		
		m_notifyTarget = nil;
		m_notifySelector = nil;
		
		// initialize data arrays...
		/*
		m_states = [[NSMutableArray alloc] initWithCapacity:50];
		m_house = [[NSMutableDictionary alloc] initWithCapacity:50];
		m_senate = [[NSMutableDictionary alloc] initWithCapacity:50];
		m_searchArray = nil;
		*/
		m_billData = [[NSMutableArray alloc] initWithCapacity:4];
		
		m_currentString = nil;
		m_currentBill = nil;
		m_xmlParser = nil;
	}
	return self;
}


- (void)dealloc
{
	isDataAvailable = NO;
	isBusy = YES;
	[m_notifyTarget release];
	[m_billData release];
	[m_xmlParser release];
	[m_currentString release];
	[m_currentBill release];
	[super dealloc];
}


- (void)setNotifyTarget:(id)target withSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = [target retain];
	m_notifySelector = sel;
}


- (BillContainer *)billAtIndex:(NSInteger)index;
{
	if ( index < [m_billData count] )
	{
		return (BillContainer *)[m_billData objectAtIndex:index];
	}
	return nil;
}


@end

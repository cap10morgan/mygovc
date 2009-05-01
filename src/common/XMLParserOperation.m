//
//  XMLParserOperation.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "XMLParserOperation.h"
#import "myGovAppDelegate.h"


@interface XMLParserOperation (private)
	-(void)downloadAndParse:(id)data;
@end


@implementation XMLParserOperation

@synthesize m_xmlDelegate;
@synthesize m_xmlURL;
@synthesize m_opDelegate;
@synthesize m_finished;
@synthesize m_success;

- (id)init
{
	if ( self = [super init] )
	{
		self.m_xmlDelegate = self;
		self.m_opDelegate = self;
		m_strEncoding = NSUTF8StringEncoding;
	}
	return self;
}


- (id)initWithOpDelegate:(id)oDelegate
{
	if ( ![oDelegate conformsToProtocol:@protocol(XMLParserOperationDelegate)] )
	{
		NSLog( @"XMLParserOperation: OpDelegate does not conform to XMLParserOperationDelegate protocol!" );
		return self;
	}
	self.m_opDelegate = [oDelegate retain];
	self.m_xmlDelegate = self;
	m_strEncoding = NSUTF8StringEncoding;
	
	return self;
}


- (void)dealloc
{
	[m_xmlURL release];
	if ( (id)self != m_xmlParser ) [m_xmlParser release];
	if ( (id)self != m_opDelegate ) [m_opDelegate release];
	[super dealloc];
}


- (void)parseXML
{
	m_finished = NO;
	if ( (nil == m_xmlDelegate) || (nil == m_xmlURL) ) 
	{
		m_finished = YES;
		m_success = NO;
		[m_opDelegate xmlParseOp:self endedWith:m_success];
		return;
	}
	[self parseXML:m_xmlURL withParserDelegate:m_xmlDelegate];
}


- (void)parseXML: (NSURL *)url
{
	m_finished = NO;
	if ( nil == m_xmlDelegate ) 
	{
		m_finished = YES;
		m_success = NO;
		[m_opDelegate xmlParseOp:self endedWith:m_success];
		return;
	}
	[self parseXML:url withParserDelegate:m_xmlDelegate];
}


- (void)parseXML:(NSURL *)url withParserDelegate:(id)pDelegate
{
	m_finished = NO;
	self.m_xmlURL = [url retain];
	if ( (id)self != pDelegate && nil != pDelegate )
	{
		self.m_xmlDelegate = [pDelegate retain];
	}
	else
	{
		self.m_xmlDelegate = self;
	}
	
	// Create an invocation operation instance which will call 
	// our 'downloadAndParse' method as a thread's "main" function
	// somewhat auto-magically
	NSInvocationOperation* xmlOp = [[NSInvocationOperation alloc] initWithTarget:self
																  selector:@selector(downloadAndParse:) 
																  object:nil];
	
    // Add the operation to the internal operation queue managed by the application delegate.
    [[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:xmlOp];
	
	[xmlOp release];
}


- (void)parseXML: (NSURL *)url withParserDelegate:(id)pDelegate withStringEncoding:(NSStringEncoding)encoding
{
	// custom string encoding request...
	m_strEncoding = encoding;
	[self parseXML:url withParserDelegate:pDelegate];
}


- (void)downloadAndParse:(id)data
{
	if ( nil != m_xmlParser ) [m_xmlParser release];
	
	[m_opDelegate xmlParseOpStarted:self];
	
	if ( NSUTF8StringEncoding == m_strEncoding )
	{
		m_xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:m_xmlURL];
	}
	else
	{
		// custom string encoding... YUCK!
		NSData *data = [NSData dataWithContentsOfURL:m_xmlURL];
		NSString *xmlStr = [[NSString alloc] initWithData:data encoding:m_strEncoding];
		m_xmlParser = [[NSXMLParser alloc] initWithData:[xmlStr dataUsingEncoding:NSUTF8StringEncoding]];
		[xmlStr release];
	}
	
	if ( nil == m_xmlParser ) 
	{
		m_finished = YES;
		m_success = NO;
		[m_opDelegate xmlParseOp:self endedWith:m_success];
		return;
	}
	
	[m_xmlParser setDelegate:m_xmlDelegate];
	m_success = [m_xmlParser parse];
	m_finished = YES;
	
	[m_opDelegate xmlParseOp:self endedWith:m_success];
}


- (void)abort
{
	if ( nil != m_xmlParser )
	{
		[m_xmlParser abortParsing];
	}
	m_finished = YES;
	m_success = NO;
}


- (void)xmlParseOpStarted:(XMLParserOperation *)parseOp
{
	// Nothing to do...
	//NSLog( @"XMLParserOperation parsing started..." );
}



- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success
{
	// Nothing to do...
	//NSLog( @"XMLParserOperation parsing ended %@", (success ? @"successfully!" : @"in failure!") );
}


@end

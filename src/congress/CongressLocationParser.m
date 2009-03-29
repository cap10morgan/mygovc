//
//  CongressLocationParser.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CongressLocationParser.h"
#import "CongressDataManager.h"

@interface CongressDataManager (private)
	- (void)setCurrentState:(NSString *)stateAbbr andDistrict:(NSUInteger)district;
@end

@implementation CongressLocationParser

// Govtrack Congressional District Mapper Keys
static NSString *kName_Response = @"congressional-district";
static NSString *kName_State = @"state";
static NSString *kName_District = @"district";
static NSString *kName_Member = @"member";


- (id)initWithCongressData:(CongressDataManager *)data;
{
	if ( self = [super init] )
	{
		m_data = [data retain];
		m_notifyTarget = nil;
		m_notifySelector = nil;
		m_currentString = nil;
		m_currentState = nil;
		m_currentDistrict = 0;
	}
	return self;
}


- (void)dealloc
{
	[m_currentState release];
	[m_currentString release];
	[m_notifyTarget release];
	[m_data release];
	[super dealloc];
}


- (void)setNotifyTarget:(id)target andSelector:(SEL)sel
{
	[m_notifyTarget release];
	m_notifyTarget = [target retain];
	m_notifySelector = sel;
}


#pragma mark XMLParser Delegate Methods


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ( [elementName isEqualToString:kName_Response] )
	{
		m_parsingResponse = YES;
		[m_currentState release]; m_currentState = nil;
		m_currentDistrict = 0;
    } 
	else if ( m_parsingResponse ) 
	{
		m_currentString = [[NSMutableString alloc] initWithString:@""];
		m_storingCharacters = YES;
    }
	else
	{
		m_storingCharacters = NO;
		m_parsingResponse = NO;
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	m_storingCharacters = NO;
	if ( [elementName isEqualToString:kName_Response] ) 
	{
		m_parsingResponse = NO;
		[m_data setCurrentState:m_currentState andDistrict:m_currentDistrict];
	}
	else if ( m_parsingResponse && [elementName isEqualToString:kName_State] )
	{
		m_currentState = [[NSString alloc] initWithString:m_currentString];
	}
	else if ( m_parsingResponse && [elementName isEqualToString:kName_District] )
	{
		m_currentDistrict = [m_currentString integerValue];
	}
	else
	{
		// XXX - nothing to do!
	}
	[m_currentString release]; m_currentString = nil;
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
    if ( m_storingCharacters ) [m_currentString appendString:string];
}


// XXX - handle XML parse errors in some sort of graceful way...
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
	m_parsingResponse = NO;
	m_storingCharacters = NO;
	[m_currentString release]; 
	m_currentString = [[NSString alloc] initWithString:@"ERROR XML parsing error"];
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:m_currentString];
	}
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	m_parsingResponse = NO;
	m_storingCharacters = NO;
	[m_currentString release];
	m_currentString = [[NSString alloc] initWithString:@"ERROR XML validation error"];
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:m_currentString];
	}
}


/*
 – (void)parserDidStartDocument:(NSXMLParser *)parser
 {
 }
 
 – (void)parserDidEndDocument:(NSXMLParser *)parser
 {
 }
 
 
 – (void)parser:(NSXMLParser *)parser didStartMappingPrefix:(NSString *)prefix toURI:(NSString *)namespaceURI
 {
 }
 
 – (void)parser:(NSXMLParser *)parser didEndMappingPrefix:(NSString *)prefix
 {
 }
 
 – (void)parser:(NSXMLParser *)parser resolveExternalEntityName:(NSString *)entityName systemID:(NSString *)systemID
 {
 }
 
 – (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
 {
 }
 
 
 – (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
 {
 }
 
 – (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString
 {
 }
 
 – (void)parser:(NSXMLParser *)parser foundProcessingInstructionWithTarget:(NSString *)target data:(NSString *)data
 {
 }
 
 – (void)parser:(NSXMLParser *)parser foundComment:(NSString *)comment
 {
 }
 
 – (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
 {
 }
 */

@end

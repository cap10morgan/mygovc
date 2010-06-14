/*
 File: CongressDatabaseParser.m
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

#import "CongressDatabaseParser.h"
#import "CongressDataManager.h"
#import "LegislatorContainer.h"

@interface CongressDataManager (private)
	- (void)addLegislatorToInMemoryCache:(id)legislator release:(BOOL)flag;
	- (NSMutableArray *)states_mut;
@end

@implementation CongressDatabaseParser

// Legislator XML key names
static NSString *kName_Response = @"response";
static NSString *kName_Legislator = @"legislator";
static NSString *kName_State = @"state";


- (id)initWithCongressData:(CongressDataManager *)data;
{
	if ( self = [super init] )
	{
		m_data = [data retain];
		m_notifyTarget = nil;
		m_notifySelector = nil;
		m_currentString = nil;
		m_currentLegislator = nil;
	}
	return self;
}


- (void)dealloc
{
	[m_currentString release];
	[m_currentLegislator release];
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
		if ( nil != m_notifyTarget )
		{
			NSString *message = [NSString stringWithString:@"Parsing data..."];
			if ( [m_notifyTarget respondsToSelector:m_notifySelector] )
				[m_notifyTarget performSelector:m_notifySelector withObject:message];
		}
	}
    else if ( [elementName isEqualToString:kName_Legislator] ) 
	{
		m_parsingLegislator = YES;
		
		// alloc a new Legislator 
		m_currentLegislator = [[LegislatorContainer alloc] init];
    } 
	else if ( m_parsingLegislator ) 
	{
		m_currentString = [[NSMutableString alloc] initWithString:@""];
		m_storingCharacters = YES;
    }
	else
	{
		m_storingCharacters = NO;
		m_parsingLegislator = NO;
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	m_storingCharacters = NO;
	if ( [elementName isEqualToString:kName_Legislator] ) 
	{
		m_parsingLegislator = NO;
		[m_data addLegislatorToInMemoryCache:m_currentLegislator release:YES];
	}
	else if ( m_parsingLegislator )
	{
		[m_currentLegislator addKey:elementName withValue:m_currentString];
		
		// Build a dynamic list of states :-)
		if ( [elementName isEqualToString:kName_State] )
		{
			if ( ![[m_data states] containsObject:m_currentString] )
			{
				[[m_data states_mut] addObject:m_currentString];
			}
			[[m_data states_mut] sortUsingSelector:@selector(caseInsensitiveCompare:)];
		}
		
		[m_currentString release]; m_currentString = nil;
	}
	else
	{
	}
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
    if ( m_storingCharacters ) [m_currentString appendString:string];
}


// XXX - handle XML parse errors in some sort of graceful way...
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
	m_parsingLegislator = NO;
	m_storingCharacters = NO;
	[m_currentLegislator release]; m_currentLegislator = nil;
	[m_currentString release];
	m_currentString = [[NSString alloc] initWithString:@"ERROR XML parsing error"];
	if ( nil != m_notifyTarget )
	{
		if ( [m_notifyTarget respondsToSelector:m_notifySelector] )
			[m_notifyTarget performSelector:m_notifySelector withObject:m_currentString];
	}
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	m_parsingLegislator = NO;
	m_storingCharacters = NO;
	[m_currentLegislator release]; m_currentLegislator = nil;
	[m_currentString release];
	m_currentString = [[NSString alloc] initWithString:@"ERROR XML validation error"];
	if ( nil != m_notifyTarget )
	{
		if ( [m_notifyTarget respondsToSelector:m_notifySelector] )
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

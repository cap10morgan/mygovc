/*
 File: BillSummaryXMLParser.m
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

#import "BillSummaryXMLParser.h"

#import "BillsDataManager.h"
#import "BillContainer.h"

@interface BillsDataManager (private)
	- (void)addNewBill:(BillContainer *)bill checkForDuplicates:(BOOL)checkDuplicates;
@end


@implementation BillSummaryXMLParser


// Govtrack Congressional District Mapper Keys
static NSString *kName_Response = @"bills";
static NSString *kName_Bill = @"bill";
static NSString *kName_Bill_Type = @"bill-type";
static NSString *kName_Bill_Id = @"id";
static NSString *kName_Bill_Introduced = @"introduced";
static NSString *kName_Bill_Number = @"number";
static NSString *kName_Bill_Summary = @"summary";
static NSString *kName_Bill_Title = @"title-full-common";
static NSString *kName_Bill_Status = @"status";

static NSString *kName_BillSponsor = @"sponsor";
static NSString *kName_Sponsor_BioguideID = @"bioguideid";

static NSString *kName_BillCoSponsors = @"co-sponsors";
static NSString *kName_Bill_CoSponsor = @"co-sponsor";
static NSString *kName_CoSponsor_BioguideID = @"bioguideid";

static NSString *kName_BillActions = @"most-recent-actions";
static NSString *kName_Bill_Action = @"most-recent-action";
static NSString *kName_Action_Id = @"id";
static NSString *kName_Action_Type = @"action-type";
static NSString *kName_Action_Date = @"date";
static NSString *kName_Action_Descrip = @"text";
static NSString *kName_Action_Result = @"result";
static NSString *kName_Action_How = @"how";


- (id)initWithBillsData:(BillsDataManager *)data;
{
	if ( self = [super init] )
	{
		m_data = [data retain];
		
		m_parsingResponse = NO;
		m_parsingBill = NO;
		m_parsingActionList = NO;
		m_parsingAction = NO;
		m_parsingCoSponsorList = NO;
		m_parsingCoSponsor = NO;
		m_parsingSponsor = NO;
		
		m_storingCharacters = NO;
		m_currentString = nil;
		
		m_currentBill = nil;
		m_currentAction = nil;
		
		m_notifyTarget = nil;
		m_notifySelector = nil;
	}
	return self;
}


- (void)dealloc
{
	[m_currentBill release];
	[m_currentAction release];
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
		[m_currentBill release]; m_currentBill = nil;
		[m_currentAction release]; m_currentAction = nil;
		[m_currentString release]; m_currentString = nil;
		[m_currentString release];
		m_currentString = [[NSMutableString alloc] init];
    }
	else if ( m_parsingResponse && [elementName isEqualToString:kName_Bill] ) 
	{
		m_parsingBill = YES;
		[m_currentBill release]; m_currentBill = nil;
		m_currentBill = [[BillContainer alloc] init];
    }
	else if ( m_parsingBill && [elementName isEqualToString:kName_BillActions] )
	{
		m_parsingActionList = YES;
	}
	else if ( m_parsingActionList && [elementName isEqualToString:kName_Bill_Action] )
	{
		m_parsingAction = YES;
		[m_currentAction release];
		m_currentAction = [[BillAction alloc] init];
	}
	else if ( m_parsingBill && !m_parsingActionList && [elementName isEqualToString:kName_BillSponsor] )
	{
		m_parsingSponsor = YES;
	}
	else if ( m_parsingBill && !m_parsingActionList && [elementName isEqualToString:kName_BillCoSponsors] )
	{
		m_parsingCoSponsorList = YES;
	}
	else if ( m_parsingCoSponsorList && [elementName isEqualToString:kName_Bill_CoSponsor] )
	{
		m_parsingCoSponsor = YES;
	}
	
	if ( m_parsingBill ) m_storingCharacters = YES;
	
	if ( [m_currentString length] > 0 )
	{
		[m_currentString setString:@""];
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	m_storingCharacters = NO;
	if ( [elementName isEqualToString:kName_Response] ) 
	{
		m_parsingResponse = NO;
	}
	else if ( m_parsingBill && !m_parsingActionList )
	{
		if ( [elementName isEqualToString:kName_Bill_Id] )
		{
			m_currentBill.m_id = [m_currentString integerValue];
		}
		else if ( [elementName isEqualToString:kName_Bill_Number] )
		{
			m_currentBill.m_number = [m_currentString integerValue];
		}
		else if ( [elementName isEqualToString:kName_Bill_Status] )
		{
			m_currentBill.m_status = m_currentString;
			// we used the string (retained it, so let's get some new memory!)
			[m_currentString release]; 
			m_currentString = [[NSMutableString alloc] init];
		}
		else if ( [elementName isEqualToString:kName_Bill_Summary] )
		{
			m_currentBill.m_summary = m_currentString;
			// we used the string (retained it, so let's get some new memory!)
			[m_currentString release]; 
			m_currentString = [[NSMutableString alloc] init];
		}
		else if ( [elementName isEqualToString:kName_Bill_Type] )
		{
			m_currentBill.m_type = [BillContainer billTypeFromString:m_currentString];
		}
		else if ( [elementName isEqualToString:kName_Bill_Title] )
		{
			m_currentBill.m_title = m_currentString;
			// we used the string (retained it, so let's get some new memory!)
			[m_currentString release]; 
			m_currentString = [[NSMutableString alloc] init];
		}
		else if ( [elementName isEqualToString:kName_Bill_Introduced] )
		{
			m_currentBill.m_bornOn = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[m_currentString integerValue]];
		}
		else if ( [elementName isEqualToString:kName_Bill] )
		{
			// add the bill to our data manager!
			[m_data addNewBill:m_currentBill checkForDuplicates:YES];
			[m_currentBill release]; m_currentBill = nil;
			m_parsingBill = NO;
		}
		else if ( m_parsingCoSponsor && [elementName isEqualToString:kName_CoSponsor_BioguideID] )
		{
			[m_currentBill addCoSponsor:m_currentString];
			m_parsingCoSponsor = NO;
		}
		else if ( m_parsingCoSponsorList && [elementName isEqualToString:kName_BillCoSponsors] )
		{
			m_parsingCoSponsorList = NO;
		}
		else if ( m_parsingSponsor && [elementName isEqualToString:kName_Sponsor_BioguideID] )
		{
			[m_currentBill addSponsor:m_currentString];
			m_parsingSponsor = NO;
		}
	}
	else if ( m_parsingAction )
	{
		if ( [elementName isEqualToString:kName_Action_Type] )
		{
			m_currentAction.m_type = m_currentString;
			// we used the string (retained it, so let's get some new memory!)
			[m_currentString release]; 
			m_currentString = [[NSMutableString alloc] init];
		}
		else if ( [elementName isEqualToString:kName_Action_How] )
		{
			m_currentAction.m_how = m_currentString;
			// we used the string (retained it, so let's get some new memory!)
			[m_currentString release]; 
			m_currentString = [[NSMutableString alloc] init];
		}
		else if ( [elementName isEqualToString:kName_Action_Result] )
		{
			NSRange passRange = {0,4};
			if ( [m_currentString length] < 4 )
			{
				m_currentAction.m_voteResult = eVote_novote;
			}
			else if ( NSOrderedSame == [m_currentString compare:@"pass" options:NSCaseInsensitiveSearch range:passRange] )
			{
				m_currentAction.m_voteResult = eVote_passed;
			}
			else if ( NSOrderedSame == [m_currentString compare:@"fail" options:NSCaseInsensitiveSearch range:passRange] )
			{
				m_currentAction.m_voteResult = eVote_failed;
			}
		}
		else if ( [elementName isEqualToString:kName_Action_Descrip] )
		{
			m_currentAction.m_descrip = m_currentString;
			// we used the string (retained it, so let's get some new memory!)
			[m_currentString release]; 
			m_currentString = [[NSMutableString alloc] init];
		}
		else if ( [elementName isEqualToString:kName_Action_Date] )
		{
			m_currentAction.m_date = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[m_currentString integerValue]];
		}
		else if ( [elementName isEqualToString:kName_Action_Id] )
		{
			m_currentAction.m_id = [m_currentString integerValue];
		}
		else if ( [elementName isEqualToString:kName_Bill_Action] )
		{
			[m_currentBill addBillAction:m_currentAction];
			[m_currentAction release]; m_currentAction = nil;
			m_parsingAction = NO;
		}
	}
	else if ( m_parsingActionList && [elementName isEqualToString:kName_BillActions] )
	{
		m_parsingActionList = NO;
	}
	else
	{
		// XXX - nothing to do!
	}
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
    if ( m_storingCharacters ) [m_currentString appendString:string];
}


// XXX - handle XML parse errors in some sort of graceful way...
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
	m_parsingResponse = NO;
	m_parsingBill = NO;
	m_parsingActionList = NO;
	m_parsingAction = NO;
	m_parsingCoSponsorList = NO;
	m_parsingCoSponsor = NO;
	m_parsingSponsor = NO;
	m_storingCharacters = NO;
	
	[m_currentString setString:@"ERROR XML parsing error"];
	if ( nil != m_notifyTarget )
	{
		[m_notifyTarget performSelector:m_notifySelector withObject:m_currentString];
	}
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	m_parsingResponse = NO;
	m_parsingBill = NO;
	m_parsingActionList = NO;
	m_parsingAction = NO;
	m_parsingCoSponsorList = NO;
	m_parsingCoSponsor = NO;
	m_parsingSponsor = NO;
	m_storingCharacters = NO;
	[m_currentString setString:@"ERROR XML validation error"];
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


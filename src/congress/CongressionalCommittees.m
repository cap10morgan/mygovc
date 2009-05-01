//
//  CongressionalCommittees.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CongressionalCommittees.h"
#import "LegislatorContainer.h"

@interface CongressionalCommittees (private)
	- (void)clearState;
	- (void)newState;
@end

static NSString *kCongressSessionKey = @"CongressSession";

static NSString *kName_CommitteesGroup = @"committees";
static NSString *kName_Committee = @"committee";
static NSString *kName_SubCommittee = @"subcommittee";
static NSString *kName_CommitteeMember = @"member";

static NSString *kProp_CommitteeID = @"code";
static NSString *kProp_CommitteeName = @"displayname";
static NSString *kProp_CommitteeURL = @"url";
static NSString *kProp_MemberID = @"id";

static NSString *kPropTitle_Parent = @"parent";


@implementation LegislativeCommittee

@synthesize m_id;
@synthesize m_name;
@synthesize m_url;
@synthesize m_parentCommittee;
@synthesize m_members;

- (id)init
{
	if ( self = [super init] )
	{
		m_members = [[NSMutableArray alloc] initWithCapacity:10];
	}
	return self;
}

- (void)dealloc
{
	[m_members release];
	[super dealloc];
}

- (NSComparisonResult)compareCommittee:(LegislativeCommittee *)other
{
	return [m_id compare:other.m_id];
/*
	// sort committees by name, but also by parent->child relationship
	if ( (nil == m_parentCommittee) && (other.m_parentCommittee != nil) )
	{
		if ( NSOrderedSame == [other.m_parentCommittee compare:m_id] )
		{
			return NSOrderedAscending;
		}
		else
		{
			return NSOrderedDescending;
		}
	}
	else
	{
		// compare by ID
		NSComparisonResult cmp = [m_id compare:other.m_id];
		if ( NSOrderedSame == cmp )
		{
			// compare by name
			return [m_name compare:other.m_name];
		}
		else
		{
			return cmp;
		}
	}
*/
}

@end



@implementation CongressionalCommittees


- (id)init
{
	if ( self = [super init] )
	{
		m_committees = nil;
		m_legislativeConnection = nil;
		
		m_parsingCommittees = NO;
		m_currentCommittee = nil;
		m_currentSubCommittee = nil;
	}
	return self;
}


- (void)dealloc
{
	[self clearState];
	[super dealloc];
}


- (void)initCommitteeDataFromFile:(NSString *)path
{
	//NSLog( @"CongressionalCommittees: reading cached data from %@",path );
	
	[self clearState];
	[self newState];
	
	NSDictionary *committeeStore = [[NSDictionary alloc] initWithContentsOfFile:path];
	
	NSString *cSession = [committeeStore objectForKey:kCongressSessionKey];
	m_congressSession = [cSession integerValue];
	
	// run through all the committees and build our in-memory data objects
	NSEnumerator *comEnum = [committeeStore keyEnumerator];
	id comKey;
	while ( (comKey = [comEnum nextObject]) ) 
	{
		if ( [comKey isEqualToString:kCongressSessionKey] ) continue;
		
		// create LegislativeCommittee object
		NSDictionary *committeeData = (NSDictionary *)[committeeStore objectForKey:comKey];
		LegislativeCommittee *committee = [[LegislativeCommittee alloc] init];
		committee.m_id = (NSString *)comKey;
		committee.m_name = [committeeData objectForKey:kProp_CommitteeName];
		committee.m_url = [committeeData objectForKey:kProp_CommitteeURL];
		committee.m_parentCommittee = [committeeData objectForKey:kPropTitle_Parent];
		
		// build legislator connection data
		NSEnumerator *memEnum = [[committeeData objectForKey:kProp_MemberID] objectEnumerator];
		id memObj;
		while ( (memObj = [memEnum nextObject]) )
		{
			NSString *memberID = (NSString *)memObj;
			NSMutableArray *committeeArray = [m_legislativeConnection objectForKey:memberID];
			if ( nil == committeeArray ) 
			{
				committeeArray = [[NSMutableArray alloc] initWithCapacity:10];
				[m_legislativeConnection setValue:committeeArray forKey:memberID];
			}
			else
			{
				[committeeArray retain];
			}
			[committeeArray addObject:committee.m_id];
			[committeeArray release];
		}
		
		// add committee to our in-memory structure
		[m_committees setValue:committee forKey:committee.m_id];
		[committee release];
	}
}


- (BOOL)writeCommitteeDataToFile:(NSString *)path
{
	if ( nil == m_committees ) return FALSE;
	
	// convert a dictionary of LegislativeCommittee objects
	// into a dictionary of PropertyList-compliant objects
	NSMutableDictionary *committeeDict = [[NSMutableDictionary alloc] initWithCapacity:[m_committees count]];
	
	// save congress session
	[committeeDict setValue:[NSString stringWithFormat:@"%d",m_congressSession] forKey:kCongressSessionKey];
	
	NSEnumerator *comEnum = [m_committees objectEnumerator];
	id comObj;
	while ( (comObj = [comEnum nextObject]) ) 
	{
		LegislativeCommittee *committee = (LegislativeCommittee *)comObj;
		NSMutableDictionary *cdict = [[NSMutableDictionary alloc] initWithCapacity:4];
		[cdict setValue:committee.m_name forKey:kProp_CommitteeName];
		[cdict setValue:committee.m_url forKey:kProp_CommitteeURL];
		[cdict setValue:committee.m_parentCommittee forKey:kPropTitle_Parent];
		[cdict setValue:committee.m_members forKey:kProp_MemberID];
		
		[committeeDict setValue:cdict forKey:committee.m_id];
	}
	
	return [committeeDict writeToFile:path atomically:YES];
}


- (void)downloadDataFrom:(NSURL *)url forCongressSession:(NSInteger)session
{
	// release memory and prepare for new data
	[self clearState];
	[self newState];
	
	m_congressSession = session;
	//NSLog( @"CongressionalCommittees: downloading %d committee data from %@ ...",session,[url absoluteString] );
	
	NSXMLParser *xmlParser = [[NSXMLParser alloc] initWithContentsOfURL:url];
	
	if ( nil == xmlParser ) 
	{
		// dang - didn't get anything
		//NSLog( @"CongressionalCommittees: could not download committee data!" );
		return;
	}
	
	[xmlParser setDelegate:self];
	//BOOL success = 
	[xmlParser parse];
	
	//NSLog( @"CongressionalCommittees: committee parsing ended %@",(success ? @"successfully." : @"in failure!") );
}


- (NSInteger)congressSession
{
	return m_congressSession;
}


- (NSArray *)getCommitteeDataFor:(LegislatorContainer *)legislator
{
	LegislativeCommittee *emptyContainer = [[LegislativeCommittee alloc] init];
	NSArray *retVal = [m_committees objectsForKeys:[m_legislativeConnection objectForKey:[legislator govtrack_id]] notFoundMarker:emptyContainer];
	[emptyContainer release];
	
	return [retVal sortedArrayUsingSelector:@selector(compareCommittee:)];
}


#pragma mark CongressionalCommittees Private Interface


- (void)clearState
{
	[m_committees release];
	[m_legislativeConnection release];
	
	m_congressSession = 0;
	
	[m_currentCommittee release]; m_currentCommittee = nil;
	[m_currentSubCommittee release]; m_currentSubCommittee = nil;
}


- (void)newState
{
	m_committees = [[NSMutableDictionary alloc] initWithCapacity:25];
	m_legislativeConnection = [[NSMutableDictionary alloc] initWithCapacity:600]; // enough for _all_ senators + representatives
}


#pragma mark XMLParser Delegate Methods


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict 
{
	if ( [elementName isEqualToString:kName_CommitteesGroup] )
	{
		m_parsingCommittees = YES;
	}
    else if ( m_parsingCommittees && [elementName isEqualToString:kName_Committee] ) 
	{
		// add a new committee
		if ( nil != m_currentCommittee )
		{
			//NSLog( @"CongressionalCommittee: previous committee (%@) did not terminate properly. Starting new one anyway...",m_currentCommittee.m_name );
			[m_currentCommittee release];
		}
		m_currentCommittee = [[LegislativeCommittee alloc] init];
		m_currentCommittee.m_id = [attributeDict objectForKey:kProp_CommitteeID];
		m_currentCommittee.m_name = [attributeDict objectForKey:kProp_CommitteeName];
		m_currentCommittee.m_url = [attributeDict objectForKey:kProp_CommitteeURL];
		m_currentCommittee.m_parentCommittee = nil;
    } 
	else if ( m_parsingCommittees && [elementName isEqualToString:kName_SubCommittee] ) 
	{
		// add a subcommittee to the current committee
		if ( nil == m_currentCommittee )
		{
			//NSLog( @"CongressionalCommittee: malformed committee XML - subcommittee started outside a committee!" );
			return;
		}
		if ( nil != m_currentSubCommittee )
		{
			//NSLog( @"CongressionalCommittee: previous subcommittee (%@) did not terminate properly. Stating new one anyway...",m_currentSubCommittee.m_name );
			[m_currentSubCommittee release];
		}
		m_currentSubCommittee = [[LegislativeCommittee alloc] init];
		m_currentSubCommittee.m_id = [NSString stringWithFormat:@"%@_%@",m_currentCommittee.m_id,[attributeDict objectForKey:kProp_CommitteeID]];
		m_currentSubCommittee.m_name = [attributeDict objectForKey:kProp_CommitteeName];
		m_currentSubCommittee.m_url = [attributeDict objectForKey:kProp_CommitteeURL];
		m_currentSubCommittee.m_parentCommittee = m_currentCommittee.m_id;
	}
	else if ( m_parsingCommittees && [elementName isEqualToString:kName_CommitteeMember] )
	{
		// add a new member to the current committee/subcommittee
		NSString *member = [[NSString alloc] initWithString:[attributeDict objectForKey:kProp_MemberID]];
		NSString *committeeID;
		if ( nil != m_currentSubCommittee )
		{
			[m_currentSubCommittee.m_members addObject:member];
			committeeID = m_currentSubCommittee.m_id;
		}
		else if ( nil != m_currentCommittee )
		{
			[m_currentCommittee.m_members addObject:member];
			committeeID = m_currentCommittee.m_id;
		}
		else
		{
			//NSLog( @"CongressionalCommittees: member found outside a committe/subcommittee!" );
		}
		NSMutableArray *committeeArray = [m_legislativeConnection objectForKey:member];
		if ( nil == committeeArray ) 
		{
			committeeArray = [[NSMutableArray alloc] initWithCapacity:10];
			[m_legislativeConnection setValue:committeeArray forKey:member];
		}
		else
		{
			[committeeArray retain];
		}
		[committeeArray addObject:committeeID];
		[committeeArray release];
		[member release];
	}
	else
	{
		// ignore this...
	}
}


- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName 
{
	if ( [elementName isEqualToString:kName_CommitteesGroup] ) 
	{
		m_parsingCommittees = NO;
		[m_currentSubCommittee release];
		[m_currentCommittee release];
	}
	else if ( m_parsingCommittees && [elementName isEqualToString:kName_Committee] )
	{
		// add this committee
		[m_committees setValue:m_currentCommittee forKey:m_currentCommittee.m_id];
		[m_currentSubCommittee release]; m_currentSubCommittee = nil;
		[m_currentCommittee release]; m_currentCommittee = nil;
	}
	else if ( m_parsingCommittees && [elementName isEqualToString:kName_SubCommittee] )
	{
		// add this subcommittee 
		[m_committees setValue:m_currentSubCommittee forKey:m_currentSubCommittee.m_id];
		[m_currentSubCommittee release]; m_currentSubCommittee = nil;
	}
	else
	{
		// nothing else to do
	}
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string 
{
	// nothing to do here!
}


// XXX - handle XML parse errors in some sort of graceful way...
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError 
{
	//NSLog( @"CongressionalCommittee: XML Parse Error: %@",[parseError localizedDescription] );
	[self clearState];
}


- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError 
{
	//NSLog( @"CongressionalCommittee: XML Validation Error: %@",[validError localizedDescription] );
	[self clearState];
}


@end


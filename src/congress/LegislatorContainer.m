//
//  LegislatorContainer.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "LegislatorContainer.h"


@implementation LegislatorContainer

static NSString * kField_Title = @"title";
static NSString * kField_FirstName = @"firstname";
static NSString * kField_MiddleName = @"middlename";
static NSString * kField_LastName = @"lastname";
static NSString * kField_NameSuffix = @"name_suffix";
static NSString * kField_Nickname = @"nickname";
static NSString * kField_Party = @"party";
static NSString * kField_State = @"state";
static NSString * kField_District = @"district";
static NSString * kField_InOffice = @"in_office";
static NSString * kField_Gender = @"gender";
static NSString * kField_Phone = @"phone";
static NSString * kField_Fax = @"fax";
static NSString * kField_Website = @"website";
static NSString * kField_Webform = @"webform";
static NSString * kField_Email = @"email";
static NSString * kField_CongressOffice = @"congress_office";
static NSString * kField_BioguideID = @"bioguide_id";
static NSString * kField_VotesmartID = @"votesmart_id";
static NSString * kField_FECID = @"fec_id";
static NSString * kField_GovetrackID = @"govtrack_id";
static NSString * kField_CRPID = @"crp_id";
static NSString * kField_EventfulID = @"eventful_id";
static NSString * kField_CongresspediaURL = @"congresspedia_url";
static NSString * kField_TwitterID = @"twitter_id";
static NSString * kField_YoutubeURL = @"youtube_url";


- (id)init
{
	if ( self = [super init] )
	{
		// initially allocate enough memory for 27 items
		// (the max number of keys provided by sunlightlabs.com)
		m_info = [[NSMutableDictionary alloc] initWithCapacity:27];
		m_filePath = nil;
	}
	
	return self;
}


- (void)dealloc
{
	[m_info release];
	[m_filePath release];
	[super dealloc];
}


// used by parsers (not for general use...)
-(void)addKey:(NSString *)field withValue:(NSString *)value
{
	[m_info setValue:value forKey:field];
}


- (void)initFromFile:(NSString *)path
{
	m_filePath = path;
	m_info = [[NSMutableArray alloc] initWithContentsOfFile:path];
}


- (NSComparisonResult)stateCompare:(LegislatorContainer *)aLegislator
{
	return [[self state] compare:[aLegislator state]];
}


- (NSComparisonResult)partyCompare:(LegislatorContainer *)aLegislator
{
	return [[self party] compare:[aLegislator party]];
}


- (void)writeToStore
{
	if ( nil == m_filePath )
	{
		// XXX - determine file path by key/value pairs in the 'm_info' object
	}
	
	// XXX - write the file!
}


- (NSString *)title
{
	return [m_info objectForKey:kField_Title];
}

- (NSString *)firstname
{
	return [m_info objectForKey:kField_FirstName];
}

- (NSString *)middlename
{
	return [m_info objectForKey:kField_MiddleName];
}

- (NSString *)lastname
{
	return [m_info objectForKey:kField_LastName];
}

- (NSString *)name_suffix
{
	return [m_info objectForKey:kField_NameSuffix];
}

- (NSString *)nickname
{
	return [m_info objectForKey:kField_Nickname];
}

- (NSString *)party
{
	return [m_info objectForKey:kField_Party];
}

- (NSString *)state
{
	return [m_info objectForKey:kField_State];
}

- (NSString *)district
{
	return [m_info objectForKey:kField_District];
}

- (NSString *)in_office
{
	return [m_info objectForKey:kField_InOffice];
}

- (NSString *)gender
{
	return [m_info objectForKey:kField_Gender];
}

- (NSString *)phone
{
	return [m_info objectForKey:kField_Phone];
}

- (NSString *)fax
{
	return [m_info objectForKey:kField_Fax];
}

- (NSString *)website
{
	return [m_info objectForKey:kField_Website];
}

- (NSString *)webform
{
	return [m_info objectForKey:kField_Webform];
}

- (NSString *)email
{
	return [m_info objectForKey:kField_Email];
}

- (NSString *)congress_office
{
	return [m_info objectForKey:kField_CongressOffice];
}

- (NSString *)bioguide_id
{
	return [m_info objectForKey:kField_BioguideID];
}

- (NSString *)votesmart_id
{
	return [m_info objectForKey:kField_VotesmartID];
}

- (NSString *)fec_id
{
	return [m_info objectForKey:kField_FECID];
}

- (NSString *)govtrack_id
{
	return [m_info objectForKey:kField_GovetrackID];
}

- (NSString *)crp_id
{
	return [m_info objectForKey:kField_CRPID];
}

- (NSString *)eventful_id
{
	return [m_info objectForKey:kField_EventfulID];
}

- (NSString *)congresspedia_url
{
	return [m_info objectForKey:kField_CongresspediaURL];
}

- (NSString *)twitter_id
{
	return [m_info objectForKey:kField_TwitterID];
}

- (NSString *)youtube_url
{
	return [m_info objectForKey:kField_YoutubeURL];
}

@end

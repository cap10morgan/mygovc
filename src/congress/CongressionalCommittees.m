//
//  CongressionalCommittees.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "CongressionalCommittees.h"


@implementation CongressionalCommittees


- (id)init
{
	if ( self = [super init] )
	{
	}
	return self;
}


- (void)dealloc
{
	[m_committees release];
	[m_subcommittees release];
	[m_legislativeConnection release];
	[super dealloc];
}


- (void)initCommitteeDataFromFile:(NSString *)path
{
}


- (BOOL)writeCommitteeDataToFile:(NSString *)path
{
	return FALSE;
}


- (void)downloadDataFrom:(NSURL *)url
{
}


- (NSArray *)getCommitteeDataFor:(LegislatorContainer *)legislator
{
	return nil;
}


@end


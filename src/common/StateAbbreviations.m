//
//  StateAbbreviations.m
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "StateAbbreviations.h"

@interface StateAbbreviations (private)
	+ (NSDictionary *)stateDict;
@end


@implementation StateAbbreviations

static NSDictionary *s_states = NULL;
static NSArray *s_sortedStateAbbr = NULL;
static NSArray *s_sortedStateNames = NULL;
static NSArray *s_statesAbbrTableIndexList = NULL;


+ (NSString *)nameFromAbbr:(NSString *)abbr
{
	return [[self stateDict] objectForKey:abbr];
}


+ (NSString *)abbrFromName:(NSString *)name
{
	NSArray *abbrA = [[self stateDict] allKeysForObject:name];
	if ( [abbrA count] > 0 )
	{
		// return the first match...
		return [abbrA objectAtIndex:0];
	}
	else
	{
		return nil;
	}
}


+ (NSArray *)abbrList
{
	if ( NULL == s_sortedStateAbbr )
	{
		s_sortedStateAbbr = [[[[self stateDict] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)] retain];
	}
	return s_sortedStateAbbr;
}


+ (NSArray *)abbrTableIndexList
{
	if ( NULL == s_statesAbbrTableIndexList )
	{
		// 50+ index points is too many - cut it in half by simple
		// NULL-ing out every odd entry title
		NSMutableArray * tmpArray = [[NSMutableArray alloc] initWithArray:[self abbrList]];
		NSUInteger numStates = [tmpArray count];
		
		for ( NSUInteger st = 0; st < numStates; ++st )
		{
			if ( ((st+1) % 2) ) // || !((st+1) % 3) )
			{
				[tmpArray replaceObjectAtIndex:st withObject:[NSString stringWithString:@""] ];
			}
		}
		
		s_statesAbbrTableIndexList = (NSArray *)tmpArray;
	}
	
	return s_statesAbbrTableIndexList;
}


+ (NSArray *)nameList
{
	if ( NULL == s_sortedStateNames )
	{
		// sort the name array using the sorted abbreviation list
		// (so indices will correspond!)
		NSMutableArray *tmpArray = [[NSMutableArray alloc] initWithCapacity:58];
		NSEnumerator *abbrEnum = [[self abbrList] objectEnumerator];
		id abbr;
		while ( (abbr = [abbrEnum nextObject]) )
		{
			[tmpArray addObject:[self nameFromAbbr:abbr]];
		}
		s_sortedStateNames = (NSArray *)tmpArray;
	}
	return s_sortedStateNames;
}


#pragma mark StateAbbreviations Private


+ (NSDictionary *)stateDict
{
	if ( NULL == s_states )
	{
		NSString *statesPath = [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@"USStates.plist"];
		s_states = [[NSDictionary alloc] initWithContentsOfFile:statesPath];
	}
	return s_states;
}


@end

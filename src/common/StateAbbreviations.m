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
	return [[self stateDict] allKeys];
}


+ (NSArray *)nameList
{
	return [[self stateDict] allValues];
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

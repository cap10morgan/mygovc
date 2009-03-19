//
//  StateAbbreviations.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/17/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface StateAbbreviations : NSObject
{}

+ (NSString *)nameFromAbbr:(NSString *)abbr;
+ (NSString *)abbrFromName:(NSString *)name;
+ (NSArray *)abbrList;
+ (NSArray *)abbrTableIndexList; // an array suitable for use as index titles in a TableView
+ (NSArray *)nameList;

@end

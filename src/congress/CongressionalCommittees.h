//
//  CongressionalCommittees.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LegislatorContainer;


@interface LegislativeCommittee : NSObject
{
	NSString *m_id;
	NSString *m_name;
	NSString *m_role;
	NSMutableArray *m_subCommittees; // array of LegislativeCommittee objects
}
@end


@interface CongressionalCommittees : NSObject
{
@private
	NSMutableDictionary *m_committees;    // committeeKey => NSArray: 0->NameString,1...n->Subcommittee keynames
	NSMutableDictionary *m_subcommittees; // subCommitteeKey => NSString: subcommittee name
	
	NSMutableDictionary *m_legislativeConnection; // legislatorID => (sub)committeeKey
}

// initialize committee data from a file
- (void)initCommitteeDataFromFile:(NSString *)path;

// write committe data to a file
- (BOOL)writeCommitteeDataToFile:(NSString *)path;

// downloads congressional XML data from specified source
// and updates internal state
- (void)downloadDataFrom:(NSURL *)url;

// Return an array of LegislativeCommittee objects
- (NSArray *)getCommitteeDataFor:(LegislatorContainer *)legislator;


@end

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
	NSURL *m_url; // website link for this committee
	NSString *m_parentCommittee; // nil for main committees
	NSMutableArray *m_members;
}
@property (nonatomic, retain) NSString *m_id;
@property (nonatomic, retain) NSString *m_name;
@property (nonatomic, retain) NSURL *m_url;
@property (nonatomic, retain) NSString *m_parentCommittee;
@property (readonly) NSMutableArray *m_members;

- (NSComparisonResult)compareCommittee:(LegislativeCommittee *)other;

@end // LegislativeCommittee


@interface CongressionalCommittees : NSObject
{
@private
	NSMutableDictionary *m_committees;    // committeeKey => LegislativeCommittee
	NSMutableDictionary *m_legislativeConnection; // legislatorID => (sub)committeeKey (array)
	NSInteger m_congressSession;
	
	// XML-parsing variables
	BOOL m_parsingCommittees;
	LegislativeCommittee *m_currentCommittee;
	LegislativeCommittee *m_currentSubCommittee;
}

// initialize committee data from a file
- (void)initCommitteeDataFromFile:(NSString *)path;

// write committe data to a file
- (BOOL)writeCommitteeDataToFile:(NSString *)path;

// downloads congressional XML data from specified source
// and updates internal state
- (void)downloadDataFrom:(NSURL *)url forCongressSession:(NSInteger)session;

// retrieve the congress session associated with this committee data
- (NSInteger)congressSession;

// Return an array of LegislativeCommittee objects
- (NSArray *)getCommitteeDataFor:(LegislatorContainer *)legislator;


@end

/*
 File: CongressionalCommittees.h
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

// Retrieve all the legislators in the given committee
- (NSArray *)legislatorsInCommittee:(NSString *)committeeKey;

@end

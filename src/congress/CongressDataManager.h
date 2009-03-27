//
//  CongressDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XMLParserOperation.h"

@class LegislatorContainer;
@class CongressionalCommittees;

@interface CongressDataManager : NSObject <XMLParserOperationDelegate>
{
	BOOL isDataAvailable;
	BOOL isBusy;
	
@private
	BOOL parsingLegislator;
	BOOL storingCharacters;
	NSMutableString *m_currentString;
	LegislatorContainer *m_currentLegislator;
	
	NSMutableArray *m_states;
	NSMutableDictionary *m_house;
	NSMutableDictionary *m_senate;
	
	NSMutableArray *m_searchArray;
	
	CongressionalCommittees *m_committees;
	
	XMLParserOperation *m_xmlParser;
	
	id m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

+ (NSString *)dataCachePath;

- (id)initWithNotifyTarget:(id)target andSelector:(SEL)sel;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

// legislators by state
- (NSArray *)states;
- (NSArray *)houseMembersInState:(NSString *)state;
- (NSArray *)senateMembersInState:(NSString *)state;

// legislator search!
- (void)setSearchString:(NSString *)string;
- (NSArray *)searchResultsArray;

// legislators by district
- (NSArray *)congressionalDistricts;
- (LegislatorContainer *)districtRepresentative:(NSString *)district;

// array of LegislativeCommittee objects
- (NSArray *)legislatorCommittees:(LegislatorContainer *)legislator;

// data cache control
- (void)writeLegislatorDataToCache:(id)sender;
- (void)updateCongressData;


@end

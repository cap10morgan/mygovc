//
//  CongressDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "XMLParserOperation.h"

@class LegislatorContainer;
@class CongressionalCommittees;


typedef enum
{
	eCongressChamberHouse,
	eCongressChamberSenate,
	eCongressSearchResults,
	eCongressCommittee,
} CongressChamber;


@interface CongressDataManager : NSObject <XMLParserOperationDelegate>
{
@private
	BOOL isDataAvailable;
	BOOL isBusy;
	BOOL isAnyDataCached;
	
	BOOL parsingLegislator;
	BOOL storingCharacters;
	NSMutableString *m_currentString;
	LegislatorContainer *m_currentLegislator;
	
	NSMutableArray *m_states;
	NSMutableDictionary *m_house;
	NSMutableDictionary *m_senate;
	
	NSString *m_searchString;
	NSMutableArray *m_searchArray;
	
	NSInteger m_currentCongressSession;
	CongressionalCommittees *m_committees;
	
	XMLParserOperation *m_xmlParser;
	
	NSMutableString *m_currentStatusMessage;
	NSString *m_currentSearchString;
	
	id m_notifyTarget;
	SEL m_notifySelector;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;
@property (readonly) BOOL isAnyDataCached;

+ (NSString *)dataCachePath;

- (id)initWithNotifyTarget:(id)target andSelector:(SEL)sel;

- (void)setNotifyTarget:(id)target withSelector:(SEL)sel;

- (NSString *)currentStatusMessage;

- (NSInteger)currentCongressSession;

// legislators by state
- (NSArray *)states;
- (NSArray *)houseMembersInState:(NSString *)state;
- (NSArray *)senateMembersInState:(NSString *)state;

// legislator search!
- (void)setSearchString:(NSString *)string;
- (void)setSearchLocation:(CLLocation *)loc;
- (NSArray *)searchResultsArray;
- (NSString *)currentSearchString;

// legislator by BioGuide ID
- (LegislatorContainer *)getLegislatorFromBioguideID:(NSString *)bioguideid;

// legislators by district
- (NSArray *)congressionalDistricts;
- (LegislatorContainer *)districtRepresentative:(NSString *)district;

// array of LegislativeCommittee objects
- (NSArray *)legislatorCommittees:(LegislatorContainer *)legislator;

// data cache control
- (void)writeLegislatorDataToCache:(id)sender;
- (void)updateCongressData;


@end

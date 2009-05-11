/*
 File: CongressDataManager.h
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

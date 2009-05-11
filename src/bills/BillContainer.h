/*
 File: BillContainer.h
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

typedef enum
{
	eBillType_unknown,
	eBillType_h,   // house
	eBillType_s,   // senate
	eBillType_hj,  // house joint resolution
	eBillType_sj,  // senate joint resolution
	eBillType_hc,  // house concurrent resolution
	eBillType_sc,  // senate concurrent resolution
	eBillType_hr,  // house resolution 
	eBillType_sr,  // senate resolution
} BillType;


typedef enum
{
	eVote_novote,
	eVote_passed,
	eVote_failed,
} VoteResult;


@interface BillAction : NSObject
{
	NSInteger   m_id;
	NSString   *m_type;
	NSDate     *m_date;
	NSString   *m_descrip;
	VoteResult  m_voteResult;
	NSString   *m_how;
}

@property (nonatomic) NSInteger m_id;
@property (nonatomic,retain) NSString *m_type;
@property (nonatomic,retain) NSDate *m_date;
@property (nonatomic,retain) NSString *m_descrip;
@property (nonatomic) VoteResult m_voteResult;
@property (nonatomic,retain) NSString *m_how;

- (NSString *)shortDescrip;

@end



@interface BillContainer : NSObject 
{
	NSInteger       m_id;
	NSDate         *m_bornOn;
	NSString       *m_title;
	BillType        m_type;
	NSInteger       m_number;
	NSString       *m_status;
	NSString       *m_summary;
	
@private
	NSMutableArray *m_sponsors;   // array of LegislatorContainers!
	NSMutableArray *m_cosponsors; // array of LegislatorContainers!
	
	NSDate         *m_lastActionDate;
	BillAction     *m_lastAction;
	NSMutableArray *m_history; // collection of BillAction objects
}

@property (nonatomic) NSInteger m_id;
@property (nonatomic,retain) NSDate *m_bornOn;
@property (nonatomic,retain) NSString *m_title;
@property (nonatomic) BillType m_type;
@property (nonatomic) NSInteger m_number;
@property (nonatomic,retain) NSString *m_status;
@property (nonatomic,retain) NSString *m_summary;

+ (NSString *)stringFromBillType:(BillType)type;
+ (BillType)billTypeFromString:(NSString *)string;
+ (NSString *)getBillTypeDescrip:(BillType)type;
+ (NSString *)getBillTypeShortDescrip:(BillType)type;

- (NSComparisonResult)lastActionDateCompare:(BillContainer *)that;

- (NSDictionary *)getBillDictionaryForCache;
- (id)initWithDictionary:(NSDictionary *)billData;

- (void)addSponsor:(NSString *)bioguideID;
- (void)addCoSponsor:(NSString *)bioguideID;

- (void)addBillAction:(BillAction *)action;

- (LegislatorContainer *)sponsor;

- (NSArray *)cosponsors;

- (NSString *)summaryText;

- (NSString *)bornOnString;

- (NSDate *)lastActionDate;

- (NSString *)lastActionString;

- (BillAction *)lastBillAction;

- (NSArray *)billActions;

- (NSString *)getIdent;

- (NSString *)getShortTitle;

- (NSURL *)getFullTextURL;

- (NSString *)voteString;

@end


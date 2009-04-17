//
//  BillContainer.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

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

- (void)addSponsor:(NSString *)bioguideID;
- (void)addCoSponsor:(NSString *)bioguideID;

- (void)addBillAction:(BillAction *)action;

- (LegislatorContainer *)sponsor;

- (NSArray *)cosponsors;

- (NSString *)titleNoBillNum;

- (NSString *)bornOnString;

- (NSDate *)lastActionDate;

- (NSString *)lastActionString;

- (BillAction *)lastBillAction;

- (NSArray *)billActions;

- (NSString *)getShortTitle;

- (NSURL *)getFullTextURL;

- (NSString *)voteString;

@end


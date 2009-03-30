//
//  BillContainer.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


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
	eVote_passed,
	eVote_failed,
} VoteResult;


@interface BillAction : NSObject
{
	NSString   *m_type;
	NSDate     *m_date;
	NSString   *m_descrip;
	VoteResult  m_voteResult;
}

@property (nonatomic,retain) NSString *m_type;
@property (nonatomic,retain) NSDate *m_date;
@property (nonatomic,retain) NSString *m_descrip;
@property (nonatomic) VoteResult m_voteResult;

@end



@interface BillContainer : NSObject 
{
	NSString       *m_title;
	BillType        m_type;
	NSInteger       m_number;
	NSString       *m_status;
	
@private
	NSMutableArray *m_sponsors;   // opencongress ID of legislator
	NSMutableArray *m_cosponsors; // opencongress ID of legislator
	
	NSDate         *m_lastActionDate;
	NSMutableArray *m_history; // collection of BillAction objects
}

@property (nonatomic,retain) NSString *m_title;
@property (nonatomic) BillType m_type;
@property (nonatomic) NSInteger m_number;
@property (nonatomic,retain) NSString *m_status;

- (void)addSponsor:(NSString *)openCongressID;
- (void)addCoSponsor:(NSString *)openCongressID;
- (void)addBillAction:(BillAction *)action;
- (NSDate *)lastActionDate;

@end


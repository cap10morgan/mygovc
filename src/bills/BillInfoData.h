//
//  BillInfoData.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class BillContainer;

@interface BillRowData : NSObject
{
	NSString *title;
	NSString *line1;
	NSString *line2;
	NSURL *url;
	SEL action;
}
@property (nonatomic,retain) NSString *title;
@property (nonatomic,retain) NSString *line1;
@property (nonatomic,retain) NSString *line2;
@property (nonatomic,retain) NSURL *url;
@property (nonatomic) SEL action;

- (NSComparisonResult)compareTitle:(BillRowData *)other;

@end


@interface BillInfoData : NSObject 
{
@private
	id m_notifyTarget;
	SEL m_notifySelector;
	
	BillContainer *m_bill;
	
	NSMutableArray *m_data; // Array of Arrays of single-object-dictionaries (fieldname -> value pairs)
	
	id m_actionParent;
}

- (void)setNotifyTarget:(id)target andSelector:(SEL)sel;

- (void)setBill:(BillContainer *)legislator;

- (NSInteger)numberOfSections;

- (NSString *)titleForSection:(NSInteger)section;

- (NSInteger)numberOfRowsInSection:(NSInteger)section;

- (CGFloat)heightForDataAtIndexPath:(NSIndexPath *)indexPath;

//- (void)setInfoCell:(BillInfoCell *)cell forIndex:(NSIndexPath *)indexPath;

- (BillRowData *)billForIndex:(NSIndexPath *)indexPath;

- (void)performActionForIndex:(NSIndexPath *)indexPath withParent:(id)parent;


@end

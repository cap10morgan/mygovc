//
//  LegislatorInfoData.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/14/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
@class LegislatorContainer;
@class LegislatorInfoCell;

@interface LegislatorInfoData : NSObject 
{
@private
	id m_notifyTarget;
	SEL m_notifySelector;
	LegislatorContainer *m_legislator;
	
	NSMutableArray *m_data; // Array of Arrays of single-object-dictionaries (fieldname -> value pairs)
	
	id m_actionParent;
	
	NSOperationQueue *m_opQ;
}


- (void)setNotifyTarget:(id)target andSelector:(SEL)sel;

- (void)setLegislator:(LegislatorContainer *)legislator;

- (NSInteger)numberOfSections;

- (NSString *)titleForSection:(NSInteger)section;

- (NSInteger)numberOfRowsInSection:(NSInteger)section;

- (CGFloat)heightForDataAtIndexPath:(NSIndexPath *)indexPath;

- (void)setInfoCell:(LegislatorInfoCell *)cell forIndex:(NSIndexPath *)indexPath;

- (void)performActionForIndex:(NSIndexPath *)indexPath withParent:(id)parent;

@end

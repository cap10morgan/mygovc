//
//  TableDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TableRowData : NSObject
{
	NSString *title;
	UIColor  *titleColor;
	UIFont   *titleFont;
	UITextAlignment titleAlignment;
	
	NSString *line1;
	UIColor  *line1Color;
	UIFont   *line1Font;
	UITextAlignment line1Alignment;
	
	NSString *line2;
	UIColor  *line2Color;
	UIFont   *line2Font;
	UITextAlignment line2Alignment;
	
	NSURL *url;
	SEL action;
}
@property (nonatomic,retain) NSString *title;
@property (nonatomic,retain) UIColor *titleColor;
@property (nonatomic,retain) UIFont *titleFont;
@property (nonatomic) UITextAlignment titleAlignment;
@property (nonatomic,retain) NSString *line1;
@property (nonatomic,retain) UIColor *line1Color;
@property (nonatomic,retain) UIFont *line1Font;
@property (nonatomic) UITextAlignment line1Alignment;
@property (nonatomic,retain) NSString *line2;
@property (nonatomic,retain) UIColor *line2Color;
@property (nonatomic,retain) UIFont *line2Font;
@property (nonatomic) UITextAlignment line2Alignment;
@property (nonatomic,retain) NSURL *url;
@property (nonatomic) SEL action;

- (NSComparisonResult)compareTitle:(TableRowData *)other;

@end



@interface TableDataManager : NSObject 
{
	id m_notifyTarget;
	SEL m_notifySelector;
	
	// array of section titles to be filled in by a sub-class
	NSMutableArray * m_dataSections;
	
	// Array of Arrays of TableRowData-derived objects
	NSMutableArray *m_data; 
	
	id m_actionParent;
}

- (void)setNotifyTarget:(id)target andSelector:(SEL)sel;

- (NSInteger)numberOfSections;

- (NSString *)titleForSection:(NSInteger)section;

- (NSInteger)numberOfRowsInSection:(NSInteger)section;

- (CGFloat)heightForDataAtIndexPath:(NSIndexPath *)indexPath;

- (id)dataAtIndexPath:(NSIndexPath *)indexPath;

- (void)performActionForIndex:(NSIndexPath *)indexPath withParent:(id)parent;

@end

//
//  CommunityItemView.m
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//  Copyright 2009 U.S. PIRG. All rights reserved.
//

#import "CommunityItemView.h"
#import "CommunityItem.h"


@implementation CommunityItemView

@synthesize communityItem;
@synthesize highlighted;
@synthesize editing;

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.opaque = YES;
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void)setCommunityItem:(CommunityItem *)newCommunityItem {
    if (communityItem != newCommunityItem) {
        [communityItem release];
        communityItem = [newCommunityItem retain];
    }
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
#define LEFT_COLUMN_OFFSET 10
#define LEFT_COLUMN_WIDTH 130
    
#define MIDDLE_COLUMN_OFFSET 140
#define MIDDLE_COLUMN_WIDTH 110
    
#define RIGHT_COLUMN_OFFSET 270
    
#define UPPER_ROW_TOP 8
#define LOWER_ROW_TOP 34
    
#define MAIN_FONT_SIZE 18
#define MIN_MAIN_FONT_SIZE 16
#define SECONDARY_FONT_SIZE 12
#define MIN_SECONDARY_FONT_SIZE 10
    
    // Color and font for the main text items
    UIColor *mainTextColor = nil;
    UIFont *mainFont = [UIFont systemFontOfSize:MAIN_FONT_SIZE];
    
    // Color and font for the secondary text items
    UIColor *secondaryTextColor = nil;
    UIFont *secondaryFont = [UIFont systemFontOfSize:SECONDARY_FONT_SIZE];
    
    // Choose font color based on highlighted state
    if (self.highlighted) {
        mainTextColor = [UIColor whiteColor];
        secondaryTextColor = [UIColor whiteColor];
    } else {
        mainTextColor = [UIColor blackColor];
        secondaryTextColor = [UIColor darkGrayColor];
        self.backgroundColor = [UIColor whiteColor];
    }
    
    CGRect contentRect = self.bounds;
    
    if (!self.editing) {
        CGFloat boundsX = contentRect.origin.x;
        CGPoint point;
        
        //CGFloat actualFontSize;
        //CGSize size;
        
        // Set the color for the main text items
        [mainTextColor set];
        
        // Draw the item label w/ scaling if necessary
        point = CGPointMake(boundsX + LEFT_COLUMN_OFFSET, UPPER_ROW_TOP);
        [communityItem.label drawAtPoint:point forWidth:
            LEFT_COLUMN_WIDTH withFont:mainFont minFontSize:MIN_MAIN_FONT_SIZE
            actualFontSize:NULL lineBreakMode:UILineBreakModeTailTruncation
            baselineAdjustment:UIBaselineAdjustmentAlignBaselines];
        
        // Draw the avatar image
        CGFloat imageY = (contentRect.size.height - communityItem.image.size.height) / 2;
        
        point = CGPointMake(boundsX + RIGHT_COLUMN_OFFSET, imageY);
        [communityItem.image drawAtPoint:point];
    }
}


- (void)dealloc {
    [super dealloc];
}


@end

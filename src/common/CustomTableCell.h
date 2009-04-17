//
//  CustomTableCell.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/16/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TableRowData;

@interface CustomTableCell : UITableViewCell 
{
}

+ (CGFloat) cellHeightForRow:(TableRowData *)rd;

- (void)setRowData:(TableRowData *)rd;

@end

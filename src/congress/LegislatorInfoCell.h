//
//  LegislatorInfoCell.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/7/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LegislatorInfoCell : UITableViewCell 
{
}

+ (CGFloat) cellHeightForText:(NSString *)text;

- (void)setField:(NSString *)field withValue:(NSString *)value;

@end

//
//  LegislatorNameCell.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LegislatorContainer;

@interface LegislatorNameCell : UITableViewCell 
{
}

- (void)setInfoFromLegislator:(LegislatorContainer *)legislator;

@end

//
//  LegislatorHeaderView.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/8/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LegislatorContainer;

@interface LegislatorHeaderView : UIView 
{
	LegislatorContainer *m_legislator;
}

- (void)setLegislator:(LegislatorContainer *)legislator;

@end

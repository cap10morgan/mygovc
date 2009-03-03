//
//  CongressViewController.h
//  myGov
//
//  Created by Jeremy C. Andrus on 2/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CongressDataManager;

typedef enum
{
	eCongressChamberHouse,
	eCongressChamberSenate,
} CongressChamber;

@interface CongressViewController : UITableViewController 
{
	
@private
	CongressDataManager *m_data;
	CongressChamber m_selectedChamber;
}

- (void)dataManagerCallback:(id)dataManager;

@end

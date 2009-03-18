//
//  SpendingDataManager.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/18/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SpendingDataManager : NSObject 
{
	BOOL isDataAvailable;
	BOOL isBusy;
}

@property (readonly) BOOL isDataAvailable;
@property (readonly) BOOL isBusy;

@end

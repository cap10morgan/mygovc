//
//  DataProviders.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 4/15/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LegislatorContainer;

@interface DataProviders : NSObject 
{}

+ (NSString *)OpenCongress_APIKey;
+ (NSString *)OpenCongress_BillsURL;
+ (NSString *)OpenCongress_PersonURL:(LegislatorContainer *)person;

@end

//
//  CommunityItem.m
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//

#import "CommunityItem.h"

static UIImage *tmpImage1;
static UIImage *tmpImage2;

@implementation CommunityItem

@synthesize image;
@synthesize type;
@synthesize label;

+ (void)initialize {
    if (self == [CommunityItem class]) {
        tmpImage1 = [[UIImage imageNamed:@"wes.png"] retain];
        tmpImage2 = [[UIImage imageNamed:@"jeremy.png"] retain];
    }
}

- (id)initWithLabel:(NSString *)_label andType:(NSString *)_type {
    if (self = [super init]) {
        self.label = _label;
        self.type = _type;
    }
    return self;
}

@end

//
//  CommunityItem.h
//  myGovernment
//
//  Created by Wesley Morgan on 2/28/09.
//

#import <Foundation/Foundation.h>


@interface CommunityItem : NSObject {
    UIImage *image;
    NSString *type;
    NSString *label;
}

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSString *type;
@property (nonatomic, retain) NSString *label;

- initWithLabel:(NSString *)_label andType:(NSString *)_type;

@end

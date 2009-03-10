//
//  CommunityViewController.h
//  myGovernment
//
//  Created by Wes Morgan on 2/28/09.
//

#import <UIKit/UIKit.h>


@interface CommunityViewController : UITableViewController {
	NSArray *displayList;
}

@property (nonatomic, retain) NSArray *displayList;

- (void)setupDisplayList;

@end

//
//  LegislatorContainer.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/2/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum
{
	eLegislatorImage_Large = 200,
	eLegislatorImage_Medium = 100,
	eLegislatorImage_Small = 50,
} LegislatorImageSize;

@interface LegislatorContainer : NSObject 
{
@private
	NSMutableDictionary *m_info;
	NSString *m_filePath;
	
	id   m_cbObj;
	SEL  m_imgSel;
	SEL  m_committeeSel;
	BOOL m_downloadInProgress;
}

+ (UIColor *)partyColor:(NSString *)party;

- (id)initFromFile:(NSString *)path;
- (void)writeRecordToFile:(NSString *)path;

- (NSComparisonResult)districtCompare:(LegislatorContainer *)aLegislator;

- (NSString *)title;		// Title held by this legislator, either Sen or Rep
- (NSString *)firstname;	// Legislator's first name
- (NSString *)middlename;	// Legislator's middle name or initial
- (NSString *)lastname;		// Legislator's last name
- (NSString *)name_suffix;	// Legislator's suffix (Jr., III, etc.)
- (NSString *)nickname;		// Preferred nickname of legislator (if any)
- (NSString *)party;		// Legislator's political party (D, I, or R)
- (NSString *)state;		// 2 letter abbreviation of legislator's state
- (NSString *)district;		// If legislator is a representative, their district. 0 is used for At-Large districts
- (NSString *)in_office;	// 1 if legislator is currently serving, 0 if legislator is no longer in office due to defeat/resignation/death/etc.
- (NSString *)gender;		// M or F
- (NSString *)phone;		// Congressional office phone number
- (NSString *)fax;			// Congressional office fax number
- (NSString *)website;		// URL of Congressional website
- (NSString *)webform;		// URL of web contact form
- (NSString *)email;		// Legislator's email address (if known)
- (NSString *)congress_office;	// Legislator's Washington DC Office Address
- (NSString *)bioguide_id;	// Legislator ID assigned by Congressional Biographical Directory (also used by Washington Post/NY Times)
- (NSString *)votesmart_id;	// Legislator ID assigned by Project Vote Smart
- (NSString *)fec_id;		// Federal Election Commission ID
- (NSString *)govtrack_id;	// ID assigned by Govtrack.us
- (NSString *)crp_id;		// ID provided by Center for Responsive Politics
- (NSString *)eventful_id;	// Performer ID on eventful.com
- (NSString *)eventful_url; // Return eventful.com absolute URL
- (NSString *)congresspedia_url;	// URL of Legislator's entry on Congresspedia
- (NSString *)twitter_id;	// Congressperson's official Twitter account
- (NSString *)twitter_url;  // Convert twitter ID to absolute URL
- (NSString *)youtube_url;	// Congressperson's official Youtube account

- (NSString *)shortName;

// congressional committee data:
// returns an array of LegislativeCommittee objects, or nil of no data is present
- (NSArray *)committee_data; 

// search criterion:
// If the legislator's first name, last name or middle name starts with
// the search string passed in, then return true
- (BOOL)isSimilarToo:(NSString *)searchPattern;


// The provided object is used to perform callbacks 
- (void)setCallbackObject:(id)obj;

// return the image of a legislator, optionally blocking until
// it has downloaded. If blockUntilDownloaded is false, and no image
// is currently in the local cache - this function spawns a thread which
// downloads the image for later. If a callback selector is provided, the 
// function will issue a message to the callback object (setCallbackObject)
// with 1 parameter, a UIImage *
- (UIImage *)getImage:(LegislatorImageSize)imgSz andBlock:(BOOL)blockUntilDownloaded withCallbackOrNil:(SEL)sel;

- (BOOL)isDownloadingImage;


// add keys to the dictionary
-(void)addKey:(NSString *)field withValue:(NSString *)value;

@end

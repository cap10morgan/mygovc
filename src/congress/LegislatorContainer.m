/*
 File: LegislatorContainer.m
 Project: myGovernment
 Org: iPhoneFLOSS
 
 Copyright (C) 2009 Jeremy C. Andrus <jeremyandrus@iphonefloss.com>
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 $Id: $
 */

#import "myGovAppDelegate.h"
#import "LegislatorContainer.h"
#import "CongressDataManager.h"

@interface LegislatorContainer (private)
	- (void)downloadImage:(id)sender;
@end


@implementation LegislatorContainer

static NSString * kField_Title = @"title";
static NSString * kField_FirstName = @"firstname";
static NSString * kField_MiddleName = @"middlename";
static NSString * kField_LastName = @"lastname";
static NSString * kField_NameSuffix = @"name_suffix";
static NSString * kField_Nickname = @"nickname";
static NSString * kField_Party = @"party";
static NSString * kField_State = @"state";
static NSString * kField_District = @"district";
static NSString * kField_InOffice = @"in_office";
static NSString * kField_Gender = @"gender";
static NSString * kField_Phone = @"phone";
static NSString * kField_Fax = @"fax";
static NSString * kField_Website = @"website";
static NSString * kField_Webform = @"webform";
static NSString * kField_Email = @"email";
static NSString * kField_CongressOffice = @"congress_office";
static NSString * kField_BioguideID = @"bioguide_id";
static NSString * kField_VotesmartID = @"votesmart_id";
static NSString * kField_FECID = @"fec_id";
static NSString * kField_GovetrackID = @"govtrack_id";
static NSString * kField_CRPID = @"crp_id";
static NSString * kField_EventfulID = @"eventful_id";
static NSString * kField_CongresspediaURL = @"congresspedia_url";
static NSString * kField_TwitterID = @"twitter_id";
static NSString * kField_YoutubeURL = @"youtube_url";


+ (UIColor *)partyColor:(NSString *)party
{
	if ( [party isEqualToString:@"D"] )
	{
		return [UIColor blueColor];
	}
	else if ( [party isEqualToString:@"R"] )
	{
		return [UIColor redColor];
	}
	else
	{
		return [UIColor darkGrayColor];
	}
}


- (id)init
{
	if ( self = [super init] )
	{
		// initially allocate enough memory for 27 items
		// (the max number of keys provided by sunlightlabs.com)
		m_info = [[NSMutableDictionary alloc] initWithCapacity:27];
		m_filePath = nil;
		m_downloadInProgress = NO;
	}
	
	return self;
}


- (void)dealloc
{
	[m_info release];
	[m_filePath release];
	[super dealloc];
}


// used by parsers (not for general use...)
-(void)addKey:(NSString *)field withValue:(NSString *)value
{
	[m_info setValue:value forKey:field];
}


- (id)initFromFile:(NSString *)path
{
	if ( self = [super init] )
	{
		m_downloadInProgress = NO;
		m_filePath = [path retain];
		m_info = [[NSMutableDictionary alloc] initWithContentsOfFile:m_filePath];
	}
	return self;
}


- (void)writeRecordToFile:(NSString *)path
{
	if ( m_info )
	{
		[m_info writeToFile:path atomically:YES];
	}
}


- (NSComparisonResult)districtCompare:(LegislatorContainer *)aLegislator
{
	NSString  *aState = [aLegislator state];
	NSString  *myState = [self state];
	
	NSInteger aDist  = [[aLegislator district] integerValue];
	NSInteger myDist = [[self district] integerValue];
	
	if ( [myState isEqualToString:aState] )
	{
		if ( myDist < aDist ) return NSOrderedAscending;
		if ( myDist > aDist ) return NSOrderedDescending;
	}
	else
	{
		return [myState compare:aState];
	}
	return NSOrderedSame;
}



- (NSString *)title
{
	return [m_info objectForKey:kField_Title];
}

- (NSString *)firstname
{
	return [m_info objectForKey:kField_FirstName];
}

- (NSString *)middlename
{
	return [m_info objectForKey:kField_MiddleName];
}

- (NSString *)lastname
{
	return [m_info objectForKey:kField_LastName];
}

- (NSString *)name_suffix
{
	return [m_info objectForKey:kField_NameSuffix];
}

- (NSString *)nickname
{
	return [m_info objectForKey:kField_Nickname];
}

- (NSString *)party
{
	return [m_info objectForKey:kField_Party];
}

- (NSString *)state
{
	return [m_info objectForKey:kField_State];
}

- (NSString *)district
{
	return [m_info objectForKey:kField_District];
}

- (NSString *)in_office
{
	return [m_info objectForKey:kField_InOffice];
}

- (NSString *)gender
{
	return [m_info objectForKey:kField_Gender];
}

- (NSString *)phone
{
	return [m_info objectForKey:kField_Phone];
}

- (NSString *)fax
{
	return [m_info objectForKey:kField_Fax];
}

- (NSString *)website
{
	return [m_info objectForKey:kField_Website];
}

- (NSString *)webform
{
	return [m_info objectForKey:kField_Webform];
}

- (NSString *)email
{
	return [m_info objectForKey:kField_Email];
}

- (NSString *)congress_office
{
	NSString *office = [m_info objectForKey:kField_CongressOffice];
	NSString *zip;
	if ( [office length] > 0 )
	{
		if ( [[self title] isEqualToString:@"Sen"] )
		{
			zip = @"Washington, DC 20510";
		}
		else
		{
			zip = @"Washington, DC 20515";
		}
		office = [NSString stringWithFormat:@"%@\n%@",office,zip];
	}
	return office;
}


- (NSString *)congress_office_noStateOrZip
{
	return [m_info objectForKey:kField_CongressOffice];
}

- (NSString *)bioguide_id
{
	return [m_info objectForKey:kField_BioguideID];
}

- (NSString *)votesmart_id
{
	return [m_info objectForKey:kField_VotesmartID];
}

- (NSString *)fec_id
{
	return [m_info objectForKey:kField_FECID];
}

- (NSString *)govtrack_id
{
	return [m_info objectForKey:kField_GovetrackID];
}

- (NSString *)crp_id
{
	return [m_info objectForKey:kField_CRPID];
}

- (NSString *)eventful_id
{
	return [m_info objectForKey:kField_EventfulID];
}

- (NSString *)eventful_url
{
	static NSString *kEventfulBaseURLFmt = @"http://eventful.com/performers/%@";
	
	NSString *eid = [self eventful_id];
	if ( [eid length] < 1 ) return nil;
	
	return [NSString stringWithFormat:kEventfulBaseURLFmt,eid];
}

- (NSString *)congresspedia_url
{
	return [m_info objectForKey:kField_CongresspediaURL];
}

- (NSString *)twitter_id
{
	return [m_info objectForKey:kField_TwitterID];
}

- (NSString *)twitter_url
{
	static NSString *kTwitterBaseURLFmt = @"http://twitter.com/%@";
	
	NSString *tid = [self twitter_id];
	if ( [tid length] < 1 ) return nil;
	return [NSString stringWithFormat:kTwitterBaseURLFmt,tid];
}

- (NSString *)youtube_url
{
	return [m_info objectForKey:kField_YoutubeURL];
}


- (NSString *)shortName
{
	NSString *nickname = [self nickname];
	NSString *fname = [self firstname];
	NSString *mname = ([nickname length] > 0 ? @"" : [self middlename]);
	NSString *lname = [self lastname];
	NSString *nm = [[[NSString alloc] initWithFormat:@"%@. %@ %@%@%@",
										[self title],
										([nickname length] > 0 ? nickname : fname),
										(mname ? mname : @""),
										(mname ? @" " : @""),lname
					] autorelease];
	return nm;
}


- (NSArray *)committee_data
{
	return [[myGovAppDelegate sharedCongressData] legislatorCommittees:self];
}


- (BOOL)isSimilarToo:(NSString *)searchPattern
{
	int txtLen = [searchPattern length];
	NSRange searchRange;
	searchRange.location = 0;
	searchRange.length = txtLen;
	
	NSString *fn = [self firstname];
	NSString *ln = [self lastname];
	NSString *mn = [self middlename];
	if ( fn && ([fn length] >= searchRange.length) && 
		 NSOrderedSame == [fn compare:searchPattern options:NSCaseInsensitiveSearch range:searchRange] )
	{
		return TRUE;
	}
	if ( ln && ([ln length] >= searchRange.length) && 
		 NSOrderedSame == [ln compare:searchPattern options:NSCaseInsensitiveSearch range:searchRange] )
	{
		return TRUE;
	}
	if ( mn && ([mn length] >= searchRange.length) && 
		 NSOrderedSame == [mn compare:searchPattern options:NSCaseInsensitiveSearch range:searchRange] )
	{
		return TRUE;
	}
	
	NSString *shortName = [NSString stringWithFormat:@"%@ %@",([self nickname] ? [self nickname] : fn),ln];
	if ( NSOrderedSame == [shortName compare:searchPattern options:NSCaseInsensitiveSearch range:searchRange] )
	{
		return TRUE;
	}
	
	return FALSE;
}


//- (UIImage *)getImageAndBlock:(BOOL)blockUntilDownloaded withCallbackOrNil:(SEL)sel;
- (UIImage *)getImage:(LegislatorImageSize)imgSz andBlock:(BOOL)blockUntilDownloaded withCallbackOrNil:(SEL)sel;
{
	m_imgSel = sel;
	
	// look for photo
	NSString *cache = [[CongressDataManager dataCachePath] stringByAppendingPathComponent:@"photos"];
	NSString *photoPath = [NSString stringWithFormat:@"%@/%@-%dpx.jpeg",cache,[self govtrack_id],imgSz];
	
	UIImage *img = nil;
	
	if ( [[NSFileManager defaultManager] fileExistsAtPath:photoPath] )
	{
		// return an image
		img = [[UIImage alloc] initWithContentsOfFile:photoPath];
		// a nil image will start a new download 
		// (replacing the possibly corrupt one)
	}
	
	if ( nil == img )
	{
		if ( !m_downloadInProgress )
		{
			m_downloadInProgress = YES;
			
			// start image download
			// data is available - read disk data into memory (via a worker thread)
			NSInvocationOperation* theOp = [[NSInvocationOperation alloc] initWithTarget:self
												selector:@selector(downloadImage:) object:self];
		
			// Add the operation to the internal operation queue managed by the application delegate.
			[[[myGovAppDelegate sharedAppDelegate] m_operationQueue] addOperation:theOp];
			
			[theOp release];
		}
		
		if ( blockUntilDownloaded )
		{
			static const int MAX_NUM_SLEEPS = 300; // 30 seconds
			static const CGFloat SLEEP_INTERVAL = 0.1f;
			int numSleeps = 0;
			
			while ( m_downloadInProgress && (numSleeps <= MAX_NUM_SLEEPS) )
			{
				[NSThread sleepForTimeInterval:SLEEP_INTERVAL];
				++numSleeps;
			}
			
			if ( numSleeps > MAX_NUM_SLEEPS ) return nil; // timeout!
			
			// recurse!
			return [self getImage:imgSz andBlock:blockUntilDownloaded withCallbackOrNil:sel];
		}
	}
	
	return img;
}


- (BOOL)isDownloadingImage
{
	return m_downloadInProgress;
}


- (void)setCallbackObject:(id)obj;
{
	[m_cbObj release];
	m_cbObj = [obj retain];
}


- (void)downloadImage:(id)sender
{
	// download the data
	NSString *photoName = [NSString stringWithFormat:@"%@-100px.jpeg",[self govtrack_id]];
	NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.govtrack.us/data/photos/%@",photoName]];
	NSData *imgData = [NSData dataWithContentsOfURL:url];
	UIImage *img = [UIImage imageWithData:imgData];
	
	// save the data to disk
	NSString *cache = [[CongressDataManager dataCachePath] stringByAppendingPathComponent:@"photos"];
	
	// make sure the directory exists!
	[[NSFileManager defaultManager] createDirectoryAtPath:cache withIntermediateDirectories:YES attributes:nil error:NULL];
	
	NSString *photoPath = [cache stringByAppendingPathComponent:photoName];
	
	// don't check the return code - failure here should take care of itself...
	if ( nil != imgData )
	{
		[[NSFileManager defaultManager] createFileAtPath:photoPath contents:imgData attributes:nil];
	}
	
	if ( (nil != m_cbObj) && (nil != m_imgSel) )
	{
		[m_cbObj performSelector:m_imgSel withObject:(nil == imgData ? nil : img)];
	}
	
	m_downloadInProgress = NO;
}


@end

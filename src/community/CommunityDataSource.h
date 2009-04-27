/*
 *  CommunityDataSource.h
 *  myGovernment
 *
 *  Created by Jeremy C. Andrus on 4/26/09.
 *  Copyright 2009 __MyCompanyName__. All rights reserved.
 *
 */
#import "CommunityItem.h"

@class MyGovUser;


/*!
	@brief Protocol used by the CommunityDataSource 
	
	This protocol is used by the CommunityDataSourceProtocol implementation
	to notify the interested party of new data and error conditions.
	
 */
@protocol CommunityDataSourceDelegate
	
	/*!
		Called every time a new CommunityItem object has been downloaded
		and is ready to be passed up the food chain.
	 */
	- (void)communityDataSource:(id)dataSource 
		newCommunityItemArrived:(CommunityItem *)item;
	
	/*!
		Called evey time the data source encounters a new user - it passes
		up the recently encountered user data
	 */
	- (void)communityDataSource:(id)dataSource 
				userDataArrived:(MyGovUser *)user;

	/*!
		Called during a search operaion every time new search results become
		available.
	 */
	- (void)communityDataSource:(id)dataSource 
			searchResultArrived:(CommunityItem *)item;
	
	/*!
		Called by any of the CommunityDataSourceProtocol methods to report
		an error condition
	 */
	- (void)communityDataSource:(id)dataSource 
				 operationError:(NSError *)error;
@end




/*!
	@brief Protocol used by the CommunityDataManager to download / submit community data
	
	This protocol marshals data to/from a data source for the Community Area
	of the myGovernment application. It is intended to hide transport details,
	and use a delegate-callback method for returning results/error-conditions.
	
 */
@protocol CommunityDataSourceProtocol

/*!
	@brief Validate a username/password combo with the data source
	
	This method should retain the username/password combo upon successful
	validation. The retention mechanism is unspecified and left to the 
	data source, but subsequent calls to protocol API methods should use
	the most recent credentials supplied to this function.
	
	@note This method is completely blocking
	
	@param[in] username MyGov username
	@param[in] password MyGov password
	
	@returns TRUE is username/password combo is valid, FALSE otherwise
	
 */
- (BOOL)validateUsername:(NSString *)username 
			 andPassword:(NSString *)password;


/*!
	@brief Attempt to add a new user to the data source
	
	This method attempts to add a new user to the data source. If 
	@c delegateOrNil is non-nil, then the method should use the
	operationError: CommunityDataSourceDelegate method to report any
	error messages (such as username already exists!).
	
	@note This method is completely blocking
	
	@param[in] newUser MyGovUser object to be added to the data source
	@param[in] delegateOrNil object implementing the CommunityDataSourceDelegate protocol (or nil for no callbacks)
	
	@returns TRUE after successfully creating/adding the new user, FALSE otherwise
	
 */
- (BOOL)addNewUser:(MyGovUser *)newUser
	  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil;


/*!
	@brief Blocking data download call 
	
	@par
	This function downloads all community items with the given type which
	were submitted to the data source between @c startDate and @c NOW. The
	@c delegate parameter is optional and may be nil. The caller is 
	responsible for creating / maintaining the thread in which this call
	executes, and thus the protocol implementation need not worry about
	executing in a non-blocking manner - this call is completely blocking.
	
	@par
	This method should call the newCommunityItemArrived: 
	CommunityDataSourceDelegate method for every item received, the 
	userDataArrived: method for every unique myGov user encountered in the 
	set of community items downloaded (including the comments!), and the
	operationError: method to announce any errors that occur in the data
	download operation.
	
	@note This method should also download all relevent user data - the data
	      can be cached locally by the data source, but a call to the userDataArrived:
	      method must still occur for each unique user encountered in the 
	      community item data set.
	
	@param[in] type items of this CommunityItemType are downloaded from the data source
	@param[in] startDate data source items created before this date are @b not downloaded
	@param[in] delegateOrNil object implementing the CommunityDataSourceDelegate protocol (or nil for no callbacks)
	
	@returns @b TRUE on success, @b FALSE otherwise (mostly useful for non-delegate calls)
	
 */
- (BOOL)downloadItemsOfType:(CommunityItemType)type 
			   notOlderThan:(NSDate *)startDate 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil;


/*!
	@brief Community data upload
	
	@par
	This function submits a community item (feedback or event) for upload
	to the data source. Just as in the downloadItemsOfType:... method, the
	protocol implementer may assume that appropriate threading has been 
	managed by the caller and this method can (and should be) completely 
	blocking.
	
	@par
	This method should call the operationError: CommunityDataSourceDelegate
	method on any error that occurs in the upload process.
 
	@note This method is completely blocking
	
	@param[in] item CommunityItem (feedback,event) to submit to the data source
	@param[in] delegateOrNil object implementing the CommunityDataSourceDelegate protocol (or nil for no callbacks)
	
	@returns @b TRUE on success, @b FALSE otherwise (mostly useful for non-delegate calls)
	
 */
- (BOOL)submitCommunityItem:(CommunityItem *)item 
			   withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil;


/*!
	@brief Query the data source for items loosly matching @c query
	
	@par
	This function searches the data source based on a query string. There are
	no arbitrary restriction put on the contents of @c query, so the data source
	should be careful to escape the string as necessary!
	
	@par
	This method should call the searchResultsArrived: 
	CommunityDataSourceDelegate method to report the arrival of a new search
	result, the userDataArrived: method to report user data arrival, and the
	operationError: method to report any errors in the search process.
	
	@note This method is completely blocking
	
	@param[in] type restrict the search to only items of this type
	@param[in] query the free-form search string used to query the data source
	@param[in] delegateOrNil object implementing the CommunityDataSourceDelegate protocol (or nil for no callbacks)
	
	@returns @b TRUE on success, @b FALSE otherwise (mostly useful for non-delegate calls)
	
 */
- (BOOL)searchForItemsWithType:(CommunityItemType)type 
			  usingQueryString:(NSString *)query 
				  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil;


/*!
	@brief Search for items near a particular location
	
	@par
	This function searches the data source for CommunityItems near a particular
	location specified by the @c location parameter. The definition of "nearby"
	has been left vague... 
	
	@par
	This method should call the operationError: CommunityDataSourceDelegate
	method on any error that occurs in the search process.
	
	@note This method is completely blocking
	
	@todo Make the definition of "nearby" less vague!
	
	@param[in] type restrict the search to only items of this type
	@param[in] location Lat/Long coordinates 
	@param[in] delegateOrNil object implementing the CommunityDataSourceDelegate protocol (or nil for no callbacks)
 
	@returns @b TRUE on success, @b FALSE otherwise (mostly useful for non-delegate calls)
	
 */
- (BOOL)searchForItemsWithType:(CommunityItemType)type 
						nearBy:(CLLocation *)location 
				  withDelegate:(id<CommunityDataSourceDelegate>)delegateOrNil;


@end




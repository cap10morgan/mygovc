//
//  XMLParserOperation.h
//  myGovernment
//
//  Created by Jeremy C. Andrus on 3/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class XMLParserOperation;


@protocol XMLParserOperationDelegate
	- (void)xmlParseOpStarted:(XMLParserOperation *)parseOp;
	- (void)xmlParseOp:(XMLParserOperation *)parseOp endedWith:(BOOL)success;
@end


@interface XMLParserOperation : NSObject <XMLParserOperationDelegate>
{
	id m_xmlDelegate;
	NSURL *m_xmlURL;
	
	id m_opDelegate;
	
	BOOL m_finished;
	BOOL m_success;
	
@private
	// private XMLParser variable
	NSXMLParser *m_xmlParser;
}

@property (nonatomic, retain) id m_xmlDelegate;
@property (nonatomic, retain) NSURL *m_xmlURL;
@property (nonatomic, retain) id m_opDelegate;
@property (nonatomic) BOOL m_finished;
@property (nonatomic) BOOL m_success;

- (id)initWithOpDelegate:(id)oDelegate;

- (void)parseXML;
- (void)parseXML: (NSURL *)url;
- (void)parseXML: (NSURL *)url withParserDelegate: (id)pDelegate;

- (void)abort;

@end



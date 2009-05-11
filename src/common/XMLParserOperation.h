/*
 File: XMLParserOperation.h
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
	NSStringEncoding m_strEncoding;
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
- (void)parseXML: (NSURL *)url withParserDelegate: (id)pDelegate withStringEncoding:(NSStringEncoding)encoding;

- (void)abort;

@end



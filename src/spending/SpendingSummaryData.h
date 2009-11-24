/*
 File: SpendingSummaryData.h
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
#import "TableDataManager.h"

@class PlaceSpendingData;
@class ContractorInfo;

@interface SpendingSummaryData : TableDataManager 
{
	PlaceSpendingData *m_placeData;
	ContractorInfo *m_contractorData;
}

- (void)setPlaceData:(PlaceSpendingData *)data;
- (void)setContractorData:(ContractorInfo *)data;

@end
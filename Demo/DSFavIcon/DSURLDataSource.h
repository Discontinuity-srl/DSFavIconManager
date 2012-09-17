//
//  DSUrlDataSoource.h
//  DSFavIcon
//
//  Created by Fabio Pelosin on 17/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSURLDataSource : NSObject

+ (NSArray*)domains;
+ (NSArray*)domainsToSkip;

@end

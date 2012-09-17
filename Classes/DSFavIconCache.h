//
//  DSFavIconCache.h
//  DSFavIcon
//
//  Created by Fabio Pelosin on 06/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "UINSImage.h"

@interface DSFavIconCache : NSCache

@property (nonatomic, retain) NSString *cacheDirectory;

+ (DSFavIconCache *)sharedCache;
- (UINSImage *)imageForKey:(NSString *)key;
- (void)setImage:(UINSImage *)image forKey:(NSString *)key;
- (void)removeAllObjects;

@end

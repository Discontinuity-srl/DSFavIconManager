//
//  DSFavIconCache.h
//  DSFavIcon
//
//  Created by Fabio Pelosin on 06/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DSFavIconCache : NSCache

+ (DSFavIconCache *)sharedCache;
- (UIImage *)imageForKey:(NSString *)key;
- (void)setImage:(UIImage *)image forKey:(NSString *)key;
- (void)removeAllObjects;

@end

//
//  DSFavIconCache.m
//  DSFavIcon
//
//  Created by Fabio Pelosin on 06/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import "DSFavIconCache.h"

@implementation DSFavIconCache {
  dispatch_queue_t _queue;
  NSFileManager *_fileManager;
  NSString *_cacheDirectory;
}

+ (DSFavIconCache *)sharedCache {
  static DSFavIconCache *sharedCache = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
      sharedCache = [DSFavIconCache new];
      });
  return sharedCache;
}

- (id)init
{
  self = [super init];
  if (self) {
    _queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
    _fileManager = [NSFileManager new];
    NSString *cachesDirectory = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    _cacheDirectory = [cachesDirectory stringByAppendingPathComponent:@"/it.discontinuity.favicons"];

    if (![_fileManager fileExistsAtPath:_cacheDirectory]) {
        [_fileManager createDirectoryAtPath:_cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    }
  }
  return self;
}


- (void)removeAllObjects {
  [_fileManager removeItemAtPath:_cacheDirectory error:nil];
  [_fileManager createDirectoryAtPath:_cacheDirectory withIntermediateDirectories:YES attributes:nil error:nil];
  [super removeAllObjects];
}

- (UIImage *)imageForKey:(NSString *)key {
    UIImage *image = [self objectForKey:key];

    if (!image) {
      NSString *path = [self pathForImage:image key:key];
      image = [UIImage imageWithContentsOfFile:path];
      if (image) {
        [self setObject:image forKey:key];
      }
    }
    return image;
}

- (void)setImage:(UIImage *)image forKey:(NSString *)key {
    if (!image || !key) {
        return;
    }

    [self setObject:image forKey:key];

    dispatch_async(_queue, ^{
        NSString *path = [self pathForImage:image key:key];
        [UIImagePNGRepresentation(image) writeToFile:path atomically:YES];
    });
}

#pragma mark - Private Methods

- (NSString *)pathForImage:(UIImage*)image key:(NSString *)key {
  NSString *path = key;
  if (image.scale == 2.0f) {
    path = [key stringByAppendingString:@"@2x"];
  }
  path = [key stringByAppendingString:@".png"];
  return [_cacheDirectory stringByAppendingPathComponent:path];
}

@end

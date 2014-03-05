//
//  DSFavIconCache.m
//  DSFavIcon
//
//  Created by Fabio Pelosin on 06/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import "DSFavIconCache.h"

NSData *UINSImagePNGRepresentation(UINSImage *image);

NSData *UINSImagePNGRepresentation(UINSImage *image) {
#if TARGET_OS_IPHONE
    return UIImagePNGRepresentation(image);

#else
    CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)[image TIFFRepresentation], NULL);
    CGImageRef imageRef =  CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
    CGImageRef copyImageRef = CGImageCreateCopyWithColorSpace (imageRef, CGColorSpaceCreateDeviceRGB());
    if (copyImageRef == NULL) {
        // The color space of the image likely to be indexed.
        CGRect imageRect  = CGRectMake(0, 0, image.size.width, image.size.height);
        NSUInteger width  = CGImageGetWidth(imageRef);
        NSUInteger height = CGImageGetHeight(imageRef);
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
        CGContextRef context = CGBitmapContextCreate(NULL, width, height, 8, width * 4, colorSpace, kCGBitmapByteOrderDefault);
        CGContextDrawImage(context, imageRect, imageRef);
        copyImageRef = CGBitmapContextCreateImage(context);
    }

    NSMutableData *data = [NSMutableData new];
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((__bridge CFMutableDataRef)(data), kUTTypePNG, 1, NULL);
    CGImageDestinationAddImage(destination, copyImageRef, nil);
    CGImageDestinationFinalize(destination);
    
    CFRelease(sourceRef);
    CGImageRelease(imageRef);
    CGImageRelease(copyImageRef);
    return data;
#endif
}


@implementation DSFavIconCache {
    dispatch_queue_t _queue;
    NSFileManager *_fileManager;
}

+ (DSFavIconCache *)sharedCache {
    static DSFavIconCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedCache = [DSFavIconCache new];
    });
    return sharedCache;
}

- (id)init {
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

- (UINSImage *)imageForKey:(NSString *)key {
    UINSImage *image = [self objectForKey:key];
    
    if (!image) {
        NSString *path = [self pathForImage:image key:key];
        image = [[UINSImage alloc] initWithContentsOfFile:path];
        if (image) {
            [self setObject:image forKey:key];
        }
    }
    return image;
}

- (void)setImage:(UINSImage *)image forKey:(NSString *)key {
    if (!image || !key) {
        return;
    }
    
    [self setObject:image forKey:key];
    
    dispatch_async(_queue, ^{
        NSString *path = [self pathForImage:image key:key];
        NSLog(@"%@", path);
        NSData *imageData = UINSImagePNGRepresentation(image);
        if (imageData) {
            [imageData writeToFile:path atomically:NO];
        }
    });
}

#pragma mark - Private Methods

- (NSString *)pathForImage:(UINSImage*)image key:(NSString *)key {
    NSString *path = key;
#if TARGET_OS_IPHONE
    if (image.scale == 2.0f) {
        path = [key stringByAppendingString:@"@2x"];
    }
#endif
    path = [key stringByAppendingString:@".png"];
    return [_cacheDirectory stringByAppendingPathComponent:path];
}

@end
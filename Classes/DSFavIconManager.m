//
//  DSFavIconFinder.m
//  DSFavIcon
//
//  Created by Fabio Pelosin on 04/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import "DSFavIconManager.h"

CGFloat screenScale();
CGSize sizeInPixels(UINSImage *image);

CGFloat screenScale() {
    #if TARGET_OS_IPHONE
        return [UIScreen mainScreen].scale;
    #else
        return [NSScreen mainScreen].backingScaleFactor;
    #endif
}

CGSize sizeInPixels(UINSImage *icon) {
    CGSize size = icon.size;
    #if TARGET_OS_IPHONE
    size.width *= icon.scale;
    size.height *= icon.scale;
    #endif
    return size;
}



@implementation DSFavIconManager {
    NSOperationQueue *_operationQue;
    NSMutableDictionary *_operationsPerURL;
}

#pragma mark - Initialization
+ (DSFavIconManager*)sharedInstance {
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init {
    self = [super init];
    if (self) {
        _cache = [DSFavIconCache sharedCache];

        _operationQue = [[NSOperationQueue alloc] init];
        _operationQue.maxConcurrentOperationCount = 4;
        _operationsPerURL = [NSMutableDictionary new];

        _placeholder = [UINSImage imageNamed:@"favicon"];
        _discardRequestsForIconsWithPendingOperation = false;
        _useAppleTouchIconForHighResolutionDisplays  = false;
    }
    return self;
}


#pragma mark - Public methods

- (void)cancelRequests {
    [_operationQue cancelAllOperations];
    _operationsPerURL = [NSMutableDictionary new];
}

- (void)clearCache {
    [self cancelRequests];
    [_cache removeAllObjects];
}

- (BOOL)hasOperationForURL:(NSURL*)url {
    return [_operationsPerURL objectForKey:url] != nil;
}

- (UINSImage*)cachedIconForURL:(NSURL *)url {
    return [_cache imageForKey:[self keyForURL:url]];
}

- (UINSImage*)iconForURL:(NSURL *)url downloadHandler:(void (^)(UINSImage *icon))downloadHandler {
    UINSImage *cachedImage = [self cachedIconForURL:url];
    if (cachedImage) {
        return cachedImage;
    }

    if (_discardRequestsForIconsWithPendingOperation && [_operationsPerURL objectForKey:url]) {
        return _placeholder;
    }
        DSFavIconOperationCompletionBlock completionBlock = ^(UINSImage *icon) {
            [_operationsPerURL removeObjectForKey:url];
            if (icon) {
                [_cache setImage:icon forKey:[self keyForURL:url]];
                dispatch_async(dispatch_get_main_queue(), ^{
                    downloadHandler(icon);
                });
            }
        };

        DSFavIconOperation *op = [DSFavIconOperation operationWithURL:url
                                                   relationshipsRegex:[self acceptedRelationshipAttributesRegex]
                                                         defaultNames:[self defaultNames]
                                                      completionBlock:completionBlock];

        // Prevent starting an operation for an icon that has been downloaded in the meanwhile.
        op.preFlightBlock = ^BOOL (NSURL *url) {
            UINSImage *icon = [self cachedIconForURL:url];
            if (icon) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    downloadHandler(icon);
                });
                return false;
            } else {
                return true;
            }
        };

        op.acceptanceBlock = ^BOOL (UINSImage *icon) {
            CGSize size = sizeInPixels(icon);
            return size.width >= (16 * screenScale()) && size.height >= (16.f * screenScale());
        };

        [_operationsPerURL setObject:op forKey:url];
        [_operationQue addOperation:op];

    return self.placeholder;
}


#pragma mark - Private methods

- (NSString*)keyForURL:(NSURL *)url {
    return [url host];
}

- (NSArray*)defaultNames {
    if (_useAppleTouchIconForHighResolutionDisplays && screenScale() > 1.f) {
        return @[ @"favicon.ico", @"apple-touch-icon-precomposed.png", @"apple-touch-icon.png", @"touch-icon-iphone.png" ];
    } else {
        return @[ @"favicon.ico" ];
    }
}

- (NSString *)acceptedRelationshipAttributesRegex {
    NSArray *array;
    if (_useAppleTouchIconForHighResolutionDisplays && screenScale() > 1.f) {
        array = @[ @"shortcut icon", @"icon", @"apple-touch-icon" ];
    } else {
        array = @[ @"shortcut icon", @"icon" ];
    }
    return [array componentsJoinedByString:@"|"];
}

@end


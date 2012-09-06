//
//  DSFavIconFinder.m
//  DSFavIcon
//
//  Created by Fabio Pelosin on 04/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import "DSFavIconManager.h"
#import "AFNetworking.h"
#import "DSFavIconCache.h"
#import "DSFavIconOperation.h"

@implementation DSFavIconManager {
    NSOperationQueue *_operationQue;
    NSMutableDictionary *_operationsPerURL;
}
#pragma mark - Initialization
+ (DSFavIconManager*)sharedInstance
{
    static dispatch_once_t once;
    static id sharedInstance;
    dispatch_once(&once, ^{
        sharedInstance = [[self alloc] init];
    });
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    if (self) {
        _operationQue = [[NSOperationQueue alloc] init];
        _operationQue.maxConcurrentOperationCount = 4;
        _operationsPerURL = [NSMutableDictionary new];

        _placehoder = [UIImage imageNamed:@"favicon"];
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

- (void)clearCache
{
    [self cancelRequests];
    [[DSFavIconCache sharedCache] removeAllObjects];
}

- (BOOL)hasOperationForURL:(NSURL*)url {
    return [_operationsPerURL objectForKey:url] != nil;
}

- (UIImage*)cachedIconForURL:(NSURL *)url
{
    return [[DSFavIconCache sharedCache] imageForKey:[self keyForURL:url]];
}

- (UIImage*)iconForURL:(NSURL *)url downloadHandler:(void (^)(UIImage *icon))downloadHandler {

    UIImage *cachedImage = [self cachedIconForURL:url];
    if (cachedImage) {
        return cachedImage;
    }

    if (_discardRequestsForIconsWithPendingOperation && [_operationsPerURL objectForKey:url]) {
        return _placehoder;
    }
        DSFavIconOperationCompletionBlock completionBlock = ^(UIImage *icon) {
            [_operationsPerURL removeObjectForKey:url];
            if (icon) {
                [[DSFavIconCache sharedCache] setImage:icon forKey:[self keyForURL:url]];
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
            UIImage *icon = [self cachedIconForURL:url];
            if (icon) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    downloadHandler(icon);
                });
                return false;
            } else {
                return true;
            }
        };

        op.acceptanceBlock = ^BOOL (UIImage *icon) {
            CGSize size = icon.size;
            BOOL result = (size.width * icon.scale) >= 16 * [UIScreen mainScreen].scale && (size.height * icon.scale) >= 16 * [UIScreen mainScreen].scale;
            return result;
        };

        [_operationsPerURL setObject:op forKey:url];
        [_operationQue addOperation:op];

    return self.placehoder;
}




#pragma mark - Private methods
- (NSString*)keyForURL:(NSURL *)url {
    return [url host];
}

- (NSArray*)defaultNames {
    if (_useAppleTouchIconForHighResolutionDisplays && [UIScreen mainScreen].scale > 1.0) {
        return @[ @"favicon.ico", @"apple-touch-icon-precomposed.png", @"apple-touch-icon.png", @"touch-icon-iphone.png" ];
    } else {
        return @[ @"favicon.ico" ];
    }
}

- (NSString *)acceptedRelationshipAttributesRegex {
    NSArray *array = @[ @"shortcut icon", @"icon" ];
    if (_useAppleTouchIconForHighResolutionDisplays && [UIScreen mainScreen].scale > 1.0) {
        array = @[ @"shortcut icon", @"icon", @"apple-touch-icon" ];
    } else {
        array = @[ @"shortcut icon", @"icon" ];
    }
    return [array componentsJoinedByString:@"|"];
}

@end


//
//  DSFavIconFinder.h
//  DSFavIcon
//
//  Created by Fabio Pelosin on 04/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "UINSImage.h"
#import "DSFavIconOperation.h"
#import "DSFavIconCache.h"

/** DSFavIconManager is a complete solution for managing Favicons.*/
@interface DSFavIconManager : NSObject

/** Returns the shared singleton. */
+ (DSFavIconManager *)sharedInstance;

/** Placeholder image for favicons. Defaults to [UIImage imageNamed:@"favicon"]. */
@property UINSImage *placeholder;

/** The DSFavIconCache instance used by the current manager. 
     Defaults to [DSFavIconCache sharedCache] */
@property DSFavIconCache *cache;


/** Wether requests for the icon of an URL already in the queue should be discarded (useful in tables). Defaults to false. */
@property BOOL discardRequestsForIconsWithPendingOperation;

/** Wether it should attempt to retrieve apple touch icons if the size of the favicon is less than 16 logical points. Defaults to false. */
@property BOOL useAppleTouchIconForHighResolutionDisplays;

/** Returns the image for an icon if it has already been downloaded.
 @param url   The URL for which the icon is requested.
 @return      The icon or nil if the icon is not available in the cache.  */
- (UINSImage*)cachedIconForURL:(NSURL *)url;

/** Returns the image for an icon. If the icon has already been downloaded it is returned immediately.

        UIImageView *imageView;
        imageView.image = [[DSFavIconManager sharedInstance] iconForURL:url completionBlock:^(UIImage *icon) {
            imageView.image = icon;
        }];

 @param url               The URL for which the icon is requested.
 @param downloadHandler   A handler to be called when and only if an icon is downloaded.
                          This handler is always called in the dispatch queue associated with the application’s main thread.
 @return                  The icon if it is already available, otherwise the placeholder image is returned.  */
- (UINSImage*)iconForURL:(NSURL *)url downloadHandler:(void (^)(UINSImage *icon))downloadHandler;

/** Cancels all the pending queues. */
- (void)cancelRequests;

/** Clears the caches (memory and disk) and cancels pending queues. */
- (void)clearCache;

@end

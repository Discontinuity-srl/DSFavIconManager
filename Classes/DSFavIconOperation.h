//
//  DSFavIconOperation.h
//  DSFavIcon
//
//  Created by Fabio Pelosin on 05/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import "UINSImage.h"

typedef void (^DSFavIconOperationCompletionBlock)(UINSImage *icon);
typedef BOOL (^DSFavIconOperationAcceptanceBlock)(UINSImage *icon);
typedef BOOL (^DSFavIconOperationPreflightBlock)(NSURL *url);

extern NSString *const kDSFavIconOperationDidStartNetworkActivity;
extern NSString *const kDSFavIconOperationDidEndNetworkActivity;

@interface DSFavIconOperation : NSOperation

@property NSURL *url;
@property NSArray *defaultNames;
@property NSString *relationshipsRegex;
@property (strong) DSFavIconOperationCompletionBlock completion;
@property (strong) DSFavIconOperationAcceptanceBlock acceptanceBlock;
@property (strong) DSFavIconOperationPreflightBlock  preFlightBlock;

+ (DSFavIconOperation*)operationWithURL:(NSURL*)url
                     relationshipsRegex:(NSString*)relationshipsRegex
                           defaultNames:(NSArray*)defaultNames
                        completionBlock:(DSFavIconOperationCompletionBlock)completion;

@end

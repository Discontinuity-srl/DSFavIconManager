//
//  DSFavIconOperation.m
//  DSFavIcon
//
//  Created by Fabio Pelosin on 05/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import "DSFavIconOperation.h"

NSString *const kDSFavIconOperationDidStartNetworkActivity = @"kDSFavIconOperationDidStartNetworkActivity";
NSString *const kDSFavIconOperationDidEndNetworkActivity   = @"kDSFavIconOperationDidEndNetworkActivity";

@implementation DSFavIconOperation

+ (DSFavIconOperation*)operationWithURL:(NSURL*)url
                     relationshipsRegex:(NSString*)relationshipsRegex
                           defaultNames:(NSArray*)defaultNames
                        completionBlock:(DSFavIconOperationCompletionBlock)completion; {
    DSFavIconOperation* result = [[[self class] alloc] init];
    result.url = url;
    result.relationshipsRegex = relationshipsRegex;
    result.defaultNames = defaultNames;
    result.completion = completion;
    return result;
}

- (BOOL)isIconValid:(UINSImage*)icon {
    if (_acceptanceBlock) {
        return icon != nil && _acceptanceBlock(icon);
    } else {
        return icon != nil;
    }
}

- (void)main {
    if (self.isCancelled) return;

    if (_preFlightBlock) {
        if (!_preFlightBlock(_url)) {
            return;
        }
    }

    UINSImage *icon = [self searchURLForImages:_url withNames:_defaultNames];

    if (![self isIconValid:icon] && !self.isCancelled) {
        NSURLRequest *request = [NSURLRequest requestWithURL:_url];
        NSURLResponse *response;

        [[NSNotificationCenter defaultCenter] postNotificationName:kDSFavIconOperationDidStartNetworkActivity object:self];
        NSData *htmlData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:kDSFavIconOperationDidEndNetworkActivity object:self];

        if (![self isIconValid:icon] && !self.isCancelled) {
            UINSImage *newIcon = [self searchURLForImages:response.URL withNames:_defaultNames];
            if (newIcon) icon = newIcon;
        }
        if (![self isIconValid:icon] && !self.isCancelled) {
            UINSImage *newIcon = [self iconFromHTML:htmlData textEncodingName:response.textEncodingName url:response.URL];
            if (newIcon) icon = newIcon;
        }
    }
    _completion(icon);
}

- (UINSImage*)searchURLForImages:(NSURL *)url withNames:(NSArray *)names {
    __block UINSImage *icon;
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@://%@", [url scheme], [url host]]];
    [names enumerateObjectsUsingBlock:^(NSString *iconName, NSUInteger idx, BOOL *stop) {
        if (!self.isCancelled) {
            NSURL *iconURL = [NSURL URLWithString:iconName relativeToURL:baseURL];

            [[NSNotificationCenter defaultCenter] postNotificationName:kDSFavIconOperationDidStartNetworkActivity object:self];
            NSData *data = [NSData dataWithContentsOfURL:iconURL];
            [[NSNotificationCenter defaultCenter] postNotificationName:kDSFavIconOperationDidEndNetworkActivity object:self];

            UINSImage *newIcon = [[UINSImage alloc] initWithData:data];
            if (newIcon) {
                icon = newIcon;
                *stop = [self isIconValid:icon];
            }
        } else {
            *stop = true;
        }
    }];
    return icon;
};

- (UINSImage*)iconFromHTML:(NSData*)htmlData textEncodingName:(NSString*)textEncodingName url:(NSURL*)url {
    __block NSString *html;
    if (textEncodingName) {
        CFStringEncoding cfencoding = CFStringConvertIANACharSetNameToEncoding((__bridge CFStringRef)textEncodingName);
        NSStringEncoding encoding = CFStringConvertEncodingToNSStringEncoding(cfencoding);
        html = [[NSString alloc] initWithData:htmlData encoding:encoding];
    }
    if (!html) {
        // As the reported encoded might be incorrect we try the common ones if there is not html
        NSArray* encodings = @[
        @(NSUTF8StringEncoding),
        @(NSISOLatin1StringEncoding),
        @(NSUTF16StringEncoding),
        @(NSISOLatin2StringEncoding),
        ];
        [encodings enumerateObjectsUsingBlock:^(NSNumber *encoding, NSUInteger idx, BOOL *stop) {
            html = [[NSString alloc] initWithData:htmlData encoding:[encoding integerValue]];
            *stop = (html != nil);
        }];
    }

    NSString *quotes                      = @"(?:\"|')";
    NSString *rel_pattern                 = [NSString stringWithFormat:@"rel=%@(%@)%@", quotes, _relationshipsRegex, quotes];
    NSString *link_pattern                = [NSString stringWithFormat:@"<link[^>]*%@[^>]*/?>", rel_pattern];
    NSRegularExpression *link_tag_regex   = [NSRegularExpression regularExpressionWithPattern:link_pattern options:NSRegularExpressionCaseInsensitive error:nil];

    __block UINSImage *icon;
    [link_tag_regex enumerateMatchesInString:html options:0 range:NSMakeRange(0, html.length) usingBlock:^(NSTextCheckingResult *link_tag_result, NSMatchingFlags flags, BOOL *stop) {
        if (!self.isCancelled) {
            NSString *link_tag                = [html substringWithRange:link_tag_result.range];
            NSString *href_pattern            = [NSString stringWithFormat:@"href=%@([^\"']*)%@", quotes, quotes];
            NSRegularExpression *href_regex   = [NSRegularExpression regularExpressionWithPattern:href_pattern options:NSRegularExpressionCaseInsensitive error:nil];
            NSTextCheckingResult* href_result = [href_regex firstMatchInString:link_tag options:0 range:NSMakeRange(0, link_tag.length)];
            NSString *href_value = [link_tag substringWithRange:[href_result rangeAtIndex:1]];
            if (href_value) {
                NSURL* iconURL = [NSURL URLWithString:href_value relativeToURL:url];

                [[NSNotificationCenter defaultCenter] postNotificationName:kDSFavIconOperationDidStartNetworkActivity object:self];
                NSData *data = [NSData dataWithContentsOfURL:iconURL];
                [[NSNotificationCenter defaultCenter] postNotificationName:kDSFavIconOperationDidEndNetworkActivity object:self];

                UINSImage *newIcon = [[UINSImage alloc] initWithData:data];
                if (newIcon) {
                    icon = newIcon;
                    *stop = [self isIconValid:icon];
                }
            }
        } else {
            *stop = true;
        }
    }];
    return icon;
}

@end

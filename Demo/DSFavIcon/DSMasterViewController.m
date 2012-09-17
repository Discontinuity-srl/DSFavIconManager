//
//  DSMasterViewController.m
//  DSFavIcon
//
//  Created by Fabio Pelosin on 04/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "DSMasterViewController.h"
#import "DSFaviconManager.h"
#import "AFNetworking.h"
#import "DSURLDataSource.h"


@implementation DSMasterViewController {
    NSMutableArray *_objects;
    NSMutableArray *_domainsWithoutIcon;
}
@synthesize headerLabel;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [AFNetworkActivityIndicatorManager sharedManager].enabled = true;
    [[NSNotificationCenter defaultCenter] addObserverForName:kDSFavIconOperationDidStartNetworkActivity object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
    }];

    [[NSNotificationCenter defaultCenter] addObserverForName:kDSFavIconOperationDidEndNetworkActivity object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
    }];

    [DSFavIconManager sharedInstance].useAppleTouchIconForHighResolutionDisplays = YES;
    [DSFavIconManager sharedInstance].discardRequestsForIconsWithPendingOperation = YES;
    
    _objects = [NSMutableArray new];
    [[DSURLDataSource domains] enumerateObjectsUsingBlock:^(NSString* domain, NSUInteger idx, BOOL *stop) {
        NSURL *url = [NSURL URLWithString:[@"http://" stringByAppendingString:domain] ];
        [_objects addObject:url];
    }];
    _domainsWithoutIcon = [_objects mutableCopy];
    [self updateHeaderLabel];
    NSLog(@"%@", _domainsWithoutIcon);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:NO];
}

- (void)updateHeaderLabel {
    __block NSMutableArray *newDomainsWithoutIcon = [NSMutableArray new];
    [_domainsWithoutIcon enumerateObjectsUsingBlock:^(NSURL* url, NSUInteger idx, BOOL *stop)
     {
         if ([self URLWantsIcon:url] && ![[DSFavIconManager sharedInstance] cachedIconForURL:url]) {
             [newDomainsWithoutIcon addObject:url];
         }
     }];
    _domainsWithoutIcon = newDomainsWithoutIcon;
    self.headerLabel.text = [NSString stringWithFormat:@"Missing Icons: %d/%d (%d disabled)", _domainsWithoutIcon.count, _objects.count, [DSURLDataSource domainsToSkip].count];
}

- (IBAction)clearCache:(id)sender
{
    [[DSFavIconManager sharedInstance] clearCache];
    [self.tableView reloadData];
    _domainsWithoutIcon = [_objects mutableCopy];
    [self updateHeaderLabel];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    NSURL *url = [_objects objectAtIndex:indexPath.row];
    UILabel *textLabel = (UILabel *)[cell viewWithTag:500];
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:501];
    imageView.layer.cornerRadius =  2.0f;

    if ([self URLWantsIcon:url]) {
        textLabel.text = [NSString stringWithFormat:@"%d. %@", indexPath.row + 1, [url absoluteString]];
        imageView.image = [[DSFavIconManager sharedInstance] iconForURL:url downloadHandler:^(UIImage *icon) {
            // This also ensures that the table view returns the cell as now it still has
            // to be returned.
            if (icon) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    UITableViewCell *tableCell = [tableView cellForRowAtIndexPath:indexPath];
                    UIImageView *imageView = (UIImageView *)[tableCell viewWithTag:501];
                    imageView.image = icon;
                    imageView.layer.masksToBounds = (icon.size.width / icon.scale) > 16.0f;
                    [self updateHeaderLabel];
                });
            }
        }];
        imageView.layer.masksToBounds = (imageView.image.size.width / imageView.image.scale) > 16.0f;
    }
    else {
        textLabel.text  = [NSString stringWithFormat:@"%d. [%@]", indexPath.row + 1, [url absoluteString]];
        imageView.image = [DSFavIconManager sharedInstance].placehoder;
    }
    return cell;
}


- (BOOL)URLWantsIcon:(NSURL*)url {
    return ![[DSURLDataSource domainsToSkip] containsObject:[url absoluteString]];
}



@end

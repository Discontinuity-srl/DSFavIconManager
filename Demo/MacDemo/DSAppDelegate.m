//
//  DSAppDelegate.m
//  MacDemo
//
//  Created by Fabio Pelosin on 17/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#import "DSAppDelegate.h"
#import "DSURLDataSource.h"
#import "DSFavIconManager.h"

@implementation DSAppDelegate {
    NSMutableArray *_objects;
    NSMutableArray *_domainsWithoutIcon;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    _objects = [NSMutableArray new];
    [[DSURLDataSource domains] enumerateObjectsUsingBlock:^(NSString* domain, NSUInteger idx, BOOL *stop) {
        NSURL *url = [NSURL URLWithString:[@"http://" stringByAppendingString:domain] ];
        [_objects addObject:url];
    }];
    _domainsWithoutIcon = [_objects mutableCopy];
    [_tableView reloadData];
}

- (void)awakeFromNib {
    [_tableView setDataSource:self];
    [_tableView setDelegate:self];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return _objects.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSURL *url = [_objects objectAtIndex:row];
    NSTableCellView *result = [tableView makeViewWithIdentifier:@"IconView" owner:self];

    result.textField.stringValue = [NSString stringWithFormat:@"%ld. %@", row + 1, [url absoluteString]];
    result.imageView.image = [[DSFavIconManager sharedInstance] iconForURL:url downloadHandler:^(NSImage *icon) {
        // This also ensures that the table view returns the cell as now it still has
        // to be returned.
        if (icon) {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSUInteger columnIndex = [_tableView.tableColumns indexOfObject:tableColumn];
                NSTableCellView *tableCell = [_tableView viewAtColumn:columnIndex row:row makeIfNecessary:NO];
                tableCell.imageView.image = icon;
            });
        }
    }];

    
    return result;
}

- (IBAction)showCachesAction:(id)sender {
    [[NSWorkspace sharedWorkspace] openFile:[DSFavIconManager sharedInstance].cache.cacheDirectory];
}

- (IBAction)clearCache:(id)sender {
    [[DSFavIconManager sharedInstance] clearCache];
    [_tableView reloadData];
}

@end

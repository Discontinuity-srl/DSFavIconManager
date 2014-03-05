DSFavIconManager
================

DSFavIconManager is a complete solution for displaying favicons.

Features:

- Finds and downloads a favicon from an URL.
- Fast and concurrent.
- Cache icons in memory and in disk.
- It doesn't uses a full blown HTML parser.
- Optional fall-back to apple touch icons for retina displays.

Installation
------------

Use [CocoaPods](https://github.com/CocoaPods/CocoaPods):

    pod 'DSFavIconManager'

Usage
-----

![demo](http://i.imgur.com/ejDz0.png)

###### Updating an image view

``` objective-c
UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16.0f, 16.0f)];
imageView.layer.cornerRadius =  2.0f;
imageView.image = [[DSFavIconManager sharedInstance] iconForURL:url completionBlock:^(UIImage *icon) {
    imageView.image = icon;
}];
```


###### Using apple touch icon fall-back for high resolution displays

``` objective-c
[DSFavIconManager sharedInstance].useAppleTouchIconForHighResolutionDisplays = YES;
UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16.0f, 16.0f)];
imageView.layer.cornerRadius =  2.0f;
imageView.image = [[DSFavIconManager sharedInstance] iconForURL:url completionBlock:^(UIImage *icon) {
    imageView.image = icon;
    // Apple touch icons usually are designed for rounded corners.
    imageView.layer.masksToBounds = (icon.size.width / icon.scale) > 16.0f;
}];
```


###### Updating an activity indicator

``` objective-c
[AFNetworkActivityIndicatorManager sharedManager].enabled = true;
[[NSNotificationCenter defaultCenter] addObserverForName:kDSFavIconOperationDidStartNetworkActivity object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    [[AFNetworkActivityIndicatorManager sharedManager] incrementActivityCount];
}];

[[NSNotificationCenter defaultCenter] addObserverForName:kDSFavIconOperationDidEndNetworkActivity object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
    [[AFNetworkActivityIndicatorManager sharedManager] decrementActivityCount];
}];
```

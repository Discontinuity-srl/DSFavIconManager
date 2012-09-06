DSFavIconManager
================

DSFavIconManager is a complete solution for displaying favicons.

Features:

- Download a favicon from the URL.
- Fast and concurrent.
- Cache icons in memory and in disk.
- It doesn't uses a full blown HTML parser.
- Optional fall-back to apple touch icons for retina displays.

Installation
------------

Use [CocoaPods](https://github.com/CocoaPods/CocoaPods):

    pod 'DSGraphicsKit'

Usage
-----

![demo](http://i.imgur.com/ejDz0.png)


```Objective-C
[AFNetworkActivityIndicatorManager sharedManager].enabled = true;
// [DSFavIconManager sharedInstance].useAppleTouchIconForHighResolutionDisplays = YES;

UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 16.0f, 16.0f)];
imageView.layer.cornerRadius =  2.0f;
imageView.image = [[DSFavIconManager sharedInstance] iconForURL:url completionBlock:^(UIImage *icon) {
    imageView.image = icon;
    // imageView.layer.masksToBounds = (icon.size.width / icon.scale) > 16.0f;
}];

// Apple touch icons usually are designed for rounded corners.
// imageView.layer.masksToBounds = (imageView.image.size.width / imageView.image.scale) > 16.0f;

```



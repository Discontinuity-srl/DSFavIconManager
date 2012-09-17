//
//  UINSImage.h
//  DSFavIcon
//
//  Created by Fabio Pelosin on 17/09/12.
//  Copyright (c) 2012 Discontinuity s.r.l. All rights reserved.
//

#ifndef DSFavIcon_UINSImage_h
#define DSFavIcon_UINSImage_h

#if TARGET_OS_IPHONE
  #import <UIKit/UIKit.h>
  #define UINSImage   UIImage
  #define UINSScreen  UIScreen
#else
  #import <Cocoa/Cocoa.h>
  #define UINSImage   NSImage
  #define UINSScreen  NSScreen
#endif

#endif

//
//  RCTHoxelViewManager.m
//  Hoxel
//
//  Created by H. Cole Wiley on 3/16/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import "RCTHoxelViewManager.h"
#import "HoxelView.h"


@implementation RCTHoxelViewManager

RCT_EXPORT_MODULE()
RCT_EXPORT_VIEW_PROPERTY(viewerMode, NSString);
RCT_EXPORT_VIEW_PROPERTY(sourceDirectory, NSString);
RCT_EXPORT_VIEW_PROPERTY(loop, BOOL);
RCT_EXPORT_VIEW_PROPERTY(frameIndex, int);

- (UIView *)view
{
  return [HoxelView new];
}

@end

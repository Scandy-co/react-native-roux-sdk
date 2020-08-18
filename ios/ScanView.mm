//
//  ScanView.m
//  Hoxel
//
//  Created by H. Cole Wiley on 12/7/18.
//  Copyright © 2018 Scandy. All rights reserved.
//

#include <scandy/core/IScandyCore.h>

#import "ScanView.h"

@implementation ScanView

- (void)setRendererBackgroundColor
{
  double color2[3] = { 0.1, 0.1, 0.1 };
  double color1[3] = { 0.0, 0.0, 0.0 };
  [self setRendererBackgroundColor:color1:color2:true];
}

- (void)setRendererBackgroundColor:(double*)
                            color1:(double*)color2
                                  :(bool)enableGradient
{
  if (ScandyCoreManager.scandyCorePtr->getVisualizer() != nullptr &&
      !ScandyCoreManager.scandyCorePtr->getVisualizer()
         ->getViewports()
         .empty()) {
    for (auto viewport :
         ScandyCoreManager.scandyCorePtr->getVisualizer()->getViewports()) {
      viewport->renderer()->SetGradientBackground(enableGradient);
      if (color1 != nullptr) {
        viewport->renderer()->SetBackground(color1);
      }
      if (color2 != nullptr) {
        viewport->renderer()->SetBackground2(color2);
      }
    }
    [self render];
  }
}


@end

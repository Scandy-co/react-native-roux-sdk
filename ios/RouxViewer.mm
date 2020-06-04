//
//  RouxViewer.m
//  RouxSdk
//
//  Created by George Farro on 6/2/20.
//  Copyright © 2020 Facebook. All rights reserved.
//


#include <scandy/core/IScandyCore.h>

#import "RouxViewer.h"

@implementation RouxViewer

-(instancetype) initWithContext:(EAGLContext *) context
{
  if (self = [super init]) {
    // Needed to ensure that rotations look smooth
    self.contentMode = UIViewContentModeCenter;
    self.context = context;
    // Have ScandyCoreView create our visualizer
    [self createVisualizer];
  }
  return self;
}

- (void) dealloc {
#if !__has_feature(objc_arc)
  [super dealloc];
#else
  // Using ARC, no dealloc needed
#endif
}

- (void)removeFromSuperview
{
  [self shutdown];
  
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [super removeFromSuperview];
}

- (void)shutdown {
  [super stopRenderLoop];
  auto _shutdown = ^{
    [ScandyCoreManager uninitializeScanner];
    ScandyCoreManager.scandyCorePtr->clearVisualizer();
#if !__has_feature(objc_arc)
    [self.context release];
#else
    // Using ARC, no release needed needed
#endif
    [self deleteDrawable];
    [EAGLContext setCurrentContext:nil];
  };
  if( [NSThread isMainThread] ){
    _shutdown();
  } else {
    dispatch_sync( dispatch_get_main_queue(), _shutdown);
  }
}

- (void)setRendererBackgroundColor {
  double color2[3] = {0.1,0.1,0.1};
  double color1[3] = {0.0,0.0,0.0};
  [self setRendererBackgroundColor:color1 :color2 :true];
}

- (void)setRendererBackgroundColor
:(double*) color1
:(double*) color2
:(bool) enableGradient
{
  if( ScandyCoreManager.scandyCorePtr->getVisualizer() != nullptr && !ScandyCoreManager.scandyCorePtr->getVisualizer()->getViewports().empty() ){
    for( auto viewport : ScandyCoreManager.scandyCorePtr->getVisualizer()->getViewports() ){
      viewport->renderer()->SetGradientBackground(enableGradient);
      if( color1 != nullptr ){
        viewport->renderer()->SetBackground(color1);
      }
      if( color2 != nullptr ){
        viewport->renderer()->SetBackground2(color2);
      }
    }
    [self render];
  }
}

@end

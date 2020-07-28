/****************************************************************************\
 * Copyright (C) 2014-2020 Scandy
 *
 * THIS CODE AND INFORMATION ARE PROVIDED "AS IS" WITHOUT WARRANTY OF ANY
 * KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A
 * PARTICULAR PURPOSE.
 *
 \****************************************************************************/

#include <scandy.h>

#include <scandy/utilities/eigen_vector_math.h>

#include <scandy/core/IScandyCore.h>
#include <scandy/core/Status.h>
#include <scandy/core/visualizer/MeshViewport.h>

// import must come second

#import "ScanView.h"
#import "RCTScandyCoreView.h"

#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/RCTUIManagerUtils.h>
#import <React/UIView+React.h>
#import <ScandyCore/ScandyCore.h>
#import <ScandyCore/ScandyCoreManager.h>

@interface
RCTScandyCoreView ()<ScandyCoreDelegate>

@property (nonatomic, strong) ScanView* scanView;
@property (nonatomic, strong) NSString* licenseString;
@property (nonatomic) bool isTracking;
@property (nonatomic) float trackingCost;

@end

@implementation RCTScandyCoreView

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();
RCT_EXPORT_VIEW_PROPERTY(onPreviewStart, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onScannerStart, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onScannerReady, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onScannerStop, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onGenerateMesh, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onSaveMesh, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onLoadMesh, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onExportVolumetricVideo, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onClientConnected, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onHostDiscovered, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onVisualizerReady, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onVolumeMemoryDidUpdate, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onTrackingDidUpdate, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(scanMode, BOOL);
RCT_EXPORT_VIEW_PROPERTY(kind, NSString);

- (dispatch_queue_t)methodQueue
{
  return RCTGetUIManagerQueue();
}

- (NSString*)formatScanStateToString:(scandy::core::ScanState)scanState
{
  return [NSString stringWithFormat:@"%s", scandy::core::getScanStateString(scanState).c_str()];
}

- (NSString*)formatStatusError:(scandy::core::Status)status
{
  return [NSString stringWithFormat:@"%s", scandy::core::getStatusString(status).c_str()];
}

- (void)onVisualizerReady:(bool)createdVisualizer
{
  // NSLog(@"onVisualizerReady, created %@", createdVisualizer ? @"YES" : @"NO");
  // NOTE: we can't use this because it gets called back before we finish
  // setting self.scanView = [ScanView init] and therefor we have no
  // self.scanView
  dispatch_after(
    dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)),
    dispatch_get_main_queue(),
    ^{
      if (self.scanView) {
        if (createdVisualizer) {
          if (self.scanView.onVisualizerReady) {
            self.scanView.onVisualizerReady(@{
              @"createdVisualizer" : [NSNumber numberWithBool:createdVisualizer]
            });
          }
        } else {
          [self.scanView resizeView];
        }
      }
    });
}
- (void)onPreviewStart:(scandy::core::Status)status
{
  if (self.scanView.onPreviewStart) {
    self.scanView.onPreviewStart(@{
      @"success" :
        [NSNumber numberWithBool:(status == scandy::core::Status::SUCCESS)],
      @"status" : [self formatStatusError:status]
    });
  }
}
- (void)onScannerStart:(scandy::core::Status)status
{
  if (self.scanView.onScannerStart) {
    self.scanView.onScannerStart(@{
      @"success" :
        [NSNumber numberWithBool:(status == scandy::core::Status::SUCCESS)],
      @"status" : [self formatStatusError:status]
    });
  }
}

- (void)onScannerReady:(scandy::core::Status)status
{
   NSLog(@"onScannerReady");

  if (self.scanView.onScannerReady) {
    self.scanView.onScannerReady(@{
      @"success" :
        [NSNumber numberWithBool:(status == scandy::core::Status::SUCCESS)],
      @"status" : [self formatStatusError:status]
    });
  }
}

- (void)onScannerStop:(scandy::core::Status)status
{
  //  NSLog(@"onScannerStop");

  if (self.scanView.onScannerStop) {
    self.scanView.onScannerStop(@{
      @"success" :
        [NSNumber numberWithBool:(status == scandy::core::Status::SUCCESS)],
      @"status" : [self formatStatusError:status]
    });
  }
}

- (void)onSaveMesh:(scandy::core::Status)status
{
  //  NSLog(@"onSaveMesh");

  if (self.scanView.onSaveMesh) {
    self.scanView.onSaveMesh(@{
      @"success" :
        [NSNumber numberWithBool:(status == scandy::core::Status::SUCCESS)],
      @"status" : [self formatStatusError:status]
    });
  }
}

- (void)onGenerateMesh:(scandy::core::Status)status
{
  //  NSLog(@"onGenerateMesh");

  if (self.scanView.onGenerateMesh) {
    self.scanView.onGenerateMesh(@{
      @"success" :
        [NSNumber numberWithBool:(status == scandy::core::Status::SUCCESS)],
      @"status" : [self formatStatusError:status]
    });
  }
}

- (void)onHostDiscovered:(NSString*)host
{
  //  NSLog(@"onHostDiscovered: %@", host);
  if (self.scanView.onHostDiscovered) {
    self.scanView.onHostDiscovered(@{ @"host" : host });
  }
}

//This doesn't seem to be working right now - never gets triggered
- (void)onClientConnected:(NSString*)host
{
  //  NSLog(@"onClientConnected: %@", host);
  if (self.scanView.onClientConnected) {
    self.scanView.onClientConnected(@{ @"host" : host });
  }
}

//Doesn't seem to work - always returns 0.00
- (void)onVolumeMemoryDidUpdate:(const float)percent_full
{
  //  NSLog(@"onVolumeMemoryDidUpdate");
  if (self.scanView.onVolumeMemoryDidUpdate) {
    NSString* percent_string =
      [NSString stringWithFormat:@"%.02f", percent_full];
    self.scanView.onVolumeMemoryDidUpdate(
      @{ @"percent_full" : percent_string });
  }
}

- (void)onTrackingDidUpdate:(float)confidence withTracking:(bool)is_tracking
{
  self.isTracking = is_tracking;
  self.trackingCost = confidence;
  if (is_tracking) {
  } else {
  }
}

- (void)onLoadMesh:(scandy::core::Status)status
{
  //  NSLog(@"onSaveMesh");
  if (self.scanView.onLoadMesh) {
    self.scanView.onLoadMesh(@{
      @"success" :
        [NSNumber numberWithBool:(status == scandy::core::Status::SUCCESS)],
      @"status" : [self formatStatusError:status]
    });
  }
}

- (UIView*)view
{
  [ScandyCore setDelegate:self];
  if( self.scanView ) {
    [self.scanView removeFromSuperview];
    self.scanView = nil;
  }
  // Always setup a new ScandView so nothing is wonky or stale
  self.scanView = [ScanView new];

  return self.scanView;
}

- (void)renderScanView
{
  if (self.scanView) {
    [self.scanView render];
  }
}

RCT_EXPORT_METHOD(render)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    [self renderScanView];
  });
}

@end

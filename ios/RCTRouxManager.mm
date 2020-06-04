//
//  RCTRouxManager.m
//  RouxSdk
//
//  Created by George Farro on 6/2/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

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
#include <scandy/utilities/FileOps.h>
#include <scandy/utilities/eigen_vector_math.h>
#include <scandy/core/IScandyCore.h>
#include <scandy/core/Status.h>

#import "RCTRouxManager.h"
#import "RouxViewer.h"

#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/UIView+React.h>

#import <ScandyCore/ScandyCore.h>
#import <ScandyCore/ScandyCoreManager.h>

using namespace scandy::utilities;

@interface
RCTRouxManager ()<ScandyCoreManagerDelegate>

@property (nonatomic, strong) EAGLContext* context;
@property (nonatomic, strong) NSString* licenseString;
@property (nonatomic) scandy::core::ScannerType scannerType;
@property (nonatomic, strong) RouxViewer* scanView;
@property (nonatomic) bool isTracking;
@property (nonatomic) float trackingCost;
@property (nonatomic, assign, getter=isSessionPaused) BOOL paused;
@property (nonatomic) bool isScreenRecording;
@property (nonatomic) int screenRecordCount;
@property (nonatomic) std::vector<std::string> screen_record_images;

@end

@implementation RCTRouxManager
RCTBridge* _bridge;

RCT_EXPORT_MODULE(ScandyCoreManager);
RCT_EXPORT_VIEW_PROPERTY(onPreviewStart, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onScannerStart, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onScannerStop, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onGenerateMesh, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onSaveMesh, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onClientConnected, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onHostDiscovered, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onVisualizerReady, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onVolumeMemoryDidUpdate, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(onVidSavedToCamRoll, RCTBubblingEventBlock);
RCT_EXPORT_VIEW_PROPERTY(scanMode, BOOL);
RCT_EXPORT_VIEW_PROPERTY(kind, NSString);

- (NSString*)formatStatusError:(scandy::core::Status)status
{
  NSString* reason = [[NSString alloc]
    initWithFormat:@"%s", scandy::core::getStatusString(status).c_str()];
#if !__has_feature(objc_arc)
  [reason autorelease];
#else
  // Using ARC, no dealloc needed
#endif
  return reason;
}

+ (BOOL)requiresMainQueueSetup
{
  return YES;
}

- (void)setBridge:(RCTBridge*)bridge
{
  _bridge = bridge;
  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(bridgeDidForeground:)
           name:@"BridgeDidForegroundNotification"
         object:self.bridge];

  [[NSNotificationCenter defaultCenter]
    addObserver:self
       selector:@selector(bridgeDidBackground:)
           name:@"BridgeDidBackgroundNotification"
         object:self.bridge];
}
- (void)bridgeDidForeground:(NSNotification*)notification
{

  if ([self isSessionPaused]) {
    self.paused = NO;
    [ScandyCoreManager.scandyCameraDelegate
      startCamera:AVCaptureDevicePositionFront];
  }
}

- (void)bridgeDidBackground:(NSNotification*)notification
{
  [self pauseAV];
}

- (void)pauseAV
{
  if (![self isSessionPaused]) {
    self.paused = YES;
    [ScandyCoreManager.scandyCameraDelegate stopCamera];
    //    [self.scanView shutdown];
  }
}


+ (void)setLicense
{
  [ScandyCore setLicense];
}

RCT_EXPORT_METHOD(initializeScanner: (RCTPromiseResolveBlock)resolve rejecter: (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    auto slam_config = ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();
    // self resetDefaults e
    [self initializeScanner];
    bool inited = scandy::core::ScanState::INITIALIZED ==
                  ScandyCoreManager.scandyCorePtr->getScanState();
    if (inited) {
      return resolve(nil);
    } else {
      return reject(@"-1", @"Could not initialize scanner", nil);
    }
  });
}


@end

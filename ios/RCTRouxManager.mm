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

RCT_EXPORT_MODULE(RouxManager);

+ (void)setLicense
{
  [ScandyCore setLicense];
}

- (void)initializeScanner
{
  auto _initializeScanner = ^{
    [RCTScandyCoreManager setLicense];

    // Let's get the scanner fired up
    bool hasTrueDepth = [ScandyCoreManager hasTrueDepth];
    auto slam_config =
      ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();
    auto scannerType = scandy::core::ScannerType::TRUE_DEPTH;

    // Make sure to reset all of these
    slam_config->m_preview_mode = true;
    slam_config->m_send_network_commands = false;
    slam_config->m_receive_rendered_stream = false;
    slam_config->m_send_rendered_stream = false;
    slam_config->m_receive_network_commands = false;
    slam_config->m_use_unbounded = false;

    // Lets do this!!!!!
    slam_config->m_use_texturing = true;

    auto status = [ScandyCoreManager initializeScanner:scannerType];
    ScandyCoreManager.scandyCorePtr->setBoundingBoxOffset(0.20);
    ScandyCoreManager.scandyCorePtr->setScanSize(0.7);

    slam_config->m_valid_depth_distance_ratio_thresh = 0.015f;
    slam_config->m_valid_depth_neighbor_count_thresh = 3;
    // Be generous
    slam_config->m_valid_depth_distance_ratio_thresh = 0.015f;
    slam_config->m_valid_depth_neighbor_count_thresh = 1;
    slam_config->m_tsdf_mu_ratio = 0.025f;
  };
  if ([NSThread isMainThread]) {
    _initializeScanner();
  } else {
    dispatch_async(dispatch_get_main_queue(), _initializeScanner);
  }
}

- (void)startPreview
{
  auto _startPreview = ^{
    // Make sure no on has taken our delegate...

    [ScandyCoreManager setScandyCoreDelegate:self];
    auto slam_config =
      ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();
    // Make sure we get a fresh dir
    if (slam_config->m_enable_volumetric_video_recording) {
      // Make the directory where this recording will live
      {
        NSString* dirName =
          [NSString stringWithFormat:@"tmp"];

        NSArray* paths = NSSearchPathForDirectoriesInDomains(
          NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* documentsDirectory = [paths objectAtIndex:0];
        NSString* dirPath =
          [documentsDirectory stringByAppendingPathComponent:dirName];

        slam_config->m_scan_dir_path = [dirPath UTF8String];
      }
    }

    auto status = [ScandyCoreManager startPreview];
    NSLog(@"startPreview");
  };
  if ([NSThread isMainThread]) {
    _startPreview();
  } else {
    dispatch_async(dispatch_get_main_queue(), _startPreview);
  }
}

RCT_EXPORT_METHOD(initializeScanner
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{

  dispatch_async(dispatch_get_main_queue(), ^{
    auto slam_config =
      ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();
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

RCT_EXPORT_METHOD(initializeVolumetricCapture
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    auto scandyCoreConfig =
      ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();
    ScandyCoreManager.scandyCorePtr->clearCommandHosts();

    scandyCoreConfig->m_enable_volumetric_video_streaming = false;
    scandyCoreConfig->m_enable_volumetric_video_recording = true;

    [self initializeScanner];
    bool inited = ScandyCoreManager.scandyCorePtr->getScanState() ==
                  scandy::core::ScanState::INITIALIZED;
    if (inited) {
      resolve(@{
        @"success" : [NSNumber numberWithBool:inited],
      });
    } else {
      reject(nil, nil, nil);
    }
  });
}

RCT_EXPORT_METHOD(uninitializeScanner
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  ScandyCoreManager.scandyCorePtr->uninitializeScanner();
  resolve(nil);
}

RCT_EXPORT_METHOD(reinitializeScanner
                  : (NSDictionary*)props resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{

  dispatch_async(dispatch_get_main_queue(), ^{
    ScandyCoreManager.scandyCorePtr->stopPipeline();
    ScandyCoreManager.scandyCorePtr->uninitializeScanner();

    // Set ScandyCore into Server or Client mode depending on whether its an
    // iPhoneX
    auto slam_config =
      ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();
    //    NSLog(@"props for reinit: %@", props);

    ScandyCoreManager.scandyCorePtr->clearCommandHosts();

    // Make sure to reset all of these
    slam_config->m_preview_mode = true;
    slam_config->m_send_network_commands = false;
    slam_config->m_receive_rendered_stream = false;
    slam_config->m_send_rendered_stream = false;
    slam_config->m_receive_network_commands = false;
    slam_config->m_enable_volumetric_video_streaming = false;
    slam_config->m_enable_volumetric_video_recording = true;

    // If you receive the rendered stream, then you should send commands via
    // network
    if ([[props objectForKey:@"networkReceiver"] intValue] == 1) {
      slam_config->m_send_network_commands = true;
      slam_config->m_receive_rendered_stream = true;
    }

    // If you send the rendered stream, then you should receive commands via
    // network
    if ([[props objectForKey:@"networkSender"] intValue] == 1) {
      slam_config->m_send_rendered_stream = true;
      slam_config->m_receive_network_commands = true;
    }

    if ([props objectForKey:@"networkServerHost"]) {
      NSString* host = [props objectForKey:@"networkServerHost"];
      // Make sure its a legit host
      if (host && host.length > 5) {
        slam_config->m_server_host = std::string([host UTF8String]);
        slam_config->m_enable_volumetric_video_streaming = true;
        slam_config->m_enable_volumetric_video_recording = false;
      } else {
        slam_config->m_server_host = "127.0.0.1";
        slam_config->m_enable_volumetric_video_streaming = false;
        slam_config->m_enable_volumetric_video_recording = true;
      }
    }

    [self initializeScanner];
    bool inited = ScandyCoreManager.scandyCorePtr->getScanState() ==
                  scandy::core::ScanState::INITIALIZED;
    if (inited) {
      resolve(@{
        @"success" : [NSNumber numberWithBool:inited],
      });
    } else {
      reject(nil, nil, nil);
    }
  });
}

RCT_EXPORT_METHOD(startPreview
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    // No sleeping while scanning please
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    [self startPreview];
    auto state = ScandyCoreManager.scandyCorePtr->getScanState();
    if (state == scandy::core::ScanState::PREVIEWING) {
      resolve(nil);
    } else {
      NSString* msg = [NSString
        stringWithFormat:@"Could not start preview. ScandyCore state: %@",
                         [ScandyCoreManager formatScanStateToString:state]];
      reject(@"-1", msg, nil);
    }
  });
}

RCT_EXPORT_METHOD(startRecording
                  : (NSString*)output_dir resolve
                  : (RCTPromiseResolveBlock)resolve reject
                  : (RCTPromiseRejectBlock)reject)
{
  auto slam_config =
    ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();

  // If we are recording, make sure to update the output dir
  if (slam_config->m_enable_volumetric_video_recording) {
    slam_config->m_scan_dir_path = output_dir.UTF8String;
    FileOps::EnsureDirectory(slam_config->m_scan_dir_path);
  }
  slam_config->m_preview_mode = false;
}

RCT_EXPORT_METHOD(stopScan
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    // And now the screen can go to sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    auto stopStatus = [ScandyCoreManager stopScanning];
    if (stopStatus == scandy::core::Status::SUCCESS) {
      return resolve(nil);
    } else {
      auto reason = [[NSString alloc]
        initWithFormat:@"%s",
                       scandy::core::getStatusString(stopStatus).c_str()];
      return reject(reason, reason, nil);
    }
  });
}

RCT_EXPORT_METHOD(getResolutions
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    scandy::core::ScanResolution max_resolution;
    auto scan_resolutions =
      ScandyCoreManager.scandyCorePtr->getAvailableScanResolutions();
    id resolutions = [NSMutableArray new];
    for (auto scan_resolution : scan_resolutions) {

      [resolutions addObject:@{
        @"description" :
          [NSString stringWithUTF8String:scan_resolution.description.c_str()],
        @"id" : [NSNumber numberWithInteger:scan_resolution.id],
        @"resolution" :
          [NSNumber numberWithInteger:scan_resolution.resolution.x],
      }];
    }
    resolve(@{ @"resolutions" : resolutions });
  });
}

RCT_EXPORT_METHOD(setResolution
                  : (NSDictionary*)dict resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    scandy::core::ScanResolution res;
    res.id = [dict[@"id"] intValue];
    auto status = ScandyCoreManager.scandyCorePtr->setResolution(res);

    if (status == scandy::core::Status::SUCCESS) {
      return resolve(nil);
    } else {
      auto reason = [[NSString alloc]
        initWithFormat:@"%s", scandy::core::getStatusString(status).c_str()];
      return reject(reason, reason, nil);
    }
  });
}

RCT_EXPORT_METHOD(setSize
                  : (float)size resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  auto status = ScandyCoreManager.scandyCorePtr->setScanSize(size);
  if (status == scandy::core::Status::SUCCESS) {
    resolve(nil);
  } else {
    auto reason = [[NSString alloc]
      initWithFormat:@"%s", scandy::core::getStatusString(status).c_str()];
    return reject(reason, reason, nil);
  }
}

RCT_EXPORT_METHOD(exportVolumetricVideo
                  : (NSDictionary*)props resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  [RCTScandyCoreManager setLicense];
  auto slam_config =
    ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();
  // Do this on a seperate thread so we can still render during it
  dispatch_async(
    dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
      std::string dirPath;

      scandy::core::MeshExportOptions opts;
      opts.m_mesh_type = scandy::core::MeshType::DRACO;
      opts.m_decimate = 0.1;
      opts.m_smoothing = 5;
      opts.m_texture_quality = 0.35;
      opts.m_remove_raw_file = false;
      //      opts.m_dst_dir_path =
      //      opts.m_src_dir_path =

      if (props[@"src_dir"]) {
        opts.m_src_dir_path = [[props[@"src_dir"] stringValue] UTF8String];
      }
      if (props[@"dst_dir"]) {
        dirPath = opts.m_dst_dir_path = [[props[@"dst_dir"] stringValue] UTF8String];
      } else {
        dirPath = slam_config->m_scan_dir_path;
      }

      if (props[@"decimate"]) {
        opts.m_decimate = [props[@"decimate"] floatValue];
      }
      if (props[@"texture_quality"]) {
        opts.m_texture_quality = [props[@"texture_quality"] floatValue];
      }
      if (props[@"smoothing"]) {
        opts.m_smoothing = [props[@"smoothing"] intValue];
      }

      scandy::core::Status status =
        ScandyCoreManager.scandyCorePtr->exportVolumetricVideo(opts);
      if (status == scandy::core::Status::SUCCESS) {
        resolve(@{
          @"directory" : [NSString stringWithUTF8String:dirPath.c_str()],
          @"success" :
            [NSNumber numberWithBool:(status == scandy::core::Status::SUCCESS)],
          @"status" : [ScandyCoreManager formatStatusError:status]
        });
      } else {
        auto reason = [[NSString alloc]
          initWithFormat:@"%s", scandy::core::getStatusString(status).c_str()];
        return reject(reason, reason, nil);
      }
    });
}

RCT_EXPORT_METHOD(getCurrentScanState
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{

  dispatch_async(dispatch_get_main_queue(), ^{
    if (ScandyCoreManager.scandyCorePtr) {
      NSString* state = [ScandyCoreManager
        formatScanStateToString:ScandyCoreManager.scandyCorePtr
                                  ->getScanState()];
      resolve(state);
    } else {
      reject(@"", @"No Scandy Core object", nil);
    }
  });
}

@end

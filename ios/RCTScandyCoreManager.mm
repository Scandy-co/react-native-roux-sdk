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
#include <scandy/core/ScanState.h>
#include <scandy/core/ScannerType.h>
#include <scandy/core/Status.h>

// imports last
#import "RCTScandyCoreManager.h"
#import "ScanView.h"

#import <React/RCTBridge.h>
#import <React/RCTConvert.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/UIView+React.h>
#import <ScandyCore/ScandyCore.h>
#import <ScandyCore/ScandyCoreManager.h>

using namespace scandy::utilities;

@interface
RCTScandyCoreManager ()

@property (nonatomic, strong) NSString* licenseString;

@end

@implementation RCTScandyCoreManager

RCT_EXPORT_MODULE(ScandyCoreManager);


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
    auto scannerType = scandy::core::ScannerType::TRUE_DEPTH;

    auto slam_config =
      ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();
    // Make sure to reset all of these
    slam_config->m_send_network_commands = false;
    slam_config->m_receive_rendered_stream = false;
    slam_config->m_send_rendered_stream = false;
    slam_config->m_receive_network_commands = false;
    slam_config->m_use_texturing = false;
    slam_config->m_save_input_plys = false;
    slam_config->m_save_input_images = false;

    auto status = [ScandyCoreManager initializeScanner:scannerType];
    ScandyCoreManager.scandyCorePtr->setBoundingBoxOffset(0.20);
  };
  if ([NSThread isMainThread]) {
    _initializeScanner();
  } else {
    dispatch_sync(dispatch_get_main_queue(), _initializeScanner);
  }
}

- (void)startPreview
{
  auto _startPreview = ^{
    auto slam_config =
      ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();
    // Make sure we get a fresh dir
    if (slam_config->m_enable_volumetric_video_recording) {
      // Make the directory where this recording will live
      {
        NSString* dirName = [NSString stringWithFormat:@"tmp"];

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
    auto licenseStatus = [ScandyCore setLicense];
    if (licenseStatus == scandy::core::Status::SUCCESS){
      [self initializeScanner];
      bool inited = scandy::core::ScanState::INITIALIZED ==
                    ScandyCoreManager.scandyCorePtr->getScanState();
      if (inited) {
        return resolve(nil);
      } else {
        return reject(@"-1", @"Could not initialize scanner", nil);
      }
    } else {
      return reject(@"-1", @"Invalid license", nil);
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
                         [self formatScanStateToString:state]];
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

RCT_EXPORT_METHOD(startScan
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    // And now the screen can go to sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    auto startStatus = [ScandyCore startScanning];
    if (startStatus == scandy::core::Status::SUCCESS) {
      return resolve(nil);
    } else {
      return reject([self formatStatusError:startStatus], [self formatStatusError:startStatus], nil);
    }
  });
}

RCT_EXPORT_METHOD(stopScan
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    // And now the screen can go to sleep
    [[UIApplication sharedApplication] setIdleTimerDisabled:NO];
    auto stopStatus = [ScandyCore stopScanning];
    if (stopStatus == scandy::core::Status::SUCCESS) {
      return resolve(nil);
    } else {
      auto reason = [NSString stringWithUTF8String:getStatusStr(stopStatus)];
      return reject(reason, reason, nil);
    }
  });
}

RCT_EXPORT_METHOD(generateMesh
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    auto status = [ScandyCore generateMesh];
    if (status == scandy::core::Status::SUCCESS) {
      return resolve(nil);
    } else {
      auto reason = [NSString stringWithUTF8String:getStatusStr(status)];
      return reject(reason, reason, nil);
    }
  });
}

RCT_EXPORT_METHOD(saveScan
                  : (NSString*)file_path resolve
                  : (RCTPromiseResolveBlock)resolve reject
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    auto status = [ScandyCore saveMesh:file_path];
    if (status == scandy::core::Status::SUCCESS) {
      return resolve(nil);
    } else {
      auto reason = [NSString stringWithUTF8String:getStatusStr(status)];
      return reject(reason, reason, nil);
    }
  });
}

RCT_EXPORT_METHOD(getV2ScanningEnabled
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    scandy::core::ScanResolution max_resolution;
    bool unbounded =
      ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration()
        ->m_use_unbounded;
    NSNumber* v2 = [NSNumber numberWithBool:unbounded];
    resolve(v2);
  });
}

RCT_EXPORT_METHOD(toggleV2Scanning
                  : (NSNumber* _Nonnull)_enabled resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
  dispatch_async(dispatch_get_main_queue(), ^{
    bool enabled = _enabled.boolValue;
    
    // get the current scan state so we can reset it after toggling
    auto scanState = ScandyCoreManager.scandyCorePtr->getScanState();
    const bool wasPreviewing = scanState == scandy::core::ScanState::PREVIEWING ||
                         scanState == scandy::core::ScanState::SCANNING;
    const bool wasInited = wasPreviewing || scanState == scandy::core::ScanState::INITIALIZED;
    
    // Unitialized the scanner if we need to
    if (wasInited) {
      [ScandyCore uninitializeScanner];
    }
    
    // Toggle the scanning mode
    auto status = [ScandyCore toggleV2Scanning:enabled];

    // Initialize if it was before toggling
    if (wasInited) {
      [ScandyCore initializeScanner];
    }

    // Start the preview if it was before toggling
    if (wasPreviewing) {
      [ScandyCore startPreview];
    }

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
  scandy::core::Status status;
  if (ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration()
        ->m_use_unbounded) {
    status = ScandyCoreManager.scandyCorePtr->setVoxelSize(size);
  } else {
    status = ScandyCoreManager.scandyCorePtr->setScanSize(size);
  }
  if (status == scandy::core::Status::SUCCESS) {
    resolve(nil);
  } else {
    auto reason = [[NSString alloc]
      initWithFormat:@"%s", scandy::core::getStatusString(status).c_str()];
    return reject(reason, reason, nil);
  }
}

RCT_EXPORT_METHOD(loadMesh
                  : (NSDictionary*)details resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{

  // get details from the js object
  NSString* meshPath;
  NSString* texturePath;

  if (![[details objectForKey:@"meshPath"] isKindOfClass:NSString.class]) {
    reject(@"", @"Expects a dict with meshPath property", nil);
  }

  meshPath = [RCTConvert NSString:details[@"meshPath"]];

  // Check if the texture is valid
  if ([[details objectForKey:@"texturePath"] isKindOfClass:NSString.class]) {
    texturePath = [RCTConvert NSString:details[@"texturePath"]];
  }

  // Working with VTK, we need to be on the render thread
  dispatch_async(dispatch_get_main_queue(), ^{
    auto status = scandy::core::Status::NOT_FOUND;
    if (ScandyCoreManager.scandyCorePtr) {
      if (texturePath) {
        status = ScandyCoreManager.scandyCorePtr->loadMesh(
          std::string([meshPath UTF8String]),
          std::string([texturePath UTF8String]));
      } else {
        status = ScandyCoreManager.scandyCorePtr->loadMesh(
          std::string([meshPath UTF8String]));
      }
    }

    if (status == scandy::core::Status::SUCCESS) {
      //      [self renderScanView];
      resolve(nil);
    } else {
      reject(
        [self formatStatusError:status], [self formatStatusError:status], nil);
    }
  });
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
  dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
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
      dirPath = opts.m_dst_dir_path =
        [[props[@"dst_dir"] stringValue] UTF8String];
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
        @"status" : [self formatStatusError:status]
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
      NSString* state = [self
        formatScanStateToString:ScandyCoreManager.scandyCorePtr
                                  ->getScanState()];
      resolve(state);
    } else {
      reject(@"", @"No Scandy Core object", nil);
    }
  });
}

- (NSString*)formatScanStateToString:(scandy::core::ScanState)scanState
{
  return [NSString stringWithFormat:@"%s", scandy::core::getScanStateString(scanState).c_str()];
}

- (NSString*)formatStatusError:(scandy::core::Status)status
{
  return [NSString stringWithFormat:@"%s", scandy::core::getStatusString(status).c_str()];
}

@end

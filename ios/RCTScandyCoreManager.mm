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

- (void) initializeScanner {
    [self initializeScanner:ScandyCoreScannerType::TRUE_DEPTH];
}

- (void)initializeScanner:(ScandyCoreScannerType)scanner_type
{
    auto _initializeScanner = ^{
        [RCTScandyCoreManager setLicense];
        
        // Let's get the scanner fired up
        //    bool hasTrueDepth = [ScandyCoreManager hasTrueDepth];
        
        // Make sure to reset all of these
        
        ScandyCoreManager.scandyCorePtr->enableSaveInputPlys(false);
        ScandyCoreManager.scandyCorePtr->enableSaveInputImages(false);
        ScandyCoreManager.scandyCorePtr->setUseTexturing(false);
        
        [ScandyCoreManager initializeScanner:scanner_type];
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
        // Make sure we get a fresh dir
        if (ScandyCoreManager.scandyCorePtr->isEnabledVolumetricVideoStreaming()) {
            // Make the directory where this recording will live
            {
                NSString* dirName = [NSString stringWithFormat:@"tmp"];
                
                NSArray* paths = NSSearchPathForDirectoriesInDomains(
                                                                     NSDocumentDirectory, NSUserDomainMask, YES);
                NSString* documentsDirectory = [paths objectAtIndex:0];
                NSString* dirPath =
                [documentsDirectory stringByAppendingPathComponent:dirName];
                ScandyCoreManager.scandyCorePtr->setScanDirPath(std::string([dirPath UTF8String]));
            }
        }
        
        [ScandyCoreManager startPreview];
        NSLog(@"startPreview");
    };
    if ([NSThread isMainThread]) {
        _startPreview();
    } else {
        dispatch_async(dispatch_get_main_queue(), _startPreview);
    }
}

- (bool)scannerStringMatchesScannerType:(NSString*)type_string     :(ScandyCoreScannerType)scanner_type{
    NSString *scannerTypeString = [NSString stringWithFormat:@"%s", scandy::core::getScannerTypeString(scanner_type)];
    return [scannerTypeString compare:type_string options:NSCaseInsensitiveSearch] == NSOrderedSame;
}

RCT_EXPORT_METHOD(initializeScanner
                  : (NSString*)scanner_type
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        ScandyCoreScannerType scannerType;
        
        if([self scannerStringMatchesScannerType
            :scanner_type
            :ScandyCoreScannerType::NETWORK]){
            scannerType = ScandyCoreScannerType::NETWORK;
        } else if([self scannerStringMatchesScannerType
                   :scanner_type
                   :ScandyCoreScannerType::IOS_LIDAR]){
            scannerType = ScandyCoreScannerType::IOS_LIDAR;
        } else if([self scannerStringMatchesScannerType
                   :scanner_type
                   :ScandyCoreScannerType::TRUE_DEPTH]){
            scannerType = ScandyCoreScannerType::TRUE_DEPTH;
        } else {
            return reject(@"-1", @"Invalid scanner type", nil);
        }
        
        auto licenseStatus = [ScandyCore setLicense];
        if (licenseStatus == scandy::core::Status::SUCCESS){
            [self initializeScanner:scannerType];
            bool inited = scandy::core::ScanState::INITIALIZED ==
            ScandyCoreManager.scandyCorePtr->getScanState();
            if (inited) {
                return resolve([self formatStatusError:scandy::core::Status::SUCCESS]);
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
        [ScandyCoreManager clearCommandHosts];
        
        
        ScandyCoreManager.scandyCorePtr->setEnableVolumetricVideoStreaming(false);
        ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration()->setEnableVolumetricVideoRecording(true);
        [self initializeScanner:ScandyCoreManager.scandyCorePtr->getScannerType()];
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
    auto uninit = [ScandyCore uninitializeScanner];
    auto statusString = [self formatStatusError:uninit];
    if (uninit == scandy::core::Status::SUCCESS) {
        return resolve(statusString);
    } else {
        return reject(statusString, statusString, nil);
    }
}

RCT_EXPORT_METHOD(reinitializeScanner
                  : (NSDictionary*)props resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        auto scanner_type = ScandyCoreManager.scandyCorePtr->getScannerType();
        ScandyCoreManager.scandyCorePtr->stopPipeline();
        ScandyCoreManager.scandyCorePtr->uninitializeScanner();
        
        // Set ScandyCore into Server or Client mode depending on whether its an
        // iPhoneX
        //    NSLog(@"props for reinit: %@", props);
        
        ScandyCoreManager.scandyCorePtr->clearCommandHosts();
        
        // Make sure to reset all of these
        [ScandyCoreManager setSendNetworkCommands:false];
        [ScandyCoreManager setReceiveRenderedStream:false];
        [ScandyCoreManager setReceiveNetworkCommands:false];
        [ScandyCoreManager setSendRenderedStream:false];
        ScandyCoreManager.scandyCorePtr->setEnableVolumetricVideoStreaming(false);
        ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration()->setEnableVolumetricVideoRecording(true);

        // If you receive the rendered stream, then you should send commands via
        // network
        if ([[props objectForKey:@"networkReceiver"] intValue] == 1) {
            [ScandyCoreManager setSendNetworkCommands:true];
            [ScandyCoreManager setReceiveRenderedStream:true];
        }
        
        // If you send the rendered stream, then you should receive commands via
        // network
        if ([[props objectForKey:@"networkSender"] intValue] == 1) {
            [ScandyCoreManager setSendRenderedStream:true];
            [ScandyCoreManager setReceiveNetworkCommands:true];
        }
        
        if ([props objectForKey:@"networkServerHost"]) {
            NSString* host = [props objectForKey:@"networkServerHost"];
            // Make sure its a legit host
            if (host && host.length > 5) {
                [ScandyCoreManager setServerHost:host];
                ScandyCoreManager.scandyCorePtr->setEnableVolumetricVideoStreaming(true);
                ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration()->setEnableVolumetricVideoRecording(false);
            } else {
                [ScandyCoreManager setServerHost:@"127.0.0.1"];
                ScandyCoreManager.scandyCorePtr->setEnableVolumetricVideoStreaming(false);
                ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration()->setEnableVolumetricVideoRecording(true);
            }
        }
        
        [self initializeScanner:scanner_type];
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
            auto statusString = [self formatStatusError:ScandyCoreStatus::SUCCESS];
            resolve(statusString);
        } else {
            NSString* msg = [NSString
                             stringWithFormat:@"Could not start preview. ScandyCore state: %@",
                             [self formatScanStateToString:state]];
            reject(@"-1", msg, nil);
        }
    });
}

// Doesn't look like this is implemented
// RCT_EXPORT_METHOD(startRecording
//                   : (NSString*)output_dir resolve
//                   : (RCTPromiseResolveBlock)resolve reject
//                   : (RCTPromiseRejectBlock)reject)
// {
//   auto slam_config =
//     ScandyCoreManager.scandyCorePtr->getIScandyCoreConfiguration();

//   // If we are recording, make sure to update the output dir
//   if (slam_config->m_enable_volumetric_video_recording) {
//     slam_config->m_scan_dir_path = output_dir.UTF8String;
//     FileOps::EnsureDirectory(slam_config->m_scan_dir_path);
//   }
//   slam_config->m_preview_mode = false;
// }

RCT_EXPORT_METHOD(startScan
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        // And now the screen can go to sleep
        [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
        auto startStatus = [ScandyCore startScanning];
        auto statusString = [self formatStatusError:startStatus];
        if (startStatus == scandy::core::Status::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
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
        auto statusString = [self formatStatusError:stopStatus];
        if (stopStatus == scandy::core::Status::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
        }
    });
}

RCT_EXPORT_METHOD(generateMesh
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        auto status = [ScandyCore generateMesh];
        auto statusString = [self formatStatusError:status];
        if (status == scandy::core::Status::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
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
        auto statusString = [self formatStatusError:status];
        if (status == scandy::core::Status::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
        }
    });
}

RCT_EXPORT_METHOD(getV2ScanningEnabled
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    dispatch_async(dispatch_get_main_queue(), ^{
        scandy::core::ScanResolution max_resolution;
        bool unbounded = [ScandyCoreManager getUseUnbounded];
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
        ScandyCoreScannerType scannerType = ScandyCoreManager.scandyCorePtr->getScannerType();
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
            status = [ScandyCore initializeScanner:scannerType];
        }
        
        // Start the preview if it was before toggling
        if (wasPreviewing) {
            status = [ScandyCore startPreview];
        }
        
        auto statusString = [self formatStatusError:status];
        
        if (status == scandy::core::Status::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
        }
    });
}

RCT_EXPORT_METHOD(setSize
                  : (float)size resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    scandy::core::Status status;
    if ([ScandyCoreManager getUseUnbounded]) {
        status = ScandyCoreManager.scandyCorePtr->setVoxelSize(size);
    } else {
        status = ScandyCoreManager.scandyCorePtr->setScanSize(size);
    }
    auto statusString = [self formatStatusError:status];
    
    if (status == scandy::core::Status::SUCCESS) {
        return resolve(statusString);
    } else {
        return reject(statusString, statusString, nil);
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
        
        auto statusString = [self formatStatusError:status];
        
        if (status == scandy::core::Status::SUCCESS) {
            //      [self renderScanView];
            resolve(statusString);
        } else {
            reject(statusString, statusString, nil);
        }
    });
}

RCT_EXPORT_METHOD(exportVolumetricVideo
                  : (NSDictionary*)props resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    [RCTScandyCoreManager setLicense];
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
            dirPath = ScandyCoreManager.scandyCorePtr->getScanDirPath();
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
        auto statusString = [self formatStatusError:status];
        if (status == scandy::core::Status::SUCCESS) {
            resolve(@{
                @"directory" : [NSString stringWithUTF8String:dirPath.c_str()],
                @"success" :
                    [NSNumber numberWithBool:(status == scandy::core::Status::SUCCESS)],
                @"status" : statusString
                    });
        } else {
            return reject(statusString, statusString, nil);
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

RCT_EXPORT_METHOD(getIPAddress
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        auto ip_address = [ScandyCore getIPAddress];
        if([ip_address  isEqual: @"127.0.0.1"]){
            reject(@"", @"Not connected to wifi", nil);
        } else {
            resolve(ip_address);
        }
    });
}

RCT_EXPORT_METHOD(setSendRenderedStream
                  : (NSNumber* _Nonnull)_enabled resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        bool enabled = _enabled.boolValue;
        ScandyCoreStatus status = [ScandyCore setSendRenderedStream:enabled];
        auto statusString = [self formatStatusError:status];
        if (status == scandy::core::Status::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
        }
    });
}

RCT_EXPORT_METHOD(getSendRenderedStream
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        auto result = [ScandyCore getSendRenderedStream];
        NSNumber* enabled = [NSNumber numberWithBool:result];
        resolve(enabled);
    });
}

RCT_EXPORT_METHOD(setSendNetworkCommands
                  : (NSNumber* _Nonnull)_enabled resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        bool enabled = _enabled.boolValue;
        ScandyCoreStatus status = [ScandyCore setSendNetworkCommands:enabled];
        auto statusString = [self formatStatusError:status];
        if (status == scandy::core::Status::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
        }
    });
}

RCT_EXPORT_METHOD(getSendNetworkCommands
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        auto result = [ScandyCore getSendNetworkCommands];
        NSNumber* enabled = [NSNumber numberWithBool:result];
        resolve(enabled);
    });
}

RCT_EXPORT_METHOD(setReceiveRenderedStream
                  : (NSNumber* _Nonnull)_enabled resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        bool enabled = _enabled.boolValue;
        ScandyCoreStatus status = [ScandyCore setReceiveRenderedStream:enabled];
        auto statusString = [self formatStatusError:status];
        if (status == scandy::core::Status::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
        }
    });
}


RCT_EXPORT_METHOD(getReceiveRenderedStream
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        auto result = [ScandyCore getReceiveRenderedStream];
        NSNumber* enabled = [NSNumber numberWithBool:result];
        resolve(enabled);
    });
}

RCT_EXPORT_METHOD(setReceiveNetworkCommands
                  : (NSNumber* _Nonnull)_enabled resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        bool enabled = _enabled.boolValue;
        ScandyCoreStatus status = [ScandyCore setReceiveNetworkCommands:enabled];
        auto statusString = [self formatStatusError:status];
        if (status == scandy::core::Status::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
        }
    });
}

RCT_EXPORT_METHOD(getReceiveNetworkCommands
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        auto result = [ScandyCore getReceiveNetworkCommands];
        NSNumber* enabled = [NSNumber numberWithBool:result];
        resolve(enabled);
    });
}

RCT_EXPORT_METHOD(setServerHost
                  : (NSString*)ip_address resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        ScandyCoreStatus status = [ScandyCore setServerHost:ip_address];
        auto statusString = [self formatStatusError:status];
        if (status == ScandyCoreStatus::SUCCESS) {
            return resolve(statusString);
        } else {
            return reject(statusString, statusString, nil);
        }
    });
}

RCT_EXPORT_METHOD(getConnectedClients
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        auto connected_clients = [ScandyCore getConnectedClients];
        if(connected_clients.count){
            resolve(connected_clients);
        } else {
            resolve(nil);
        }
    });
}

RCT_EXPORT_METHOD(getDiscoveredHosts
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        auto discovered_hosts = [ScandyCore getDiscoveredHosts];
        if(discovered_hosts.count){
            resolve(discovered_hosts);
        } else {
            resolve(nil);
        }
    });
}

RCT_EXPORT_METHOD(connectToCommandHost
                  : (NSString*)ip_address resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ScandyCore connectToCommandHost:ip_address];
        return resolve([self formatStatusError:ScandyCoreStatus::SUCCESS]);
    });
}

RCT_EXPORT_METHOD(hasNetworkConnection
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        auto is_connected = [ScandyCore hasNetworkConnection];
        return resolve([NSNumber numberWithBool:is_connected]);
    });
}

RCT_EXPORT_METHOD(clearCommandHosts
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [ScandyCore clearCommandHosts];
        return resolve([self formatStatusError:ScandyCoreStatus::SUCCESS]);
    });
}

RCT_EXPORT_METHOD(decimateMesh
                  : (double)percent resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    auto status = [ScandyCore decimateMesh:percent];
    auto statusString = [self formatStatusError:status];
    if (status == scandy::core::Status::SUCCESS) {
        return resolve(statusString);
    } else {
        return reject(statusString, statusString, nil);
    }
}

RCT_EXPORT_METHOD(smoothMesh
                  : (int)iterations resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    auto status = [ScandyCore smoothMesh:iterations];
    auto statusString = [self formatStatusError:status];
    if (status == scandy::core::Status::SUCCESS) {
        return resolve(statusString);
    } else {
        return reject(statusString, statusString, nil);
    }
}

RCT_EXPORT_METHOD(fillHoles
                  : (double)hole_size resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    auto status = [ScandyCore fillHoles:hole_size];
    auto statusString = [self formatStatusError:status];
    if (status == scandy::core::Status::SUCCESS) {
        return resolve(statusString);
    } else {
        return reject(statusString, statusString, nil);
    }
}

RCT_EXPORT_METHOD(extractLargestSurface
                  : (double)min_percent resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    auto status = [ScandyCore extractLargestSurface:min_percent];
    auto statusString = [self formatStatusError:status];
    if (status == scandy::core::Status::SUCCESS) {
        return resolve(statusString);
    } else {
        return reject(statusString, statusString, nil);
    }
}

RCT_EXPORT_METHOD(makeWaterTight
                  : (int)depth resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    auto status = [ScandyCore makeWaterTight:depth];
    auto statusString = [self formatStatusError:status];
    if (status == scandy::core::Status::SUCCESS) {
        return resolve(statusString);
    } else {
        return reject(statusString, statusString, nil);
    }
}

RCT_EXPORT_METHOD(applyEditsFromMeshViewport
                  : (NSNumber* _Nonnull)_apply_changes resolver
                  : (RCTPromiseResolveBlock)resolve rejecter
                  : (RCTPromiseRejectBlock)reject)
{
    bool apply_changes = _apply_changes.boolValue;
    auto status = [ScandyCore applyEditsFromMeshViewport:apply_changes];
    auto statusString = [self formatStatusError:status];
    if (status == scandy::core::Status::SUCCESS) {
        return resolve(statusString);
    } else {
        return reject(statusString, statusString, nil);
    }
}


- (NSString*)formatScanStateToString:(scandy::core::ScanState)scanState
{
    NSString* scanStateStr = [NSString stringWithFormat:@"%s", scandy::core::getScanStateString(scanState).c_str()];
    if ([scanStateStr rangeOfString:@"scandy::core::ScanState"].location == NSNotFound){
        return scanStateStr;
    } else {
        auto start = [scanStateStr rangeOfString:@":" options:NSBackwardsSearch].location + 3;
        auto length = scanStateStr.length - start - 1;
        NSRange substrRange = NSMakeRange(start, length);
        return [scanStateStr substringWithRange:substrRange];
    }
}

- (NSString*)formatStatusError:(scandy::core::Status)status
{
    return [NSString stringWithFormat:@"%s", scandy::core::getStatusString(status).c_str()];
}

@end

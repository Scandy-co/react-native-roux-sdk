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

// imports must come second
#import "RCTScandyCoreManager.h"
#import "ScanView.h"

#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import <React/RCTLog.h>
#import <React/RCTUtils.h>
#import <React/UIView+React.h>
#import <ScandyCore/ScandyCore.h>
#import <ScandyCore/ScandyCoreManager.h>

using namespace scandy::utilities;

@interface
RCTRouxManager ()


@property (nonatomic, strong) NSString* licenseString;

@end

@implementation RCTRouxManager

RCT_EXPORT_MODULE(RouxManager);

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

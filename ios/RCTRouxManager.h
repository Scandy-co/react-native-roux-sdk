//
//  RCTRouxManager.h
//  RouxSdk
//
//  Created by George Farro on 6/3/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

#ifndef RCTRouxManager_h
#define RCTRouxManager_h

#import <React/RCTViewManager.h>
#import <React/RCTBridgeModule.h>
#import <GLKit/GLKit.h>

NSString* const StartScanningNotification = @"StartScanning";
NSString* const ChangeScanSizeNotification = @"ChangeScanSize";

@interface RCTRouxManager : RCTViewManager <RCTBridgeModule>
- (bool)uninitializeScanner;
- (void)pauseAV;
@end


#endif /* RCTRouxManager_h */

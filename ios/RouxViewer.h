//
//  RouxViewer.m
//  RouxSdk
//
//  Created by George Farro on 6/2/20.
//  Copyright © 2020 Facebook. All rights reserved.
//

#import <GLKit/GLKit.h>

#import <ScandyCore/ScandyCoreView.h>
#import <React/RCTComponent.h>


NS_ASSUME_NONNULL_BEGIN

@interface RouxViewer : ScandyCoreView

@property (nonatomic, copy) RCTBubblingEventBlock onScannerReady;
@property (nonatomic, copy) RCTBubblingEventBlock onVisualizerReady;
@property (nonatomic, copy) RCTBubblingEventBlock onPreviewStart;
@property (nonatomic, copy) RCTBubblingEventBlock onScannerStart;
@property (nonatomic, copy) RCTBubblingEventBlock onScannerStop;
@property (nonatomic, copy) RCTBubblingEventBlock onGenerateMesh;
@property (nonatomic, copy) RCTBubblingEventBlock onSaveMesh;
@property (nonatomic, copy) RCTBubblingEventBlock onClientConnected;
@property (nonatomic, copy) RCTBubblingEventBlock onHostDiscovered;
@property (nonatomic, copy) RCTBubblingEventBlock onVolumeMemoryDidUpdate;
@property (nonatomic, copy) RCTBubblingEventBlock onVidSavedToCamRoll;

@property BOOL scanMode;
@property (nonatomic, copy) NSString* kind;

- (instancetype)initWithContext:(EAGLContext *) context;
- (void)shutdown;
- (void)setRendererBackgroundColor;
- (void)setRendererBackgroundColor:(double*) color1 :(double*) color2 :(bool) enableGradient;

@end

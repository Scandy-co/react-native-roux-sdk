//
//  ScanView.h
//  Hoxel
//
//  Created by H. Cole Wiley on 12/7/18.
//  Copyright © 2018 Scandy. All rights reserved.
//

#import <GLKit/GLKit.h>

#import <ScandyCore/ScandyCoreView.h>
#import <React/RCTComponent.h>


NS_ASSUME_NONNULL_BEGIN

@interface ScanView : ScandyCoreView

@property (nonatomic, copy) RCTBubblingEventBlock onScannerReady;
@property (nonatomic, copy) RCTBubblingEventBlock onVisualizerReady;
@property (nonatomic, copy) RCTBubblingEventBlock onPreviewStart;
@property (nonatomic, copy) RCTBubblingEventBlock onScannerStart;
@property (nonatomic, copy) RCTBubblingEventBlock onScannerReady;
@property (nonatomic, copy) RCTBubblingEventBlock onScannerStop;
@property (nonatomic, copy) RCTBubblingEventBlock onGenerateMesh;
@property (nonatomic, copy) RCTBubblingEventBlock onSaveMesh;
@property (nonatomic, copy) RCTBubblingEventBlock onExportVolumetricVideo;
@property (nonatomic, copy) RCTBubblingEventBlock onClientConnected;
@property (nonatomic, copy) RCTBubblingEventBlock onHostDiscovered;
@property (nonatomic, copy) RCTBubblingEventBlock onVolumeMemoryDidUpdate;
@property (nonatomic, copy) RCTBubblingEventBlock onVidSavedToCamRoll;
@property BOOL scanMode;

@end

NS_ASSUME_NONNULL_END

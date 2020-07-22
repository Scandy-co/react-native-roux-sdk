# react-native-roux-sdk

A React Native wrapper around the Roux 3D scanning SDK for iOS. Provides access to 3D meshing, measuring, editing tools, etc. https://scandy.co/apps/roux

## Compatibility

This react-native-roux-sdk is built to be used with `ScandyCore.framework` **v0.7.2**.

We are still working on version linking this react native package and the Roux SDK framework.

## Installation

```
npm install https://github.com/Scandy-co/react-native-roux-sdk
```

## Usage

### Methods

```js
import Roux from 'react-native-roux-sdk';

// ...
// Set up the scan preview
const result = await Roux.initializeScanner();
const result = await Roux.startPreview();

// ...
// Update the scan parameters

// Toggle v2 scanning
await Roux.toggleV2Scanning();

// Get v2 scanning (returns true/false)
const v2 = await Roux.getV2ScanningEnabled();

// For V1 (aka bounded scanning)
const boxSize = 1.5; // meters
const result = await Roux.setSize(boxSize);

// For V2 (aka unbounded scanning)
const voxelSize = 1.5; // millimeters
const result = await Roux.setSize(voxelSize * 1e-3); // set size needs meters, so convert mm to m

// ...
// Start, stop, and save your model
const result = await Roux.startScan();
const result = await Roux.stopScan();
const result = await Roux.generateMesh();
const result = await Roux.saveScan(destination);
```

### Component

```js
import { RouxView } from 'react-native-roux-sdk';

<RouxView
  style={{ flex: 1 }}
  onScanStateChanged={this._onScanStateChanged}
  onVisualizerReady={() =>
    console.log('wait for this to fire, then setup the scan preview')
  }
  onPreviewStart={this._onPreviewStart}
  onScannerStart={this._onScannerStart}
  onScannerStop={this._onScannerStop}
  onGenerateMesh={this._onGenerateMesh}
  onSaveMesh={this._onSaveMesh}
/>;
```

## Notes on building

In Build Settings for your project including this library, please change Build Settings to:

Enable Bitcode: No

Valid Architectures: arm64 (no others)

In `General`, add `ScandyCore.framework` to `Frameworks, Libraries and Embedded Content`.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

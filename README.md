# react-native-roux-sdk

A React Native wrapper around the Roux 3D scanning SDK for iOS. Provides access to 3D meshing, measuring, editing tools, etc. https://scandy.co/apps/roux

## Installation

```sh
yarn add react-native-roux-sdk
```

Or

```sh
npm install react-native-roux-sdk
```

## Usage

### Methods

```js
import { Roux } from 'react-native-roux-sdk';

// ...
// Set up the scan preview
const result = await Roux.initializeScanner();
const result = await Roux.startPreview();

// ...
// Update the scan parameters
// const result = await Roux.setSize(???);
// const result = await Roux.setResolution(???);

// ...
// Start, stop, and save your model
const result = await Roux.startScan();
const result = await Roux.stopScan(); // generates your mesh & shows mesh in preview window
const result = await Roux.saveScan(destination);
```

### Component

```js
import { RNScandyCoreView } from 'react-native-roux-sdk';

<RouxViewer
  style={{ flex: 1 }}
  onVisualizerReady={() =>
    console.log('wait for this to fire, then setup the scan preview')
  }
  onPreviewStart={this._onScannerStart}
  onScannerStart={this._onScannerStart}
  onScannerStop={this._onScannerStop}
  onGenerateMesh={this._onGenerateMesh}
  onSaveMesh={this._onSaveMesh}
/>;
```

## Notes on building

In Build Settings for your project including this library, please change Build Settings to:

Bitcode Enabled: false
Valid Architectures: arm64

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

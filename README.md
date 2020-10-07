# react-native-roux-sdk

A React Native wrapper around the Roux 3D scanning SDK for iOS. Provides access to 3D meshing, measuring, editing tools, etc. https://scandy.co/apps/roux

## Compatibility

This react-native-roux-sdk is built to be used with `ScandyCore.framework` **v0.8.0**.

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
const result = await Roux.initializeScanner('true_depth' || 'network');
const result = await Roux.startPreview();

// ...
// Update the scan parameters

// Toggle v2 scanning
const status = await Roux.toggleV2Scanning();

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
const result = await Roux.saveScan(destination, {options});
const result = await Roux.loadMesh({ meshPath, texturePath });

// Editing mesh
const result = await Roux.decimateMesh(percent);
const result = await Roux.smoothMesh(iterations);
const result = await Roux.fillHoles(hole_size);
const result = await Roux.extractLargestSurface(min_percent);
const result = await Roux.makeWaterTight(depth);
const result = await Roux.applyEditsFromMeshViewport(apply_changes);

//Networking
const ip_address = await Roux.getIPAddress();

const result = await Roux.setSendRenderedStream(true || false);
const result = await Roux.getSendRenderedStream();

const result = await Roux.setReceiveNetworkCommands(true || false);
const result = await Roux.getReceiveNetworkCommands();

const result = await Roux.setReceiveRenderedStream(true || false);
const result = await Roux.getReceiveRenderedStream();

const result = await Roux.setSendNetworkCommands(true || false);
const result = await Roux.getSendNetworkCommands();

const result = await Roux.setServerHost(ip_address); //where ip_address is a string
const hosts = await Roux.getDiscoveredHosts();
const clients = await Roux.getConnectedClients();
const result = await Roux.connectToCommandHost(ip_address); //where ip_address is a string
const is_connected = await Roux.hasNetworkConnection();
const result = await Roux.clearCommandHosts();
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
  onScannerReady={this._onScannerReady}
  onScannerStart={this._onScannerStart}
  onScannerStop={this._onScannerStop}
  onGenerateMesh={this._onGenerateMesh}
  onSaveMesh={this._onSaveMesh}
  onHostDiscovered={this._onHostDiscovered}
/>;
```

#### Return values

All methods return a promise. When resolved, most methods return a `RouxStatusString` (unless otherwise indicated below) which is a string describing the result of the method call. For example, a successful call will return `scandy::core::Status::SUCCESS no errors`, while an error may return `scandy::core::Status::INVALID_STATE invalid state`.

### Scanning Methods

#### `initializeScanner(type: string): Promise<RouxStatusString>`

Checks for valid license and initializes scanner. Must call initializeScanner in order to be able to start scanning, stop scanning, etc.

**Parameters**

- **type**: string
  One of the following supported scanner types: `true_depth`, `network`

#### `startPreview(): Promise<RouxStatusString>`

Starts scanning preview.

#### `toggleV2Scanning(): Promise<RouxStatusString>`

Toggles v2 scanning on or off. `v2 scan mode` is the Scandy way of referring to unbounded scanning. If v2 mode is enabled, the user can scan freely. If v2 mode is disabled, the user can only capture scan within a predefined bounding box.

#### `getV2ScanningEnabled(): Promise<Bool>`

Promise returns `true` if v2 mode is enabled, and `false` if v2 mode is disabled.

#### `setSize(size: float): Promise<RouxStatusString>`

Sets the voxel size (aka resolution) if in v2 mode (unbounded scanning). Small voxel size = small objects, large voxel size = large objects. If in bounded (v1) mode, this sets the size of the bounding box - the larger the bounding box, the larger the voxel size. We can set this from 0.5mm for smaller objects to 4mm for larger objects.

**Parameters**

- **size**: float
  voxel size in meters for v2 mode, mm for v1 mode.

#### `startScan(): Promise<RouxStatusString>`

Starts scanning.

#### `stopScan(): Promise<RouxStatusString>`

Stops scanning.

### Mesh Methods

#### `generateMesh(): Promise<RouxStatusString>`

Generates mesh from the most recent scan session.

#### `saveScan(destination: string, options: object): Promise<RouxStatusString>`

Saves the generated mesh to the device. Options is required, but can be empty object. Default model scale is meters.

**Parameters**

- **destination**: string
  Path of file. Supported extensions: `.obj`, `.ply`, `.stl`, `.glb`, `.fbx`, `.draco`. If no extension is found, the mesh will be saved as a `PLY` by default.
- **options**: object
  - **scale** (optional): string
    desired model scale. possible values: `mm`, `cm`, `m`, `in`

#### `loadMesh(details: object): Promise<RouxStatusString>`

Loads mesh data and renders in RouxView.

**Parameters**

- **details**: object
  - **meshPath**: string
    absolute path to the mesh file to be loaded
  - **texturePath** (optional): string
    absolute path to the texture file to be loaded and mapped on the mesh

#### `decimateMesh(percent: float): Promise<RouxStatusString>`

Reduces the number of points and triangles in the mesh.
**Parameters**

- **percent**: float
  percent reduction in number of points, 0.0 - 1.0

#### `smoothMesh(iterations: int): Promise<RouxStatusString>`

Smooths the surface of the mesh
**Parameters**

- **iterations**: int
  The number of smoothing iterations to make. 3-10 is a reasonable range

#### `fillHoles(hole_size: float): Promise<RouxStatusString>`

Attempts to automatically fill holes in the mesh.

**Parameters**

- **hole_size**: float
  Largest area of mesh to fill

#### `extractLargestSurface(min_percent: double): Promise<RouxStatusString>`

Removes all the non connected surfaces floating in the mesh that smaller than min_percent of the full mesh's size.

**Parameters**

- **min_percent**: float
  The minimum percentage of mesh size to preserve individual pieces. 0.1 (10%) is good for removing small noisy parts while keeping some possibly larger disconnected pieces.

#### `makeWaterTight(depth: int): Promise<RouxStatusString>`

Attempts to automatically make the mesh water tight

**Parameters**

- **depth**: int
  How deeply to follow the original model. 5 is loose, 8 is default, 13 is high

#### `applyEditsFromMeshViewport(apply_changes: bool): Promise<RouxStatusString>`

Apply the edits being viewed in the Viewport into the mesh, so that when you save they take

**Parameters**

- **apply_changes**: bool
  Apply the edits (true) or (false) undo the edits

### Networking Methods

(see [networking demo](https://github.com/Scandy-co/RouxReactNativeHelloWorld/tree/demo/networking) more information on networking)

#### `getIPAddress(): Promise<string>`

Returns IP address of device.

#### `setSendRenderedStream(enabled: Bool): Promise<RouxStatusString>`

Sets whether this device should stream its rendered preview to a mirror device.

#### `getSendRenderedStream(): Promise<Bool>`

Resolves to `true` if the device is set up to send rendered preview to a mirror device.

#### `setReceiveNetworkCommands(enabled: Bool): Promise<RouxStatusString>`

Sets whether this device should receive commands from connected scanning devices.

#### `getReceiveNetworkCommands(): Promise<Bool>`

Resolves to `true` if the device is set up to receive commands from connected scanning devices.

#### `setReceiveRenderedStream(enabled: Bool): Promise<RouxStatusString>`

Sets whether this device should receive preview stream from a scanning device. Scanner must be initialized with `intializeScanner(network)` if this is true.

#### `getReceiveRenderedStream(): Promise<Bool>`

Resolves to `true` if the device is set up to receive preview stream from a scanning device.

#### `setSendNetworkCommands(enabled: Bool): Promise<RouxStatusString>`

Sets whether this device should send commands to connected scanning devices. If enabled = `true`, calls to functions `startScan`, `stopScan`, `generateMesh`, and `setSize` will be sent to the connected scanning device.

#### `getSendNetworkCommands(): Promise<Bool>`

Resolves to `true` if the device is set up to send commands to connected scanning devices.

#### `setServerHost(ip_address: string): Promise<RouxStatusString>`

Sets the IP address of the scanning device where scan commands will be sent.

#### `connectToCommandHost(ip_address: string): Promise<RouxStatusString>`

Connects to a mirror device to receive commands from.

#### `getDiscoveredHosts(): Promise<string[]>`

Returns an array containing the IP addresses of available mirror devices.

#### `getConnectedClients(): Promise<string[]>`

Returns an array containing the IP addresses of connected scanning devices.

#### `hasNetworkConnection(): Promise<Bool>`

Returns true if the device is actively connected to a networking clients, false if not.

#### `clearCommandHosts(): Promise<RouxStatusString>`

Clears the list of hosts that we should receive commands from.

### RouxView Callback Props

| Prop               | Description                                                                                                                                    |
| ------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| onScanStateChanged | Triggered when scan state changes. Returns the following scan states: `INITIALIZED`, `PREVIEWING`, `SCANNING`, `STOPPED`, `MESHING`, `VIEWING` |
| onVisualizerReady  | Visualizer is ready to start initializing, previewing, etc                                                                                     |
| onPreviewStart     | Preview has started rendering                                                                                                                  |
| onScannerReady     | Scanner is ready to start                                                                                                                      |
| onScannerStart     | Scanning has started                                                                                                                           |
| onScannerStopped   | Scanning has stopped                                                                                                                           |
| onGenerateMesh     | Mesh has been generated                                                                                                                        |
| onSaveMesh         | Mesh has been saved                                                                                                                            |
| onHostDiscovered   | Host (mirror device) has been discovered. Returns ip address of discovered host.                                                               |

## Notes on building

In Build Settings for your project including this library, please change Build Settings to:

Enable Bitcode: No

Valid Architectures: arm64 (no others)

In `General`, add `ScandyCore.framework` to `Frameworks, Libraries and Embedded Content`.

## Contributing

See the [contributing guide](CONTRIBUTING.md) to learn how to contribute to the repository and the development workflow.

## License

MIT

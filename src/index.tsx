/**
 * @format
 */
import * as React from 'react';
import {
  StyleSheet,
  View,
  NativeModules,
  requireNativeComponent,
  ViewStyle,
  StyleProp,
} from 'react-native';

const { ScandyCoreManager } = NativeModules;
const Roux = ScandyCoreManager;

const RCTScandyCoreView = requireNativeComponent('RCTScandyCoreView');

type Props = {
  /**
   * when Core has an issue mounting natively
   */
  onError?: Function;
  /**
   * called once Core has a valid render context
   * IMPORTANT - don't call any functions prior to this being called
   */
  onVisualizerReady?: Function;
  /**
   * 2d preview and depth volume stream is now displayed in
   * the Core visualizer
   */
  onStartPreview?: Function;
  /**
   * Core began live meshing
   */
  onStartScanning?: Function;
  /**
   * Core is initialized
   */
  onInitializeScanner?: Function;
  /**
   * Core finished live meshing
   */
  onStopScanning?: Function;
  /**
   * Mesh completed and is now visualized
   */
  onGenerateMesh?: Function;
  /**
   * mesh has saved successfully
   */
  onSaveMesh?: Function;
  onExportVolumetricVideo?: Function;
  onLoadMesh?: Function;
  onScanStateChanged?: Function;
  onClientConnected?: Function;
  onHostDiscovered?: Function;
  onVoxelSizeChanged?: Function;
  onVolumeMemoryDidUpdate?: Function;
  onVidSavedToCamRoll?: Function;
  scanMode: Boolean;
  onLayout?: Function;
  meshPath?: string;
  style?: StyleProp<ViewStyle>;
};

class RouxView extends React.Component<Props> {
  static defaultProps = {
    onError: () => console.log('ScandyCore: Errored'),
    onVisualizerReady: () => console.log('ScandyCore: Visualizer Readied'),
    onStartPreview: () => console.log('ScandyCore: Preview Started'),
    onStartScanning: () => console.log('ScandyCore: Scanner Started'),
    onInitializeScanner: () => console.log('ScandyCore: Scanner Ready'),
    onStopScanning: () => console.log('ScandyCore: Scanner Stopped'),
    onGenerateMesh: () => console.log('ScandyCore: Generated Mesh'),
    onSaveMesh: () => console.log('ScandyCore: Saved Mesh'),
    onLoadMesh: () => console.log('Scandy Core: Mesh Loaded'),
    onScanStateChanged: (state: string) =>
      console.log('Scandy Core: State Changed ', state),
    onClientConnected: () => console.log('ScandyCore: Client Connected'),
    onHostDiscovered: () => console.log('Scandy Core: Host Discovered'),
    scanMode: false,
  };

  componentDidMount() {
    // console.log('ScandyCoreView mounting')
  }

  componentWillUnmount() {
    // Make sure the scanner doesn't keep running in the background
    ScandyCoreManager.uninitializeScanner();
    // console.log('ScandyCoreView un mounting')
  }
  _onError = (err: string) => {
    if (this.props.onError) {
      this.props.onError(err);
    }
    console.log(err);
  };

  _onVisualizerReady = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onVisualizerReady) {
      this.props.onVisualizerReady(nativeEvent);
    }
    this._updateCoreState();
  };

  _onStartPreview = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onStartPreview) {
      this.props.onStartPreview(nativeEvent);
    }
    this._updateCoreState();
  };

  _onStartScanning = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onStartScanning) {
      this.props.onStartScanning(nativeEvent);
    }
    this._updateCoreState();
  };

  _onInitializeScanner = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onInitializeScanner) {
      this.props.onInitializeScanner(nativeEvent);
    }
    this._updateCoreState();
  };

  _onStopScanning = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onStopScanning) {
      this.props.onStopScanning(nativeEvent);
    }
    this._updateCoreState();
  };

  _onGenerateMesh = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onGenerateMesh) {
      this.props.onGenerateMesh(nativeEvent);
    }
    this._updateCoreState();
  };

  _onSaveMesh = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onSaveMesh) {
      this.props.onSaveMesh(nativeEvent);
    }
    this._updateCoreState();
  };

  _onLoadMesh = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onLoadMesh) {
      this.props.onLoadMesh(nativeEvent);
    }
    this._updateCoreState();
  };

  _onExportVolumetricVideo = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onExportVolumetricVideo) {
      this.props.onExportVolumetricVideo(nativeEvent);
    }
    this._updateCoreState();
  };

  _onClientConnected = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onClientConnected) {
      this.props.onClientConnected(nativeEvent.host);
    }
  };

  _onHostDiscovered = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onHostDiscovered) {
      this.props.onHostDiscovered(nativeEvent.host);
    }
  };

  _onVolumeMemoryDidUpdate = (dict) => {
    if (this.props.onVolumeMemoryDidUpdate) {
      this.props.onVolumeMemoryDidUpdate(dict.nativeEvent.percent_full);
    }
  };

  _updateCoreState = () => {
    ScandyCoreManager.getCurrentScanState().then((STATE: string) => {
      if (this.props.onScanStateChanged) {
        this.props.onScanStateChanged(STATE);
      }
    });
  };

  _onVidSavedToCamRoll = ({ nativeEvent }: { nativeEvent: object }) => {
    if (this.props.onVidSavedToCamRoll) {
      this.props.onVidSavedToCamRoll(nativeEvent);
    }
  };

  render() {
    const { style } = this.props;
    return (
      <View
        style={style || StyleSheet.absoluteFill}
        onLayout={(e) => {
          if (this.props.onLayout) {
            this.props.onLayout(e);
          }
        }}
      >
        <RCTScandyCoreView
          style={style || StyleSheet.absoluteFill}
          onError={this._onError}
          onVisualizerReady={this._onVisualizerReady}
          onStartPreview={this._onStartPreview}
          onStartScanning={this._onStartScanning}
          onInitializeScanner={this._onInitializeScanner}
          onStopScanning={this._onStopScanning}
          onGenerateMesh={this._onGenerateMesh}
          onSaveMesh={this._onSaveMesh}
          onLoadMesh={this._onLoadMesh}
          onExportVolumetricVideo={this._onExportVolumetricVideo}
          onClientConnected={this._onClientConnected}
          onHostDiscovered={this._onHostDiscovered}
          scanMode={this.props.scanMode}
          onVolumeMemoryDidUpdate={this._onVolumeMemoryDidUpdate}
          onVidSavedToCamRoll={this._onVidSavedToCamRoll}
        />
        {this.props.children}
      </View>
    );
  }
}

// TODO example fo how to type up these methods for ScandyCoreManager
// Promise<any> could probable be Promise<void> instead
//  but I hit a speedbump...
type RouxType = {
  initializeScanner(scanner_type: string): Promise<any>;
  uninitializeScanner(): Promise<any>;
  startPreview(): Promise<any>;
  startScan(): Promise<any>;
  stopScan(): Promise<any>;
  generateMesh(): Promise<any>;
  saveScan(filePath: string): Promise<any>;
  setSize(size: number): Promise<any>;
  loadMesh(dict: object): Promise<any>;
  toggleV2Scanning(enabled: boolean): Promise<any>;
  getV2ScanningEnabled(): Promise<any>;
  getIPAddress(): Promise<any>;
  setSendRenderedStream(enabled: boolean): Promise<any>;
  getSendRenderedStream(enabled: boolean): Promise<any>;
  setSendNetworkCommands(enabled: boolean): Promise<any>;
  getSendNetworkCommands(): Promise<any>;
  setReceiveRenderedStream(enabled: boolean): Promise<any>;
  getReceiveRenderedStream(): Promise<any>;
  setReceiveNetworkCommands(enabled: boolean): Promise<any>;
  getReceiveNetworkCommands(): Promise<any>;
  setServerHost(ip_address: string): Promise<any>;
  getDiscoveredHosts(): Promise<any>;
  getConnectedClients(): Promise<any>;
  connectToCommandHost(ip_address: string): Promise<any>;
  clearCommandHosts(): Promise<any>;
  decimateMesh(percent: number): Promise<any>;
  smoothMesh(iterations: number): Promise<any>;
  fillHoles(hole_size: number): Promise<any>;
  extractLargestSurface(min_percent: number): Promise<any>;
  makeWaterTight(depth: number): Promise<any>;
  applyEditsFromMeshViewport(apply_changes: boolean): Promise<any>;
  optimizeMeshSize(max_size: number): Promise<any>;
};

// const { RouxSdk } = NativeModules;

export default Roux as RouxType;
export { RouxView };

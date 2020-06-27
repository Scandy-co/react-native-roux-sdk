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
  onPreviewStart?: Function;
  /**
   * Core began live meshing
   */
  onScannerStart?: Function;
  /**
   * Core finished live meshing
   */
  onScannerStop?: Function;
  /**
   * Mesh completed and is now visualized
   */
  onGenerateMesh?: Function;
  /**
   * mesh has saved successfully
   */
  onSaveMesh?: Function;
  onExportVolumetricVideo?: Function;
  onMeshLoaded: Function;
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
    onPreviewStart: () => console.log('ScandyCore: Preview Started'),
    onScannerStart: () => console.log('ScandyCore: Scanner Started'),
    onScannerStop: () => console.log('ScandyCore: Scanner Stoped'),
    onGenerateMesh: () => console.log('ScandyCore: Generated Mesh'),
    onSaveMesh: () => console.log('ScandyCore: Saved Mesh'),
    onMeshLoaded: () => console.log('Scandy Core: Mesh Loaded'),
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

  _onVisualizerReady = ({ nativeEvent }) => {
    if (this.props.onVisualizerReady) {
      this.props.onVisualizerReady(nativeEvent);
    }
    this._updateCoreState();
  };

  _onPreviewStart = ({ nativeEvent }) => {
    if (this.props.onPreviewStart) {
      this.props.onPreviewStart(nativeEvent);
    }
    this._updateCoreState();
  };

  _onScannerStart = ({ nativeEvent }) => {
    if (this.props.onScannerStart) {
      this.props.onScannerStart(nativeEvent);
    }
    this._updateCoreState();
  };

  _onScannerStop = ({ nativeEvent }) => {
    if (this.props.onScannerStop) {
      this.props.onScannerStop(nativeEvent);
    }
    this._updateCoreState();
  };

  _onGenerateMesh = ({ nativeEvent }) => {
    if (this.props.onGenerateMesh) {
      this.props.onGenerateMesh(nativeEvent);
    }
    this._updateCoreState();
  };

  _onSaveMesh = ({ nativeEvent }) => {
    if (this.props.onSaveMesh) {
      this.props.onSaveMesh(nativeEvent);
    }
    this._updateCoreState();
  };

  _onExportVolumetricVideo = ({ nativeEvent }) => {
    if (this.props.onExportVolumetricVideo) {
      this.props.onExportVolumetricVideo(nativeEvent);
    }
    this._updateCoreState();
  };

  _onClientConnected = ({ nativeEvent }) => {
    if (this.props.onClientConnected) {
      this.props.onClientConnected(nativeEvent.host);
    }
  };

  _onHostDiscovered = ({ nativeEvent }) => {
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

  _onVidSavedToCamRoll = ({ nativeEvent }) => {
    if (this.props.onVidSavedToCamRoll) {
      this.props.onVidSavedToCamRoll(nativeEvent);
    }
  };

  _startPreview = () => {
    ScandyCoreManager.startPreview().then(() => {
      if (this.props.onPreviewStart) {
        this.props.onPreviewStart();
      }
    });
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
          onPreviewStart={this._onPreviewStart}
          onScannerStart={this._onScannerStart}
          onScannerStop={this._onScannerStop}
          onGenerateMesh={this._onGenerateMesh}
          onSaveMesh={this._onSaveMesh}
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
  initializeScanner(): Promise<any>;
  startPreview(): Promise<any>;
  startScan(): Promise<any>;
  stopScan(): Promise<any>;
  generateMesh(): Promise<any>;
  saveScan(filePath: string): Promise<any>;
  setSize(size: number): Promise<any>;
  loadMesh(dict: object): Promise<any>;
  toggleV2Scanning(enabled: boolean): Promise<any>;
};

// const { RouxSdk } = NativeModules;

export default Roux as RouxType;
export { RouxView };

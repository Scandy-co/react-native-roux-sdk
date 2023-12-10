import React from 'react';
import {
  StyleSheet,
  View,
  Switch,
  TouchableOpacity,
  Alert,
  Text,
  Button,
  FlatList,
  SafeAreaView,
} from 'react-native';
import Slider from '@react-native-community/slider';
import Drawer from 'react-native-drawer';

import Roux, { RouxView } from 'react-native-roux-sdk';
import RNFS from 'react-native-fs';

const SCAN_DIR = `${RNFS.DocumentDirectoryPath}/meshes`;
export default class App extends React.Component {
  constructor(props: Readonly<{}>) {
    super(props);
    this.state = {
      scanState: '',
      savedMeshes: [],
      renderLoadedMesh: false,
      v2ScanningMode: null, //v2ScanningMode defaults to true
      scanSize: 1.0, // scan size in mm or meters pending on scanning mode
    };
  }

  handleScanStateChanged = (scanState) => {
    console.log('Scan State: ', scanState);
    this.setState({ scanState });
  };

  initializeScanner = async () => {
    try {
      await Roux.initializeScanner('true_depth');
    } catch (err) {
      console.warn(err);
    }
  };

  onInitializeScanner = async () => {
    if (!this.state.renderLoadedMesh) {
      try {
        await Roux.startPreview();
      } catch (e) {
        console.warn(e);
      }
    }
  };

  startScan = async () => {
    try {
      await Roux.startScan();
    } catch (err) {
      console.warn(err);
    }
  };

  stopScan = async () => {
    try {
      await Roux.stopScan();
    } catch (err) {
      console.warn(err);
    }
  };

  onStartPreview = () => {
    console.log('Preview Started');
  };

  onStartScanning = () => {
    console.log('Scanner Started');
  };

  onStopScanning = async () => {
    try {
      await Roux.generateMesh();
    } catch (err) {
      console.warn(err);
    }
  };

  onGenerateMesh = () => {
    // call back that generate mesh finished
    console.log('MESH GENERATED');
  };

  onSaveMesh = async () => {
    this.getSavedMeshes();
    if (!this.state.renderLoadedMesh) {
      this.restartScanner();
    }
  };

  restartScanner = async () => {
    if (this.state.renderLoadedMesh) {
      //Need to reinitialize scanner if we have a loaded mesh in our RouxView
      this.setState({ renderLoadedMesh: false, selectedMeshPath: '' });
      await Roux.uninitializeScanner();
      await Roux.initializeScanner('true_depth');
      this._drawer.close();
    }
    await Roux.startPreview();
  };

  saveScan = async () => {
    try {
      const filePath = `${SCAN_DIR}/${Date.now()}.ply`;
      await Roux.saveScan(filePath);
      Alert.alert('Saved scan', `Saved to: ${filePath}`);
    } catch (err) {
      console.warn(err);
    }
  };

  toggleV2Scanning = async () => {
    try {
      const v2ScanningMode = await Roux.getV2ScanningEnabled();
      await Roux.toggleV2Scanning(!v2ScanningMode);
      this.setState({ v2ScanningMode: !v2ScanningMode });
      this.setSize(this.state.scanSize);
    } catch (err) {
      console.warn(err);
    }
  };

  setSize = async (val: number) => {
    try {
      const size = this.state.v2ScanningMode ? val * 1e-3 : val;
      // Round the number to the tenth precision
      this.setState({ scanSize: Math.floor(val * 10) / 10 });
      await Roux.setSize(size);
    } catch (err) {
      console.warn(err);
    }
  };

  onLoadMesh = (e) => {
    console.log('Mesh loaded: ', e);
    this._drawer.close();
  };

  loadMesh = async (item) => {
    console.log(item);
    this.setState({ renderLoadedMesh: true });
    //Reinitialize scanner for loaded mesh
    await Roux.uninitializeScanner();
    await Roux.initializeScanner('true_depth');
    await Roux.loadMesh({ meshPath: item.path });
    this.setState({ selectedMeshPath: item.path });
  };

  getSavedMeshes = () => {
    RNFS.readDir(SCAN_DIR).then((readDirItems) => {
      const savedMeshes = readDirItems.map((item) => {
        const { path, name } = item;
        return { path, name };
      });
      this.setState({ savedMeshes });
    });
  };

  saveCleanedMesh = async () => {
    try {
      await Roux.applyEditsFromMeshViewport(true);
      await Roux.saveScan(this.state.selectedMeshPath);
    } catch (e) {
      console.warn(e);
    }
    console.log(status);
    this._drawer.open();
  };

  async componentDidMount() {
    //Get default scanning mode and set state
    await RNFS.mkdir(SCAN_DIR);
    this.getSavedMeshes();
    const v2ScanningMode = await Roux.getV2ScanningEnabled();
    this.setState({ v2ScanningMode });
  }

  render() {
    const { scanState, savedMeshes, renderLoadedMesh } = this.state;
    return (
      <View style={styles.container}>
        <Drawer
          ref={(ref) => (this._drawer = ref)}
          content={
            <SafeAreaView style={{ paddingBottom: 30, flex: 1 }}>
              <Text style={{ alignSelf: 'center', marginTop: 10 }}>Meshes</Text>
              <FlatList
                data={savedMeshes}
                renderItem={({ item, index }) => (
                  <TouchableOpacity
                    onPress={() => this.loadMesh(item)}
                    style={{ paddingHorizontal: 20, paddingVertical: 20 }}
                  >
                    <Text>{item.name}</Text>
                  </TouchableOpacity>
                )}
                keyExtractor={(item) => item.name}
              />
              <Button
                title="Back to scanner"
                onPress={this.restartScanner}
              ></Button>
            </SafeAreaView>
          }
        >
          <RouxView
            style={styles.roux}
            onScanStateChanged={this.handleScanStateChanged}
            onVisualizerReady={this.initializeScanner}
            onInitializeScanner={this.onInitializeScanner}
            onStartPreview={this.onStartPreview}
            onStartScanning={this.onStartScanning}
            onStopScanning={this.onStopScanning}
            onGenerateMesh={this.onGenerateMesh}
            onSaveMesh={this.onSaveMesh}
            onLoadMesh={this.onLoadMesh}
          />
          {(scanState === 'INITIALIZED' || scanState === 'PREVIEWING') &&
            !renderLoadedMesh && (
              <>
                <TouchableOpacity
                  onPress={this.startScan}
                  style={styles.button}
                >
                  <Text style={styles.buttonText}>Start Scanning</Text>
                </TouchableOpacity>
                <View style={styles.sliderContainer}>
                  <Slider
                    minimumValue={0.2}
                    maximumValue={4}
                    onSlidingComplete={this.setSize}
                    value={this.state.scanSize}
                    style={styles.slider}
                  />
                  <Text style={styles.previewLabel}>
                    size: {this.state.scanSize}
                    {this.state.v2ScanningMode ? 'mm' : 'm'}
                  </Text>
                </View>
                <View style={styles.v2SwitchContainer}>
                  <Switch
                    onValueChange={this.toggleV2Scanning}
                    value={this.state.v2ScanningMode}
                  />
                  <Text style={styles.previewLabel}>v2 scanning</Text>
                </View>
                <TouchableOpacity
                  style={{
                    ...styles.button,
                    backgroundColor: '#586168',
                    bottom: 40,
                    height: 50,
                  }}
                  onPress={() => {
                    this._drawer.open();
                  }}
                >
                  <Text style={styles.buttonText}>View meshes</Text>
                </TouchableOpacity>
              </>
            )}
          {scanState === 'SCANNING' && (
            <TouchableOpacity onPress={this.stopScan} style={styles.button}>
              <Text style={styles.buttonText}>STOP</Text>
            </TouchableOpacity>
          )}
          {scanState === 'VIEWING' && (
            <>
              <TouchableOpacity
                onPress={this.saveScan}
                style={{ ...styles.button, bottom: 150 }}
              >
                <Text style={styles.buttonText}>SAVE</Text>
              </TouchableOpacity>
              <TouchableOpacity
                onPress={this.restartScanner}
                style={styles.newScanButton}
              >
                <Text style={styles.buttonText}>NEW SCAN</Text>
              </TouchableOpacity>
            </>
          )}
          {renderLoadedMesh && (
            <>
              <TouchableOpacity
                style={{
                  ...styles.button,
                  backgroundColor: '#586168',
                  left: 20,
                  bottom: 40,
                  height: 50,
                }}
                onPress={() => {
                  this._drawer.open();
                }}
              >
                <Text style={styles.buttonText}>Go back</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={{
                  ...styles.button,
                  right: 0,
                  bottom: 40,
                  height: 50,
                }}
                onPress={this.saveCleanedMesh}
              >
                <Text style={styles.buttonText}>Save changes</Text>
              </TouchableOpacity>
              <View style={styles.actions}>
                {/* TODO: play around with the values passed to the editing functions to see their results - or, get fancy and implement a slider! */}
                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={async () => {
                    await Roux.decimateMesh(0.9);
                  }}
                >
                  <Text style={styles.buttonText}>Decimate</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={async () => {
                    await Roux.smoothMesh(10);
                  }}
                >
                  <Text style={styles.buttonText}>Smooth</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={async () => {
                    await Roux.fillHoles(1);
                  }}
                >
                  <Text style={styles.buttonText}>Fill Holes</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={async () => {
                    await Roux.extractLargestSurface(0.1);
                  }}
                >
                  <Text style={styles.buttonText}>Auto clean</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.actionButton}
                  onPress={async () => {
                    await Roux.makeWaterTight(13);
                  }}
                >
                  <Text style={styles.buttonText}>Make water tight</Text>
                </TouchableOpacity>
              </View>
            </>
          )}
        </Drawer>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  button: {
    position: 'absolute',
    alignSelf: 'center',
    justifyContent: 'center',
    alignItems: 'center',
    bottom: 200,
    paddingHorizontal: 10,
    height: 70,
    minWidth: 150,
    backgroundColor: '#f2494a',
  },
  newScanButton: {
    position: 'absolute',
    alignSelf: 'center',
    justifyContent: 'center',
    alignItems: 'center',
    bottom: 70,
    width: 150,
    height: 70,
    backgroundColor: '#586168',
  },
  buttonText: {
    fontSize: 24,
    color: 'white',
  },
  actions: {
    position: 'absolute',
    bottom: 100,
    backgroundColor: 'transparent',
    flex: 1,
    flexDirection: 'row',
    flexWrap: 'wrap',
    justifyContent: 'space-evenly',
  },
  actionButton: {
    backgroundColor: 'transparent',
    padding: 10,
    margin: 5,
    borderWidth: 1,
    borderColor: 'white',
  },
  sliderContainer: {
    position: 'absolute',
    bottom: 120,
    width: '80%',
    alignSelf: 'center',
  },
  previewLabel: {
    color: 'white',
    alignSelf: 'center',
    fontSize: 20,
  },
  v2SwitchContainer: {
    position: 'absolute',
    alignItems: 'center',
    top: 100,
    right: 10,
  },
  roux: { flex: 1, backgroundColor: 'blue' },
});

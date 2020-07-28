import React from 'react'
import {
  StyleSheet,
  View,
  Switch,
  TouchableOpacity,
  Alert,
  Text,
  Picker,
} from 'react-native'
import Slider from '@react-native-community/slider'
import SegmentedControl from '@react-native-community/segmented-control'

import Roux, { RouxView } from 'react-native-roux-sdk'
import RNFS from 'react-native-fs'

export default class App extends React.Component {
  constructor(props: Readonly<{}>) {
    super(props)
    this.state = {
      selectedDeviceType: 0,
      deviceIPAddress: '',
      connectedIPAddress: '',
      connectedToHost: false,
      displayIPPicker: true,
      discoveredHosts: [],
      scanState: '',
      v2ScanningMode: null, //v2ScanningMode defaults to true
      scanSize: 1.0, // scan size in mm or meters pending on scanning mode
    }
  }

  handleScanStateChanged = (scanState) => {
    console.log('Scan State: ', scanState)
    this.setState({ scanState })
  }

  initializeMirrorDevice = async () => {
    await Roux.setSendRenderedStream(false)
    await Roux.setReceiveNetworkCommands(false)
    await Roux.setReceiveRenderedStream(true)
    await Roux.setSendNetworkCommands(true)

    scannerType = 'network'

    try {
      //TODO: test error catching with no wifi
      var deviceIPAddress = await Roux.getIPAddress()
      this.setState({ deviceIPAddress })
      await Roux.setServerHost(deviceIPAddress)
    } catch (e) {
      console.log(e)
      this.setState({ deviceIPAddress: 'NOT CONNECTED TO WIFI' })
    }
    try {
      await Roux.initializeScanner('network')
      await Roux.startPreview()
    } catch (err) {
      console.warn(err)
    }
  }

  initializeScanningDevice = async () => {
    await Roux.setSendRenderedStream(true)
    await Roux.setReceiveNetworkCommands(true)
    await Roux.setReceiveRenderedStream(false)
    await Roux.setSendNetworkCommands(false)
    try {
      await Roux.initializeScanner('true_depth')
      var hosts = await Roux.getDiscoveredHosts()
      this.setState({ discoveredHosts: hosts, displayIPPicker: true })
    } catch (err) {
      console.warn(err)
    }
  }

  setupPreview = async () => {
    const { selectedDeviceType } = this.state

    switch (selectedDeviceType) {
      case 0: // Mirror device
        await this.initializeMirrorDevice()
        break
      case 1: // Scanner device
        await this.initializeScanningDevice()
        break
      default:
        break
    }
  }

  handleHostDiscovered = async () => {
    console.log('Host discovered')
    var hosts = await Roux.getDiscoveredHosts()
    this.setState({ discoveredHosts: hosts })
  }

  handleDeviceTypeToggled = async (e) => {
    let deviceType = e.nativeEvent.selectedSegmentIndex
    this.setState({ selectedDeviceType: deviceType })
    await Roux.uninitializeScanner()
    this.setupPreview()
  }

  startScan = async () => {
    try {
      status = await Roux.startScan()
      console.log(`startScan: ${status}`)
    } catch (err) {
      console.warn(err)
    }
  }

  stopScan = async () => {
    try {
      status = await Roux.stopScan()
      console.log(`stopScan: ${status}`)
    } catch (err) {
      console.warn(err)
    }
  }

  onPreviewStart = () => {
    console.log('Preview Started')
  }

  onScannerStart = () => {
    console.log('Scanner Started')
  }

  onScannerStop = async () => {
    try {
      await Roux.generateMesh()
    } catch (err) {
      console.warn(err)
    }
  }

  onGenerateMesh = () => {
    // call back that generate mesh finished
    console.log('MESH GENERATED')
    Alert.alert(
      'Scanning Complete',
      `Mesh has been generated on scanning device.`,
      [{ text: 'Take new scan', onPress: this.setupPreview }]
    )
  }

  onSaveMesh = async () => {
    // call back that generate mesh finished
    console.log('MESH SAVED')
    this.setupPreview()
  }

  saveScan = async () => {
    try {
      const dirPath = `${RNFS.DocumentDirectoryPath}/${Date.now()}`
      await RNFS.mkdir(dirPath)
      const filePath = `${dirPath}/scan.ply`
      status = await Roux.saveScan(filePath)
      Alert.alert('Saved scan', `Saved to: ${filePath}`)
    } catch (err) {
      console.warn(err)
    }
  }

  toggleV2Scanning = async () => {
    try {
      const v2ScanningMode = await Roux.getV2ScanningEnabled()
      await Roux.toggleV2Scanning(!v2ScanningMode)
      this.setState({ v2ScanningMode: !v2ScanningMode })
      this.setSize(this.state.scanSize)
    } catch (err) {
      console.warn(err)
    }
  }

  setSize = async (val: number) => {
    try {
      const size = this.state.v2ScanningMode ? val * 1e-3 : val
      this.setState({ scanSize: Math.floor(val * 10) / 10 })
      await Roux.setSize(size)
    } catch (err) {
      console.warn(err)
    }
  }

  handleIPAddressPickerChange = (IPAddress) => {
    this.setState({ connectedIPAddress: IPAddress })
  }

  connectToHost = async () => {
    try {
      await Roux.clearCommandHosts()
      await Roux.connectToCommandHost(this.state.connectedIPAddress)
      await Roux.setServerHost(this.state.connectedIPAddress)
      await Roux.startPreview()
      this.setState({ connectedToHost: true, displayIPPicker: false })
    } catch (e) {
      console.log(e)
    }
  }

  async componentDidMount() {
    //Get default scanning mode and set state
    const v2ScanningMode = await Roux.getV2ScanningEnabled()
    this.setState({ v2ScanningMode })
  }

  render() {
    const { scanState, discoveredHosts } = this.state
    const deviceType =
      this.state.selectedDeviceType === 0 ? 'MIRROR' : 'SCANNER'
    return (
      <View style={styles.container}>
        <RouxView
          style={styles.roux}
          onScanStateChanged={this.handleScanStateChanged}
          onVisualizerReady={this.setupPreview}
          onHostDiscovered={this.handleHostDiscovered}
          onPreviewStart={this.onPreviewStart}
          onScannerStart={this.onScannerStart}
          onScannerStop={this.onScannerStop}
          onGenerateMesh={this.onGenerateMesh}
          onSaveMesh={this.onSaveMesh}
        />
        <SegmentedControl
          style={styles.deviceToggle}
          values={['Mirror Device', 'Scanning Device']}
          selectedIndex={this.state.selectedDeviceType}
          onChange={(e) => this.handleDeviceTypeToggled(e)}
          backgroundColor={'#000'}
        />

        {/* MIRROR DEVICE SET UP */}
        {deviceType === 'MIRROR' && (
          <>
            <Text style={styles.ipAddressLabel}>
              IP Address: {this.state.deviceIPAddress}
            </Text>
            {(scanState === 'INITIALIZED' || scanState === 'PREVIEWING') && (
              <>
                <TouchableOpacity
                  onPress={this.startScan}
                  style={styles.button}
                >
                  <Text style={styles.buttonText}>START</Text>
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
              </>
            )}
            {scanState === 'SCANNING' && (
              <TouchableOpacity onPress={this.stopScan} style={styles.button}>
                <Text style={styles.buttonText}>STOP</Text>
              </TouchableOpacity>
            )}
            {scanState === 'VIEWING' && (
              <>
                {/* Nothing to see here! All mesh commands are rendered on the Scanning Device. */}
              </>
            )}
          </>
        )}
        {/* SCANNER DEVICE SET UP */}
        {deviceType === 'SCANNER' && (
          <>
            <Text style={styles.ipAddressLabel}>
              Connected to:{' '}
              {this.state.connectedToHost ? this.state.connectedIPAddress : ''}
            </Text>
            {(scanState === 'INITIALIZED' || scanState === 'PREVIEWING') && (
              <>
                {this.state.displayIPPicker ? (
                  <>
                    <View style={styles.IPAddressPickerContainer}>
                      <Picker
                        style={styles.IPAddressPicker}
                        selectedValue={this.state.connectedIPAddress || ''}
                        onValueChange={(IPAddress) =>
                          this.handleIPAddressPickerChange(IPAddress)
                        }
                      >
                        <Picker.Item
                          label={'Pick a Mirror Device'}
                          value={''}
                        />
                        {discoveredHosts &&
                          discoveredHosts.map((host) => {
                            return <Picker.Item label={host} value={host} />
                          })}
                      </Picker>
                    </View>
                    <TouchableOpacity
                      style={
                        this.state.connectedIPAddress
                          ? { ...styles.button, backgroundColor: '#3053FF' }
                          : {
                              ...styles.button,
                              backgroundColor: '#D3D3D3',
                              opacity: 0.5,
                            }
                      }
                      disabled={!this.state.connectedIPAddress}
                      onPress={this.connectToHost}
                    >
                      <Text style={styles.buttonText}>CONNECT</Text>
                    </TouchableOpacity>
                  </>
                ) : (
                  <>
                    <TouchableOpacity
                      style={{
                        ...styles.button,
                        backgroundColor: '#586168',
                        width: 300,
                      }}
                      onPress={() => {
                        this.setState({ displayIPPicker: true })
                      }}
                    >
                      <Text style={styles.buttonText}>
                        Change Mirror Device
                      </Text>
                    </TouchableOpacity>
                  </>
                )}
              </>
            )}
            {scanState === 'SCANNING' && (
              <>
                {/* Nothing to see here! All scan commands are rendered on the Mirror Device. */}
              </>
            )}
            {scanState === 'VIEWING' && (
              <>
                <TouchableOpacity onPress={this.saveScan} style={styles.button}>
                  <Text style={styles.buttonText}>Save Mesh</Text>
                </TouchableOpacity>
              </>
            )}
          </>
        )}
      </View>
    )
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  roux: { flex: 1, backgroundColor: 'blue' },
  ipAddressLabel: {
    position: 'absolute',
    top: 50,
    backgroundColor: '#3053FF',
    color: '#fff',
    padding: 5,
    fontSize: 18,
    width: '100%',
  },
  deviceToggle: {
    position: 'absolute',
    alignSelf: 'center',
    height: 50,
    width: 300,
    top: 90,
  },
  button: {
    position: 'absolute',
    alignSelf: 'center',
    justifyContent: 'center',
    alignItems: 'center',
    bottom: 150,
    width: 150,
    height: 70,
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
  sliderContainer: {
    position: 'absolute',
    bottom: 70,
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
    top: 150,
    right: 10,
  },
  IPAddressPickerContainer: {
    position: 'absolute',
    bottom: 270,
    width: '80%',
    alignSelf: 'center',
    backgroundColor: '#fff',
  },
})

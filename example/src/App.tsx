import * as React from 'react';
import { StyleSheet, View, Text } from 'react-native';
// import RouxSdk from 'react-native-roux-sdk';
import { Roux, RouxView } from 'react-native-roux-sdk';

export default class App extends React.Component{
  setup = async () => {
    try {
      await Roux.initializeScanner()
      await Roux.startPreview()
      
    }
    catch(err) {
      console.error(err)
    }
  }

  render() {
    return (
      <View style={styles.container}>
        <RouxView
          onVisualizerReady={this.setup} 
        />
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
});

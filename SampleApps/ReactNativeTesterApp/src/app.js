
import React, {Component} from 'react';
import {AppRegistry, StyleSheet, View, Text, TouchableOpacity} from 'react-native';
import 'detox-instruments-react-native-utils';

class ReactNativeTesterApp extends Component {
  constructor(props) {
    super(props);
    this.slowJSTimer = null;
    this.slowBridgeTimer = null;
    this.state = {counter: 0};
  }

  _performTask() {
    let counter = 0;
    for(let i = 0; i < Math.pow(2, 25); i++) {
      counter++;
    }
  }

  _startSlowJSTimer() {
    this._performTask();
    this.slowJSTimer = setTimeout(() => {
      this._startSlowJSTimer();
    }, 2000);
  }

  _startBusyBridgeTimer() {
    this.setState({counter: this.state.counter + 1}, () => {
      this.slowBridgeTimer = setTimeout(() => {
        this._startBusyBridgeTimer();
      }, 100);
    });
  }

  onSlowJSThread() {
    if(this.slowJSTimer) {
      clearTimeout(this.slowJSTimer);
      this.slowJSTimer = null;
    } else {
      this._startSlowJSTimer();
    }
  }

  onBusyBridge() {
    if(this.slowBridgeTimer) {
      clearTimeout(this.slowBridgeTimer);
      this.slowBridgeTimer = null;
    } else {
      this._startBusyBridgeTimer();
    }
  }

  render() {
    return (
      <View style={styles.container}>
        <TouchableOpacity style={styles.button} onPress={() => this.onSlowJSThread()}>
          <Text style={styles.buttonText}>Slow JS Thread</Text>
        </TouchableOpacity>
        <TouchableOpacity style={styles.button} onPress={() => this.onBusyBridge()}>
          <Text style={styles.buttonText}>Busy Bridge</Text>
        </TouchableOpacity>
        <Text>Counter: {this.state.counter}</Text>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  button: {
    height: 40,
    justifyContent: 'center'
  },
  buttonText: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
});

AppRegistry.registerComponent('ReactNativeTesterApp', () => ReactNativeTesterApp);

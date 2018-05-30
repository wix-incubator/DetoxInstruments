
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
		console.log("Slowing CPU!");
    this._performTask();
    this.slowJSTimer = setTimeout(() => {
      this._startSlowJSTimer();
    }, 3500);
  }

  _startBusyBridgeTimer() {
		if(this.state.counter == 200) {
			this.clearBusyBridgeTimeout();
			return;
		}
		
    this.setState({counter: this.state.counter + 1}, () => {
      this.slowBridgeTimer = setTimeout(() => {
        this._startBusyBridgeTimer();
      }, 30);
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

	clearBusyBridgeTimeout() {
		clearTimeout(this.slowBridgeTimer);
		this.slowBridgeTimer = null;
	}
	
  onBusyBridge() {
    if(this.slowBridgeTimer) {
			this.clearBusyBridgeTimeout();
    } else {
			this.setState({counter: 0}, () => {
											this._startBusyBridgeTimer();
										});
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

import MessageQueue from 'react-native/Libraries/BatchedBridge/MessageQueue.js';

const spyFunction = (msg) => {
	global.nativeLoggingHook(JSON.stringify(msg));
};

MessageQueue.spy(spyFunction);

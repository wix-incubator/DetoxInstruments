
import React, {Component} from 'react';
import {AppRegistry, StyleSheet, View, Text, TouchableOpacity} from 'react-native';
import 'detox-instruments-react-native-utils';

class ReactNativeLegacyTesterApp extends Component {
  constructor(props) {
    super(props);
    this.slowJSTimer = null;
    this.slowBridgeTimer = null;
    this.state = {counter: 0};
  }

  _performTask() {
    let counter = 0;
    for(let i = 0; i < Math.pow(2, 28); i++) {
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

  onLogObject() {
    const obj = {
      name: 'my name',
      age: 100,
      list1: [
        {
          key1: 'value1',
          key2: 'value2',
        },
        {
          key3: 'value3',
          key4: 'value4',
        }
      ],
      list2: [
        {
          key1: 'value1',
          key2: 'value2',
        },
        {
          key3: 'value3',
          key4: 'value4',
        }
      ]
    };
    console.log('log - my object', 'second message', obj, 'another message', Object.assign({}, obj));
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
        <TouchableOpacity style={styles.button} onPress={() => this.onLogObject()}>
          <Text style={styles.buttonText}>Log Object</Text>
        </TouchableOpacity>
        <Text style={{marginTop: 30}}>Bridge Activity Counter: {this.state.counter}</Text>
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

AppRegistry.registerComponent('ReactNativeLegacyTesterApp', () => ReactNativeLegacyTesterApp);

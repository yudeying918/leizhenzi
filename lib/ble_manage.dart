// Copyright 2017, Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'common/global.dart';


/*class FlutterBlueApp extends StatelessWidget {
  const FlutterBlueApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: StreamBuilder<BluetoothState>(
          stream: FlutterBluePlus.instance.state,
          initialData: BluetoothState.unknown,
          builder: (c, snapshot) {
            final state = snapshot.data;
            if (state == BluetoothState.on) {
              return FindDevicesScreen();
            }
            return BluetoothOffScreen(state: state);
          }),
    );
  }
}*/

/*class BluetoothOffScreen extends StatelessWidget {
  const BluetoothOffScreen({Key? key, this.state}) : super(key: key);
  final BluetoothState? state;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.lightBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.bluetooth_disabled,
              size: 200.0,
              color: Colors.white54,
            ),
            Text(
              'Bluetooth Adapter is ${state != null ? state.toString().substring(15) : 'not available'}.',
              style: Theme.of(context)
                  .primaryTextTheme
                  .subtitle2
                  ?.copyWith(color: Colors.white),
            ),
            ElevatedButton(
              child: const Text('TURN ON'),
              onPressed: Platform.isAndroid
                  ? () => FlutterBluePlus.instance.turnOn()
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}*/

class FindDevicesScreen extends StatefulWidget {
  FindDevicesScreen({Key? key}) : super(key: key);
  final List<BluetoothDevice> devicesList = <BluetoothDevice>[];
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {

  _addDeviceTolist(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device) && device.name.contains('FQ')) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  getAllBleList(){
    widget.flutterBlue.startScan(timeout: const Duration(seconds: 3));
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addDeviceTolist(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addDeviceTolist(result.device);
      }
    });
  }

  void connectDevice(BluetoothDevice _device) async {
    widget.flutterBlue.stopScan();
    try {
      await _device.connect();
    } on PlatformException catch (e) {
      if (e.code != 'already_connected') {
        rethrow;
      }
    }
    print(_device.name + ' is connected');
    // setState(() {
      Global.connectedDevice = _device;
      Global.isConnected = true;
    // });

  }

  void disConnectDevice(BluetoothDevice _device) {
    _device.disconnect();
    print(_device.name + ' is disconnected');
  }

  Column listAllBleResults(){
      List<Widget> containers = <Widget>[];
      for (BluetoothDevice device in widget.devicesList) {
        containers.add(
          SizedBox(
            height: 50,
            child: ListTile(
                        title: Text(device.name),
                        subtitle: Text(device.id.toString()),
                        trailing: StreamBuilder<BluetoothDeviceState>(
                          stream: device.state,
                          initialData: BluetoothDeviceState.connecting,
                          builder: (c, snapshot) {
                            VoidCallback? onPressed;
                            String text;
                            switch (snapshot.data) {
                              case BluetoothDeviceState.connected:
                                onPressed = () => disConnectDevice(device);
                                text = 'DISCONNECT';
                                break;
                              case BluetoothDeviceState.disconnected:
                                onPressed = () => connectDevice(device);
                                text = 'CONNECT';
                                break;
                              default:
                                onPressed = null;
                                text = snapshot.data.toString().substring(21).toUpperCase();
                                break;
                            }
                            return TextButton(
                                onPressed: onPressed,
                                child: Text(
                                  text,
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .button
                                      ?.copyWith(color: Colors.blue),
                                ));
                          },
                        ),
                      )
                ),
            );
      }

      return Column(
        children: <Widget>[
          ...containers,
        ],
      );
    }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAllBleList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Devices'),
        leading: IconButton(icon:Icon(Icons.arrow_back),
          onPressed: () {
            return Navigator.pop(context,true);
          },),
      ),
      body:
          listAllBleResults(),

      floatingActionButton: StreamBuilder<bool>(
        stream: FlutterBluePlus.instance.isScanning,
        initialData: false,
        builder: (c, snapshot) {
          if (snapshot.data!) {
            return FloatingActionButton(
              child: const Icon(Icons.stop),
              onPressed: () => FlutterBluePlus.instance.stopScan(),
              backgroundColor: Colors.red,
            );
          } else {
            return FloatingActionButton(
                child: const Icon(Icons.search),
                onPressed: () => getAllBleList(),
                    // FlutterBluePlus.instance
            );    // .startScan(timeout: const Duration(seconds: 4)));
          }
        },
      ),
    );
  }



}







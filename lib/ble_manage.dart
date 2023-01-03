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
/*insure that there is only one connected device*/
    widget.flutterBlue.stopScan();
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        device.disconnect();
      }
    });

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

  List<Widget> listAllBleResults(){
      List<Widget> list = <Widget>[];
      for (BluetoothDevice device in widget.devicesList) {
        list.add(
          // SizedBox(
          //   height: 50,
          //   child:
           ListTile(
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
                                text = '断开连接';
                                break;
                              case BluetoothDeviceState.disconnected:
                                onPressed = () => connectDevice(device);
                                text = '连接';
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
                                      ?.copyWith(color: Colors.pinkAccent),
                                ));
                          },
                        ),
                      )
                );
            // );
      }

      // return ListView()
      //   children: <Widget>[
      //     ...containers,
      //   ],
    return list;
      // );
    }



  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAllBleList();
  }

  @override
  Widget build(BuildContext context) {
    print('ble page build');

    return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            title: const Text('设备连接',style: TextStyle(color: Colors.black),),
            leading: IconButton(icon:Icon(Icons.arrow_back),color: Colors.black,
              onPressed: () {
                return Navigator.pop(context,true);
              },),
          ),
          body:
          Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                    border: Border.all(width: 1.0,color: Colors.black26),
                    borderRadius: BorderRadius.all(Radius.circular(10.0))
                ),
                height: 400,
                padding: EdgeInsets.only(top: 5.0,left: 5.0,right: 5.0),
                margin: EdgeInsets.only(left: 10.0,right: 10.0),
                child: ListView(
                  children: listAllBleResults(),
                ),
              ),
              Container(
                height: 50,
                margin: EdgeInsets.symmetric(vertical: 30.0,horizontal: 10.0),
                // padding: EdgeInsets.all(10),
                child: StreamBuilder<bool>(
                  stream: FlutterBluePlus.instance.isScanning,
                  initialData: false,
                  builder: (c,snapshot){
                    if(snapshot.data!){
                      return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.pinkAccent,
                            backgroundColor: Colors.white,
                            side: BorderSide(color: Colors.pinkAccent, width: 1),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.all(Radius.circular(30.0))
                            ),
                            padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                            // padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 10.0),
                          ),
                          onPressed: () =>FlutterBluePlus.instance.stopScan(),
                          child:
                          Text('停止扫描',
                              style: TextStyle(
                                fontSize: 15.0,))
                      );
                    }else{
                      return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black,
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.pinkAccent, width: 1),
                      shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0))
                      ),
                      padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                      // padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 10.0),
                      ),
                      onPressed: () { getAllBleList(); },
                      child:
                      Text('重新扫描',
                      style: TextStyle(
                    fontSize: 15.0,))
                    );
                    }
                  },
                )
              )
            ],
          ),


          // listAllBleResults(),

          /*floatingActionButton: StreamBuilder<bool>(
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
      ),*/
        );
  }



}







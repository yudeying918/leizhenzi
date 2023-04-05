import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'common/global.dart';
import 'package:permission_handler/permission_handler.dart';

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<BluetoothDevice> devicesList = [];
  List<BluetoothDevice> connectedDevicesList = [];
  StreamSubscription<ScanResult>? _scanSubscription;
  bool _isConnecting = false;
  int? _connectingIndex;

  @override
  void initState() {
    super.initState();

    flutterBlue.state.listen((state) {
      if (state == BluetoothState.on) {
        _getConnectedDevices();
        _scanForDevices();
      }
    });
    print(
        'initState connectedDevicesList is ' + connectedDevicesList.toString());
    // print('initState Global.connectedDevice is ' + Global.connectedDevice.toString());
    print('initState instance.connectedDevices is ' +
        flutterBlue.connectedDevices.toString());
  }

  Future<void> _getConnectedDevices() async {
    final List<BluetoothDevice> connected = await flutterBlue.connectedDevices;
    setState(() {
      connectedDevicesList = connected;
    });
  }

  void _scanForDevices() {
    // _scanSubscription?.cancel();
    devicesList.clear();
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
    flutterBlue.scanResults.listen(
      (List<ScanResult> results) {
        for (ScanResult result in results) {
          if (result.device.name.isNotEmpty) {
            if (!devicesList.contains(result.device)) {
              setState(() {
                devicesList.add(result.device);
              });
            }
          }
          if (_isDeviceConnected(result.device) &&
              !connectedDevicesList.contains(result.device)) {
            setState(() {
              connectedDevicesList.add(result.device);
            });
          }
        }
      },
    );
  }



  bool _isDeviceConnected(BluetoothDevice device) {
    return device.state == BluetoothDeviceState.connected;
  }


  void _connectToDevice(int index) async {
    final device = devicesList[index];
    flutterBlue.stopScan();
    flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        device.disconnect();
        setState(() {
          devicesList.add(device);
          connectedDevicesList.remove(device);
        });
      }
    });

    setState(() {
      _connectingIndex = index;
    });

    try {
      await device.connect(
          timeout: const Duration(seconds: 10), autoConnect: false);

      setState(() {
        connectedDevicesList.add(device);
        print('connectedDevicesList is ' + connectedDevicesList.toString());
        devicesList.remove(device);
        print('devicesList is ' + devicesList.toString());
        Global.connectedDevice = device;
        print('Global.connectedDevice is ' + Global.connectedDevice.toString());
        Global.isConnected = true;
        // _isConnecting = false;
        _connectingIndex = null;
      });
    } catch (e) {
      /*setState(() {
        _isConnecting = false;
      });*/
      print('连接设备失败：$e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('连接设备失败'),
          content: Text('请检查设备是否开启蓝牙并且在可连接范围内'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('确定'),
            ),
          ],
        ),
      );
    } /*finally {
      setState(() {
        _isLoading = false;
      });
    }*/
  }

  void _disconnectDevice(BluetoothDevice device) {
    device.disconnect();
    setState(() {
      devicesList.add(device);
      print('devicesList is ' + devicesList.toString());
      connectedDevicesList.remove(device);
      print('connectedDevicesList is ' + connectedDevicesList.toString());
      Global.isConnected = false;
      print('Global.connectedDevice is ' + Global.connectedDevice.toString());
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('build ble page');
    return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          title: const Text(
            '设备连接',
            style: TextStyle(color: Colors.black),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: Colors.black,
            onPressed: () {
              return Navigator.pop(context, true);
            },
          ),
        ),
        body: Column(children: <Widget>[
          SizedBox(
            height: 50,
            child: connectedDevicesList.isNotEmpty
                ? ListView.builder(
                    itemCount: connectedDevicesList.length,
                    itemBuilder: (context, index) {
                      final device = connectedDevicesList[index];
                      return ListTile(
                        title: Text(device.name),
                        trailing: OutlinedButton(
                          onPressed: () => _disconnectDevice(device),
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.black,
                              side: const BorderSide(
                                  width: 1, color: Colors.pinkAccent)),
                          child: const Text('已连接'),
                        ),
                      );
                    },
                  )
                : const Center(child: Text('没有已连接设备')),
          ),
          /*Column(
            children: _getConnectedBleList(),
          ),*/
          const Divider(),
          // if (devicesList.isNotEmpty) ...[

          /*ListTile(
                  title: const Text('Available Devices'),
                ),*/
          SizedBox(
            height: 400,
            child: devicesList.isNotEmpty
                ? ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                final device = devicesList[index];
                _isConnecting = index == _connectingIndex;
                return ListTile(
                  title: Text(device.name),
                  trailing: OutlinedButton(
                    onPressed: () => _isConnecting? null: _connectToDevice(index),
                    style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(
                            width: 1, color: Colors.pinkAccent)),
                    child: _isConnecting? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.pinkAccent),
                    ): const Text('连接'),
                  ),
                );
              },
            )
                : const Center(child: Text('没有可连接设备')),
          ),


          const Divider(),
          // ],
          Padding(
              padding: const EdgeInsets.all(8.0),
              child: StreamBuilder<bool>(
                stream: FlutterBluePlus.instance.isScanning,
                initialData: false,
                builder: (c, snapshot) {
                  if (snapshot.data!) {
                    return OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.pinkAccent,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.pinkAccent, width: 1),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.all(Radius.circular(30.0))),
                        padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                        // padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 10.0),
                      ),
                      onPressed: () => FlutterBluePlus.instance.stopScan(),
                      child: CircularProgressIndicator(
                        color: Colors.pinkAccent,
                      ),
                    );
                  } else {
                    return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.pinkAccent, width: 1),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(30.0))),
                          padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                          // padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 10.0),
                        ),
                        onPressed: () => _scanForDevices(),
                        child: Text('重新扫描',
                            style: TextStyle(
                              fontSize: 15.0,
                            )));
                  }
                },
              )),
          const Text('version v0324.01 debug ')
        ]));
  }
}

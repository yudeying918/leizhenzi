import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'common/global.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FindDevicesScreen extends StatefulWidget {
  const FindDevicesScreen({Key? key}) : super(key: key);

  @override
  State<FindDevicesScreen> createState() => _FindDevicesScreenState();
}

class _FindDevicesScreenState extends State<FindDevicesScreen> {
  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<BluetoothDevice> devicesList = [];
  List<BluetoothDevice> connectedDevicesList = [];
  bool _isConnecting = false;
  int? _connectingIndex;

  @override
  void initState() {
    super.initState();
    // checkPermissionStatus();

    if (kDebugMode) {
      print('界面初始化进行');
    }

    flutterBlue.state.listen((state) {
      if (state == BluetoothState.on) {
        if (kDebugMode) {
          print('搜索初始化进行');
        }
        _getConnectedDevices();
        _scanForDevices();
      }
      else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('蓝牙未开启'),
            content: const Text('请开启设备蓝牙'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('确定'),
              ),
            ],
          ),
        );
      }
    });
    if (kDebugMode) {
      print('初始化时connectedDevicesList is $connectedDevicesList');
    }
    if(Global.isConnected){
      if (kDebugMode) {
        print('初始化时Global.connectedDevice is ${Global.connectedDevice}');
      }
    }
    if (kDebugMode) {
      print('初始化时devicesList is $devicesList');
    }
  }

  Future<void> checkPermissionStatus() async {
    PermissionStatus  locationStatus = await Permission.location.status;
    if (kDebugMode) {
      print('检测权限状态$locationStatus');
    }
    if(locationStatus != PermissionStatus.granted){
      locationStatus = await Permission.location.request();
      if (kDebugMode) {
        print('请求位置权限后$locationStatus');
      }
    }

    /* if (status.isGranted) {
      //权限通过
      if (kDebugMode) {
        print('status 的状态是status.isGranted');
      }
    } else if (status.isDenied) {
      //权限拒绝， 需要区分IOS和Android，二者不一样
      if (kDebugMode) {
        print('status 的状态是status.isDenied');
      }
      requestPermission();
    } else if (status.isPermanentlyDenied) {
      //权限永久拒绝，且不在提示，需要进入设置界面
      if (kDebugMode) {
        print('status 的状态是status.isPermanentlyDenied');
      }
      openAppSettings();
    } else if (status.isRestricted) {
      if (kDebugMode) {
        print('status 的状态是status.isRestricted');
      }
      //活动限制（例如，设置了家长///控件，仅在iOS以上受支持。
      openAppSettings();
    } else {
      if (kDebugMode) {
        print('这是第一次申请定位权限');
      }
      //第一次申请
      requestPermission();
    }*/

  }

  Future<void> requestPermission() async {
    final status = await Permission.location.request();
    if (kDebugMode) {
      print('请求权限状态$status');
    }
    /*if (!status.isGranted) {
      openAppSettings();
    }*/
  }

  Future<void> _getConnectedDevices() async {
    final List<BluetoothDevice> connected = await flutterBlue.connectedDevices;
    if(mounted){
      setState(() {
        connectedDevicesList = connected;
      });
    }
  }

  void _scanForDevices() {
    devicesList.clear();
    if (kDebugMode) {
      print('devicesList被清除了，devicesList is $devicesList');
    }
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
    if (kDebugMode) {
      print('初始化扫描完成');
    }
    flutterBlue.scanResults.listen(
          (List<ScanResult> results) {
        for (ScanResult result in results) {
          if (result.device.name.isNotEmpty) {
            if (!devicesList.contains(result.device)) {
              if(mounted){
                setState(() {
                  devicesList.add(result.device);
                });
              }
            }
          }
        }
        if(Global.isConnected && devicesList.contains(Global.connectedDevice)){
          if (kDebugMode) {
            print('判断devicesList是否包含已连接设备');
          }
          devicesList.remove(Global.connectedDevice);
        }
        if (kDebugMode) {
          print('初始化扫描完成devicesList is $devicesList');
        }
      },
    );
  }

/*
  bool _isDeviceConnected(BluetoothDevice device) {
    print('判断当前设备是否已经连接');
    return device.state == BluetoothDeviceState.connected;
  }
*/


  void _connectToDevice(int index) async {
    final device = devicesList[index];
    flutterBlue.stopScan();
    flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        device.disconnect();
        if(mounted){
          setState(() {
            devicesList.add(device);
            connectedDevicesList.remove(device);
          });
        }
      }
    });

    if(mounted){
      setState(() {
        _connectingIndex = index;
      });
    }

    try {
      await device.connect(
          timeout: const Duration(seconds: 10), autoConnect: false);

      if(mounted){
        setState(() {
          connectedDevicesList.add(device);
          if (kDebugMode) {
            print('连接后connectedDevicesList is $connectedDevicesList');
          }
          devicesList.remove(device);
          if (kDebugMode) {
            print('连接后devicesList is $devicesList');
          }
          Global.connectedDevice = device;
          if (kDebugMode) {
            print('连接后Global.connectedDevice is ${Global.connectedDevice}');
          }
          Global.isConnected = true;
          _connectingIndex = null;
        });
      }

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastDeviceId', device.id.toString());
      if (kDebugMode) {
        print('保存最后一次连接设备到本地lastDeviceId is ${device.id}');
      }

    } catch (e) {
      if (kDebugMode) {
        print('连接设备失败：$e');
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('连接设备失败'),
          content: const Text('请检查设备是否开启蓝牙并且在可连接范围内'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('确定'),
            ),
          ],
        ),
      );
    }
  }

  void _disconnectDevice(BluetoothDevice device) {
    device.disconnect();
    if(mounted){
      setState(() {
        devicesList.add(device);
        if (kDebugMode) {
          print('断开连接后devicesList is $devicesList');
        }
        connectedDevicesList.remove(device);
        if (kDebugMode) {
          print('断开连接后connectedDevicesList is $connectedDevicesList');
        }
        Global.isConnected = false;
        if (kDebugMode) {
          print('断开连接后Global.connectedDevice is ${Global.connectedDevice}');
        }
      });
    }
  }
  //save the last connected device
/*  saveLastConnectedDevice() async {

    if(Global.isConnected) {
      lastDevice = Global.connectedDevice;
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('lastDeviceId', lastDevice.id.toString());
      if (kDebugMode) {
        print('保存最后一次连接设备到本地lastDeviceId is ${lastDevice.id}');
      }
    }
  }*/

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('build设备连接界面');
    }
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
            child: Global.isConnected
                ? ListView.builder(
              itemCount: 1,
              itemBuilder: (context, index) {
                final device = Global.connectedDevice;
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
                        side: const BorderSide(color: Colors.pinkAccent, width: 1),
                        shape: const RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(30.0))),
                        padding: const EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                        // padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 10.0),
                      ),
                      onPressed: () => FlutterBluePlus.instance.stopScan(),
                      child: const CircularProgressIndicator(
                        color: Colors.pinkAccent,
                      ),
                    );
                  } else {
                    return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.pinkAccent, width: 1),
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(30.0))),
                          padding: const EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                          // padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 10.0),
                        ),
                        onPressed: () => _scanForDevices(),
                        child: const Text('重新扫描',
                            style: TextStyle(
                              fontSize: 15.0,
                            )));
                  }
                },
              )),
          const Text('version v0513.01 release')
        ]));
  }
}

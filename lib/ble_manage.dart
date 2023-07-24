import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'common/global.dart';

class FindDeviceDialog extends StatefulWidget {
  const FindDeviceDialog({super.key});

  @override
  State<FindDeviceDialog> createState() => FindDeviceDialogState();
}

class FindDeviceDialogState extends State<FindDeviceDialog> {

  final FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  List<BluetoothDevice> devicesList = [];
  List<BluetoothDevice> connectedDevicesList = [];
  bool _isConnecting = false;
  int? _connectingIndex;
  late BluetoothCharacteristic connectedDeviceChar;

  @override
  void initState() {
    super.initState();
    flutterBlue.state.listen((state) {
      if (state == BluetoothState.on) {
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
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      title: const Text('搜索设备'),
      content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              height: 50,
              child: Global.isConnected
                  ? ListView.builder(
                // physics: const NeverScrollableScrollPhysics(),
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
                              width: 1, color: Colors.tealAccent)),
                      child: const Text('已连接'),
                    ),
                  );
                },
              )
                  : const Center(child: Text('没有已连接设备')),
            ),

            const Divider(),
            /*ListTile(
                  title: const Text('Available Devices'),
                ),*/
            SizedBox(
              height: 200,
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
                              width: 1, color: Colors.tealAccent)),
                      child: _isConnecting? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.tealAccent),
                      ): const Text('连接'),
                    ),
                  );
                },
              )
                  : const Center(child: Text('没有可连接设备')),
            ),
            const Divider(),
            Padding(
                padding: const EdgeInsets.all(8.0),
                child: StreamBuilder<bool>(
                  stream: FlutterBluePlus.instance.isScanning,
                  initialData: false,
                  builder: (c, snapshot) {
                    if (snapshot.data!) {
                      return OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.tealAccent,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: Colors.tealAccent, width: 1),
                          shape: const RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.all(Radius.circular(30.0))),
                          padding: const EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                          // padding: EdgeInsets.symmetric(vertical: 5.0,horizontal: 10.0),
                        ),
                        onPressed: () => FlutterBluePlus.instance.stopScan(),
                        child: const CircularProgressIndicator(
                          color: Colors.tealAccent,
                        ),
                      );
                    } else {
                      return OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black,
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.tealAccent, width: 1),
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

          ]),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('关闭'),
        ),
      ],
    );
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
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
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
          devicesList.remove(Global.connectedDevice);
        }
      },
    );
  }


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
          devicesList.remove(device);
          Global.connectedDevice = device;
          Global.isConnected = true;
          _connectingIndex = null;
        });
      }
      Navigator.of(context).pop(true);
    } catch (e) {
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
    // _getDeviceServices();
  }

  void _getDeviceServices() async{
    List<BluetoothService> services =
    await Global.connectedDevice.discoverServices();
    for (BluetoothService s in services) {
      if (s.uuid.toString().toUpperCase().substring(4, 8) == "FFF0") {
        for (BluetoothCharacteristic c in s.characteristics) {
          if (c.uuid.toString().toUpperCase().substring(4, 8) == "FFF1") {
            connectedDeviceChar = c; // get the characteristic of the connected device
          }
        }
      }
    }
  }


  void _disconnectDevice(BluetoothDevice device) {
    device.disconnect();
    if(mounted){
      setState(() {
        devicesList.add(device);
        connectedDevicesList.remove(device);
        Global.isConnected = false;
      });
    }
  }


}

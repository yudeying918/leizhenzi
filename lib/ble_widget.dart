import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';


late final BluetoothDevice bleDevice;
late final FlutterBluePlus flutterBlue;
late final Map<String, ScanResult> scanResults;
late final List allBleNameAry;
late final BluetoothCharacteristic mCharacteristic;

class ScanResultsList extends StatelessWidget {
  const ScanResultsList({Key? key,}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (bleDevice.name.isNotEmpty && bleDevice.name.contains('FQ') ){
      return ListTile(
          title: Text(bleDevice.name),
          subtitle: Text(bleDevice.id.toString()),
          trailing: StreamBuilder<BluetoothDeviceState>(
            stream: bleDevice.state,
            initialData: BluetoothDeviceState.connecting,
            builder: (c, snapshot) {
              VoidCallback? onPressed;
              String text;
              switch (snapshot.data) {
                case BluetoothDeviceState.connected:
                  onPressed = () => bleDevice.disconnect();
                  text = 'DISCONNECT';
                  break;
                case BluetoothDeviceState.disconnected:
                  onPressed = () => bleDevice.connect();
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
                    style: Theme
                        .of(context)
                        .primaryTextTheme
                        .button
                        ?.copyWith(color: Colors.blue),
                  ));
            },
          )
      );
    }

    else {
      return Container();
    }
  }
}

void startBle() async {
  // 开始扫描
  flutterBlue.startScan(timeout: Duration(seconds: 4));
  // 监听扫描结果
  flutterBlue.scanResults.listen((results) {
    // 扫描结果 可扫描到的所有蓝牙设备
    for (ScanResult r in results) {
      scanResults[r.device.name] = r;
      if (r.device.name.isNotEmpty) {
        // print('${r.device.name} found! rssi: ${r.rssi}');
        allBleNameAry.add(r.device.name);
        getBleScanNameAry();
      }
    }
  });
}

List getBleScanNameAry() {
  //更新过滤蓝牙名字
  List distinctIds = allBleNameAry.toSet().toList();
  allBleNameAry = distinctIds;
  return allBleNameAry;
}

void connectionBle(int chooseBle) {
  for (var i = 0; i < allBleNameAry.length; i++) {
    bool isBleName = allBleNameAry[i].contains("GTRS");
    if (isBleName) {
      ScanResult? r = scanResults[allBleNameAry[i]];
      bleDevice = r!.device;
      // 停止扫描
      flutterBlue.stopScan();

      discoverServicesBle();
    }
  }
}

void discoverServicesBle() async {
  print("连接上蓝牙设备...延迟连接");
  await bleDevice
      .connect(autoConnect: false, timeout: Duration(seconds: 10));
  List<BluetoothService> services = await bleDevice.discoverServices();
  services.forEach((service) {
    var value = service.uuid.toString();
    print("所有服务值 --- $value");
    if (service.uuid.toString().toUpperCase().substring(4, 8) == "FFF0") {
      List<BluetoothCharacteristic> characteristics = service.characteristics;
      characteristics.forEach((characteristic) {
        var valuex = characteristic.uuid.toString();
        print("所有特征值 --- $valuex");
        if (characteristic.uuid.toString() ==
            "0000fff1-0000-1000-8000-xxxxxxxxx") {
          print("匹配到正确的特征值");
          mCharacteristic = characteristic;

          const timeout = const Duration(seconds: 30);
          Timer(timeout, () {
            dataCallbackBle();
          });
        }
      });
    }
    // do something with service
  });
}

dataCallsendBle(List<int> value) {
  mCharacteristic.write(value);
}

dataCallbackBle() async {
  await mCharacteristic.setNotifyValue(true);
  mCharacteristic.value.listen((value) {
    // do something with new value
    // print("我是蓝牙返回数据 - $value");
    if (value == null) {
      print("我是蓝牙返回数据 - 空！！");
      return;
    }
    List data = [];
    for (var i = 0; i < value.length; i++) {
      String dataStr = value[i].toRadixString(16);
      if (dataStr.length < 2) {
        dataStr = "0" + dataStr;
      }
      String dataEndStr = "0x" + dataStr;
      data.add(dataEndStr);
    }
    print("我是蓝牙返回数据 - $data");
  });
}

void endBle() {
  bleDevice.disconnect();
}

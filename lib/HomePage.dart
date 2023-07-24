import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ble_manage.dart';
import 'common/global.dart';
import 'app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'slider_view.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String connectedDeviceNameText = '未连接设备';
  var massageModeNum = 0x00;
  var massageTimeHighNum = 0x00;
  var massageTimeLowNum = 0x0F;
  var massageStrengthNum = 0x32;
  var isMassaging = false;

  late BluetoothCharacteristic connectedDeviceChar;
  DateTime? _lastQuitTime;
  String batteryImageLink = 'images/battery-4.png';
  bool isCharging = false;
  bool _isChargeHide = true;
  bool _isBatteryHide = true;
  bool _isMassageGifShow = false;
  int _selectedGroup3Index = 0;

  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;

  double strengthValue = 50.0;
@override
void initState() {
    super.initState();
    // _checkBluetoothState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Theme(
        data: HotelAppTheme.buildLightTheme(),
        child: Scaffold(
          body:  Column(
                  children: <Widget>[
                    getAppBarUI(),
                    Expanded(
                      child: SingleChildScrollView(
                        // controller: _scrollController,
                          child: Column(
                            children: <Widget>[
                              deviceBatteryUI(),
                              const SizedBox(height: 10),
                              massageAnimationUI(),
                              const SizedBox(height: 10),
                              strengthSliderBarUI(),
                              const SizedBox(height: 10),
                              normalModeUI(),
                            ],
                          )
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 16, right: 16, bottom: 16, top: 8),
                    child: massageControlUI(),
                    )
                  ],
                ),
        ),
      ),

      onWillPop: () async {
        if (_lastQuitTime == null ||
            DateTime.now().difference(_lastQuitTime!).inSeconds > 1) {
          if (kDebugMode) {
            print('再按一次Back键退出');
          }
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('再按一次返回键退出')));
          _lastQuitTime = DateTime.now();
          return false;
        } else {
          if (kDebugMode) {
            print('退出');
          }
          disconnectConnectedDevice();
          // Navigator.of(context).pop(true);
          return true;
        }
      },
    );
  }

  Widget getAppBarUI() {
    return Container(
      decoration: BoxDecoration(
        color: HotelAppTheme.buildLightTheme().colorScheme.background,
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              offset: const Offset(0, 2),
              blurRadius: 8.0),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top, left: 8, right: 8),
        child: Row(
          children: <Widget>[
            Container(
              alignment: Alignment.centerLeft,
              width: AppBar().preferredSize.height + 40,
              height: AppBar().preferredSize.height,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(32.0),
                  ),
                  onTap: () {
                    // Navigator.pop(context);
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    // child: Icon(Icons.close),
                  ),
                ),
              ),
            ),
            const Expanded(
              child: Center(
                child: Text(
                  'leizhenzi',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            SizedBox(
              width: AppBar().preferredSize.height + 40,
              height: AppBar().preferredSize.height,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.all(
                        Radius.circular(32.0),
                      ),
                      onTap: () => Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                            builder: (context) => const FindDeviceDialog()),
                      )
                          .then((value) => _getRequests()),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.bluetooth,color: Colors.tealAccent,),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget deviceBatteryUI() {
    return Container(
      margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
      height: 50,
      /*decoration: BoxDecoration(
          border: Border.all(width: 1.0, color: Colors.black12),
          //   color: Colors.black26,
          borderRadius: const BorderRadius.all(Radius.circular(10.0))),*/
      child: Row(
        children: [
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(connectedDeviceNameText,
              textAlign: TextAlign.left,
              style: TextStyle(
                  color: Colors.grey,
                  fontSize: MediaQuery.of(context).size.width > 360 ? 18 : 16,
                  fontWeight: FontWeight.normal),),
          ),
          Offstage(
            offstage: _isChargeHide,
            child: Image.asset(
              'images/battery-charging.png',
              width: 30,
            ),
          ),
          Offstage(
            offstage: _isBatteryHide,
            child: Image.asset(
              batteryImageLink,
              width: 30,
            ),
          ),
          const SizedBox(
            width: 20,
          )
        ],
      ),
    );
  }

  Widget massageAnimationUI() {
    return Column(
      children: [
        Container(
          // height: 65,
          margin: const EdgeInsets.only(top: 0, left: 10, right: 10),
          child: Visibility(
            visible: _isMassageGifShow,
            replacement: Image.asset(
              'images/massage_0.png',
              // width: 394.0,
            ),
            // maintainState: true,
            // maintainAnimation: true,
            // maintainSize: false,
            child: Image.asset(
              'images/massage_active.gif',
              // width: 394.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget massageControlUI(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
              side:
              const BorderSide(color: Colors.tealAccent, width: 1),
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(30.0),
                      right: Radius.circular(30.0))),
              padding:
              const EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
            ),
            onPressed: () => startMassageDataSend(),
            child: const Text('开始按摩',
                style: TextStyle(
                  fontSize: 16.0,
                ))),
        const SizedBox(width: 20,),
        ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white,
              side:
              const BorderSide(color: Colors.tealAccent, width: 1),
              shape: const RoundedRectangleBorder(
                // borderRadius: BorderRadius.all(Radius.circular(10))
                  borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(30.0),
                      right: Radius.circular(30.0))),
              padding:
              const EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
            ),
            onPressed: () => stopMassageDataSend(),
            child: const Text('停止按摩',
                style: TextStyle(
                  fontSize: 16.0,
                ))),
      ],
    );
  }

  Widget strengthSliderBarUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding:
          const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 3),
          child: Text(
            '按摩强度',
            textAlign: TextAlign.left,
            style: TextStyle(
                color: Colors.grey,
                fontSize: MediaQuery.of(context).size.width > 360 ? 18 : 16,
                fontWeight: FontWeight.normal),
          ),
        ),
        SliderView(
          distValue: strengthValue,
          onChangedistValue: (double value) {
            strengthValue = value;
            massageStrengthNum = strengthValue.round();
            writeMToBle();
          },
        ),
        const SizedBox(
          height: 8,
        ),
      ],
    );
  }

  Widget normalModeUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            Padding(
              padding:
              const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 8),
              child: Text(
                '按摩模式',
                textAlign: TextAlign.left,
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: MediaQuery.of(context).size.width > 360 ? 18 : 16,
                    fontWeight: FontWeight.normal),
              ),
            ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 20,),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGroup3Index = 0;
                  massageModeNum = 0x00;
                });
                writeMToBle();
              },
              child: AnimatedContainer(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                  // shape: BoxShape.circle,
                  border: Border.all(
                      color: _selectedGroup3Index == 0
                          ? Colors.tealAccent
                          : Colors.black),
                  color: _selectedGroup3Index == 0
                      ? Colors.tealAccent
                      : Colors.white,
                ),
                child: Text("模式1",
                    style: TextStyle(
                        color: _selectedGroup3Index == 0
                            ? Colors.white
                            : Colors.black)),
              ),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGroup3Index = 1;
                  massageModeNum = 0x01;
                });
                writeMToBle();
              },
              child: AnimatedContainer(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                  // shape: BoxShape.circle,
                  border: Border.all(
                      color: _selectedGroup3Index == 1
                          ? Colors.tealAccent
                          : Colors.black),
                  color: _selectedGroup3Index == 1
                      ? Colors.tealAccent
                      : Colors.white,
                ),
                child: Text("模式2",
                    style: TextStyle(
                        color: _selectedGroup3Index == 1
                            ? Colors.white
                            : Colors.black)),
              ),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGroup3Index = 2;
                  massageModeNum = 0x02;
                });
                writeMToBle();
              },
              child: AnimatedContainer(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                  // shape: BoxShape.circle,
                  border: Border.all(
                      color: _selectedGroup3Index == 2
                          ? Colors.tealAccent
                          : Colors.black),
                  color: _selectedGroup3Index == 2
                      ? Colors.tealAccent
                      : Colors.white,
                ),
                child: Text("模式3",
                    style: TextStyle(
                        color: _selectedGroup3Index == 2
                            ? Colors.white
                            : Colors.black)),
              ),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGroup3Index = 3;
                  massageModeNum = 0x03;
                });
                writeMToBle();
              },
              child: AnimatedContainer(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                  // shape: BoxShape.circle,
                  border: Border.all(
                      color: _selectedGroup3Index == 3
                          ? Colors.tealAccent
                          : Colors.black),
                  color: _selectedGroup3Index == 3
                      ? Colors.tealAccent
                      : Colors.white,
                ),
                child: Text("模式4",
                    style: TextStyle(
                        color: _selectedGroup3Index == 3
                            ? Colors.white
                            : Colors.black)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20,),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(width: 20),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGroup3Index = 4;
                  massageModeNum = 0x04;
                });
                writeMToBle();
              },
              child: AnimatedContainer(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                  // shape: BoxShape.circle,
                  border: Border.all(
                      color: _selectedGroup3Index == 4
                          ? Colors.tealAccent
                          : Colors.black),
                  color: _selectedGroup3Index == 4
                      ? Colors.tealAccent
                      : Colors.white,
                ),
                child: Text("模式5",
                    style: TextStyle(
                        color: _selectedGroup3Index == 4
                            ? Colors.white
                            : Colors.black)),
              ),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGroup3Index = 5;
                  massageModeNum = 0x05;
                });
                writeMToBle();
              },
              child: AnimatedContainer(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                  // shape: BoxShape.circle,
                  border: Border.all(
                      color: _selectedGroup3Index == 5
                          ? Colors.tealAccent
                          : Colors.black),
                  color: _selectedGroup3Index == 5
                      ? Colors.tealAccent
                      : Colors.white,
                ),
                child: Text("模式6",
                    style: TextStyle(
                        color: _selectedGroup3Index == 5
                            ? Colors.white
                            : Colors.black)),
              ),
            ),
            const SizedBox(width: 15),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedGroup3Index = 6;
                  massageModeNum = 0x06;
                });
                writeMToBle();
              },
              child: AnimatedContainer(
                width: 65,
                height: 65,
                alignment: Alignment.center,
                duration: const Duration(milliseconds: 300),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(18.0)),
                  // shape: BoxShape.circle,
                  border: Border.all(
                      color: _selectedGroup3Index == 6
                          ? Colors.tealAccent
                          : Colors.black),
                  color: _selectedGroup3Index == 6
                      ? Colors.tealAccent
                      : Colors.white,
                ),
                child: Text("模式7",
                    style: TextStyle(
                        color: _selectedGroup3Index == 6
                            ? Colors.white
                            : Colors.black)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /*disconnect the connected device*/
  void disconnectConnectedDevice() {
    flutterBlue.connectedDevices.then((connectedDevices) {
      if (connectedDevices.isNotEmpty) {
        connectedDevices.map((device) async {
          return await device.disconnect();
        });
      }
    });

    if (Global.isConnected == true) {
      Global.connectedDevice.disconnect();
      Global.isConnected = false;
    }
  }

  _getRequests() {
    if (!Global.isConnected) {
      if (kDebugMode) {
        print('没有已连接设备！');
      }
      setState(() {
        connectedDeviceNameText = '未连接设备';
        // _isToFindPageHide = false;
        _isBatteryHide = true;
        _isChargeHide = true;
        _isMassageGifShow = false;
        // Global.isConnected = false;
      });
    } else {
      refreshHomePage();
    }
    // });
  }

  /*get the connected device characteristic data and update the option*/
  refreshHomePage() async {
    setState(() {
      connectedDeviceNameText = Global.connectedDevice.name;
    });
    List<BluetoothService> services =
    await Global.connectedDevice.discoverServices();
    for (BluetoothService s in services) {
      if (s.uuid.toString().toUpperCase().substring(4, 8) == "FFF0") {
        for (BluetoothCharacteristic c in s.characteristics) {
          if (c.uuid.toString().toUpperCase().substring(4, 8) == "FFF1") {
            connectedDeviceChar =
                c; // get the characteristic of the connected device
          }
        }
      }
    }
    await connectedDeviceChar.setNotifyValue(true);
    if (connectedDeviceChar.properties.read) {
      await connectedDeviceChar.read();
    }
    connectedDeviceChar.value.listen((value) {
      // do something with new value
      /*if (value == null) {
        if (kDebugMode) {
          print("蓝牙返回空数据！！");
        }
        return;
      }*/
      List data = [];
      for (var i = 0; i < value.length; i++) {
        // print(value[i]);
        String dataStr = value[i].toRadixString(16);
        if (dataStr.length < 2) {
          dataStr = "0$dataStr";
        }
        String dataEndStr = "0x$dataStr";
        data.add(dataEndStr);
        // print(dataStr);
      }
      if (kDebugMode) {
        print("我是蓝牙返回数据data - $data");
      }
      var sum1 = 0;
      if (value.length > 2) {
        for (var i = 1; i < value.length - 1; i++) {
          sum1 = sum1 + value[i];
        }
        var checkSum1 = sum1 & 0xff;
        var checkSum1a = checkSum1.toRadixString(16);
        if (checkSum1a.length < 2) {
          checkSum1a = '0$checkSum1a';
        }
        var checkSum1To16 = '0x$checkSum1a';
        if (data[0] == '0xff' && checkSum1To16 == data[data.length - 1]) {
/*it's massage control data*/
          if (data[1] == '0xc1') {
            setState(() {
              isMassaging = true;
              _isMassageGifShow = true;
            });
            /*update massage model*/
            switch (data[2]) {
              case '0x00':
                setState(() {
                  _selectedGroup3Index = 0;
                });
                break;
              case '0x01':
                setState(() {
                  _selectedGroup3Index = 1;
                });
                break;
              case '0x02':
                setState(() {
                  _selectedGroup3Index = 2;
                });
                break;
            }

            /*update massage strength*/
            /*if (kDebugMode) {
              print('data[5] is' + data[5]);
            }
            switch (data[5]) {
              case '0x64':
                setState(() {
                  _selectedGroup5Index = 0;
                });
                break;
              case '0x4b':
                setState(() {
                  _selectedGroup5Index = 1;
                });
                break;
              case '0x32':
                setState(() {
                  _selectedGroup5Index = 2;
                });
                break;
            }*/
          }

          if (data[1] == '0xc0') {
            setState(() {
              isMassaging = false;
              _isMassageGifShow = false;
            });
          }

          /*update battery situation, no matter warm or massage, it's the same*/
          switch (data[7]) {
            case '0x00':
              setState(() {
                // _isToFindPageHide = true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-4.png';
              });
              break;
            case '0x01':
              setState(() {
                // _isToFindPageHide = true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-3.png';
              });
              break;
            case '0x02':
              setState(() {
                // _isToFindPageHide = true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-2.png';
              });
              break;
            case '0x03':
              setState(() {
                // _isToFindPageHide = true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-1.png';
              });
              break;
            case '0x10':
              setState(() {
                // _isToFindPageHide = true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-4.png';
              });
              break;
            case '0x11':
              setState(() {
                // _isToFindPageHide = true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-3.png';
              });
              break;
            case '0x12':
              setState(() {
                // _isToFindPageHide = true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-2.png';
              });
              break;
            case '0x13':
              setState(() {
                // _isToFindPageHide = true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-1.png';
              });
              break;
          }
        }
      }
    });
    // }
  }

/*write massage data list*/
  void writeMToBle() async {
    var b2 = massageModeNum;
    var b3 = massageTimeHighNum;
    var b4 = massageTimeLowNum;
    var b5 = massageStrengthNum;
    //校验和，2-7相加后取低8位
    var bSum = 0xC1 + b2 + b3 + b4 + b5 + 0x00 + 0x00;
    var checkSum = bSum & 0xff;

    List<int> massageDataList =
    ([0xFF, 0xC1, b2, b3, b4, b5, 0x00, 0x00, checkSum]);
    if (isMassaging) {
      await connectedDeviceChar.write(massageDataList, withoutResponse: true);
    }
  }

  /*send massage on data*/
  void startMassageDataSend() async {
    var b2 = massageModeNum;
    var b3 = massageTimeHighNum;
    var b4 = massageTimeLowNum;
    var b5 = massageStrengthNum;
    //校验和，2-7相加后取低8位
    var bSum = 0xC1 + b2 + b3 + b4 + b5 + 0x00 + 0x00;
    var checkSum = bSum & 0xff;

    List<int> startMassageWriteDataList =
    ([0xFF, 0xC1, b2, b3, b4, b5, 0x00, 0x00, checkSum]);
    if (kDebugMode) {
      print('这是开启按摩的指令: $startMassageWriteDataList');
    }
    if (isCharging == true) {
      showToastHint('充电状态不能开启按摩');
    } else if (Global.isConnected == true) {
      await connectedDeviceChar.write(startMassageWriteDataList,
          withoutResponse: true);
      if (kDebugMode) {
        print('发送开启按摩指令： $startMassageWriteDataList');
      }
      setState(() {
        isMassaging = true;
        _isMassageGifShow = true;
      });
      // showToastHint('已开启按摩');
    } else {
      showToastHint('请连接设备');
    }
  }

/*send massage off data*/
  void stopMassageDataSend() async {
    List<int> stopMassageWriteDataList =
    ([0xff, 0xC0, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0xC0]);
    if (Global.isConnected == true) {
      if (isMassaging == true) {
        await connectedDeviceChar.write(stopMassageWriteDataList,
            withoutResponse: true);
        if (kDebugMode) {
          print('发送关闭按摩指令： $stopMassageWriteDataList');
        }
        setState(() {
          isMassaging = false;
          _isMassageGifShow = false;
        });
        // showToastHint('已停止按摩');
      } else {
        showToastHint('设备未开启按摩');
      }
    } else {
      showToastHint('请连接设备');
    }
  }
}

/*show toast*/
showToastHint(String msgStr) {
  Fluttertoast.showToast(
      msg: msgStr,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.CENTER,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.blue,
      textColor: Colors.white,
      fontSize: 14.0);
}
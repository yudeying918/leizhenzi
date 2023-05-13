import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'common/global.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ble_manage.dart';

enum WarmGear { high, middle, low }

enum WarmTime { one, five, ten }

enum MassageMode { zero, one, two }

enum MassageTime { quarter, half, one }

enum MassageStrength { high, middle, low }

void main() {
  runApp(const MyApp());
  if (kDebugMode) {
    print('运行main');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        "/": (_) => const MyHomePage(),
        "/ble": (_) => const FindDevicesScreen()
      },
      initialRoute: "/",
      title: '沣趣智能',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _getRequests() async {
    // bleInstance.connectedDevices.then((connectedDevices) {
    if (!Global.isConnected) {
      if (kDebugMode) {
        print('没有已连接设备！');
      }
      setState(() {
        connectedDeviceNameText = '未连接设备';
        _isToFindPageHide = false;
        _isBatteryHide = true;
        _isChargeHide = true;
        Global.isConnected = false;
      });
    } else {
      refreshHomePage();
    }
    // });
  }

  FlutterBluePlus bleInstance = FlutterBluePlus.instance;
  String connectedDeviceNameText = '未连接设备';
  var warmGearChoice = '高';
  var warmTimeChoice = '1小时';
  var warmGearNum = 0x5F;
  var warmTimeHighNum = 0x00;
  var warmTimeLowNum = 0x3C;
  var isWarming = false;

  var massageModeChoice = '持续';
  var massageTimeChoice = '15分钟';
  var massageStrengthChoice = '低';
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
  bool _isWarmGifShow = false;
  bool _isMassageGifShow = false;
  bool _isToFindPageHide = false;
  int _selectedGroup1Index = 0;
  int _selectedGroup2Index = 0;
  int _selectedGroup3Index = 0;
  int _selectedGroup4Index = 0;
  int _selectedGroup5Index = 2;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (kDebugMode) {
      print('主界面初始化');
    }
    loadLastDeviceId();
  }

  @override
  void dispose() {
    disconnectConnectedDevice();
    if (kDebugMode) {
      print('主界面释放');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      print('主界面构建');
    }
    return WillPopScope(
        onWillPop: () async {
          if (_lastQuitTime == null ||
              DateTime
                  .now()
                  .difference(_lastQuitTime!)
                  .inSeconds > 1) {
            if (kDebugMode) {
              print('再按一次Back键退出');
            }
            ScaffoldMessenger.of(context)
                .showSnackBar(
                const SnackBar(content: Text('再按一次返回键退出')));
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
        child: Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              title: const Text(
                '沣趣智能穿戴',
                style: TextStyle(color: Colors.black),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                    icon: Image.asset(
                      'images/bluetooth.png',
                      width: 18,
                    ),
                    onPressed: () {
                      // Navigator.pushNamed(context, "/ble");
                      Navigator.of(context)
                          .push(
                        MaterialPageRoute(
                            builder: (_) => const FindDevicesScreen()),
                      )
                      // .then((val) => val ? _getRequests() : null);
                          .then((val) => _getRequests());
                    }),
              ],
            ),
            body: SingleChildScrollView(
                child: Column(children: [
                  /*battery situation display*/
                  Container(
                    margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
                    height: 40,
                    decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.black12),
                        //   color: Colors.black26,
                        borderRadius:
                        const BorderRadius.all(Radius.circular(10.0))),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 10,
                        ),
                        Expanded(
                          child: Text(connectedDeviceNameText),
                        ),
                        Offstage(
                          offstage: _isToFindPageHide,
                          child: TextButton(
                              onPressed: () =>
                              {
                                Navigator.of(context)
                                    .push(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                      const FindDevicesScreen()),
                                )
                                // .then((val) => val ? _getRequests() : null);
                                    .then((val) => _getRequests())
                              },
                              child: const Text('搜索设备',
                                  style: TextStyle(
                                    color: Colors.pinkAccent,
                                    fontSize: 15.0,
                                  ))),
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
                  ),
                  /*warm control widget*/
                  Container(
                    margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
                    decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.black12),
                        //   color: Colors.black26,
                        borderRadius:
                        const BorderRadius.all(Radius.circular(10.0))),
                    child: Column(
                      children: [
                        //warm gear widget
                        Container(
                          // margin:
                          // const EdgeInsets.only(top: 8, left: 10, right: 10),
                            margin: const EdgeInsets.only(
                              top: 8,
                            ),
                            height: 45,
                            /*decoration: BoxDecoration(
                              border:
                              Border.all(width: 1.0, color: Colors.black26),
                              // color: Colors.amber,
                              borderRadius:
                              const BorderRadius.all(Radius.circular(10.0))),*/
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text('加热档位'),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup1Index = 0;
                                      warmGearNum = 0x5F;
                                    });
                                    writeWToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup1Index == 0
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup1Index == 0
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("高",
                                        style: TextStyle(
                                            color: _selectedGroup1Index == 0
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup1Index = 1;
                                      warmGearNum = 0x4B;
                                    });
                                    writeWToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup1Index == 1
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup1Index == 1
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("中",
                                        style: TextStyle(
                                            color: _selectedGroup1Index == 1
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup1Index = 2;
                                      warmGearNum = 0x37;
                                    });
                                    writeWToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup1Index == 2
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup1Index == 2
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("低",
                                        style: TextStyle(
                                            color: _selectedGroup1Index == 2
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                              ],
                            )),
                        //warm time widget
                        Container(
                            margin: const EdgeInsets.only(
                              top: 8,
                            ),
                            height: 45,
                            /*decoration: BoxDecoration(
                              border:
                              Border.all(width: 1.0, color: Colors.black26),
                              // color: Colors.amber,
                              borderRadius:
                              const BorderRadius.all(Radius.circular(10.0))),*/
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text('加热时间'),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup2Index = 0;
                                      warmTimeHighNum = 0x00;
                                      warmTimeLowNum = 0x3C;
                                    });
                                    writeWToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup2Index == 0
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup2Index == 0
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("1小时",
                                        style: TextStyle(
                                            color: _selectedGroup2Index == 0
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup2Index = 1;
                                      warmTimeHighNum = 0x01;
                                      warmTimeLowNum = 0x2C;
                                    });
                                    writeWToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup2Index == 1
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup2Index == 1
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("5小时",
                                        style: TextStyle(
                                            color: _selectedGroup2Index == 1
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup2Index = 2;
                                      warmTimeHighNum = 0x02;
                                      warmTimeLowNum = 0x58;
                                    });
                                    writeWToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup2Index == 2
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup2Index == 2
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("10小时",
                                        style: TextStyle(
                                            color: _selectedGroup2Index == 2
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                              ],
                            )),

                        /*warm animation*/
                        Container(
                          height: 65,
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          child: Visibility(
                            visible: _isWarmGifShow,
                            replacement: Image.asset('images/heating_low.png'),
                            // maintainState: true,
                            // maintainAnimation: true,
                            maintainSize: false,
                            child: Image.asset('images/heating_low_active.gif'),
                          ),
                        ),

                        //start&stop warm Button
                        Container(
                            margin:
                            const EdgeInsets.only(top: 5, left: 10, right: 10),
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.pinkAccent, width: 1),
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(30.0),
                                              right: Radius.circular(0.0))),
                                      padding: const EdgeInsets.fromLTRB(
                                          30.0, 10.0, 30.0, 10.0),
                                    ),
                                    onPressed: () => startWarmDataSend(),
                                    child: const Text('开始加热',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                        ))),
                                // SizedBox(width: 30,),
                                OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.pinkAccent, width: 1),
                                      shape: const RoundedRectangleBorder(
                                        // borderRadius: BorderRadius.all(Radius.circular(10))
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(0.0),
                                              right: Radius.circular(30.0))),
                                      padding: const EdgeInsets.fromLTRB(
                                          30.0, 10.0, 30.0, 10.0),
                                    ),
                                    onPressed: () => stopWarmDataSend(),
                                    child: const Text('停止加热',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                        ))),
                              ],
                            ))
                      ],
                    ),
                  ),

                  /*massage control widget*/
                  Container(
                    margin: const EdgeInsets.only(top: 5, left: 10, right: 10),
                    decoration: BoxDecoration(
                        border: Border.all(width: 1.0, color: Colors.black12),
                        //   color: Colors.black26,
                        borderRadius:
                        const BorderRadius.all(Radius.circular(10.0))),
                    child: Column(
                      children: [
                        /*massage mode widget*/
                        Container(
                            margin: const EdgeInsets.only(
                              top: 8,
                            ),
                            height: 45,
                            /*decoration: BoxDecoration(
                              border:
                              Border.all(width: 1.0, color: Colors.black26),
                              // color: Colors.amber,
                              borderRadius:
                              const BorderRadius.all(Radius.circular(10.0))),*/
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text('按摩模式'),
                                const SizedBox(width: 20),
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
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup3Index == 0
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup3Index == 0
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("持续",
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
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup3Index == 1
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup3Index == 1
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("舒缓",
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
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup3Index == 2
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup3Index == 2
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("轻快",
                                        style: TextStyle(
                                            color: _selectedGroup3Index == 2
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                              ],
                            )),
                        /*massage time widget*/
                        Container(
                            margin: const EdgeInsets.only(
                              top: 8,
                            ),
                            height: 45,
                            /*decoration: BoxDecoration(
                              border:
                              Border.all(width: 1.0, color: Colors.black26),
                              // color: Colors.amber,
                              borderRadius:
                              const BorderRadius.all(Radius.circular(10.0))),*/
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text('按摩时间'),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup4Index = 0;
                                      massageTimeHighNum = 0x00;
                                      massageTimeLowNum = 0x0F;
                                    });
                                    writeMToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup4Index == 0
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup4Index == 0
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("15分钟",
                                        style: TextStyle(
                                            color: _selectedGroup4Index == 0
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup4Index = 1;
                                      massageTimeHighNum = 0x00;
                                      massageTimeLowNum = 0x1E;
                                    });
                                    writeMToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup4Index == 1
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup4Index == 1
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("30分钟",
                                        style: TextStyle(
                                            color: _selectedGroup4Index == 1
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup4Index = 2;
                                      massageTimeHighNum = 0x00;
                                      massageTimeLowNum = 0x3C;
                                    });
                                    writeMToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup4Index == 2
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup4Index == 2
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("1小时",
                                        style: TextStyle(
                                            color: _selectedGroup4Index == 2
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                              ],
                            )),
                        /*massage strength widget*/
                        Container(
                            margin: const EdgeInsets.only(
                              top: 8,
                            ),
                            height: 45,
                            /*decoration: BoxDecoration(
                          border: Border.all(width: 1.0, color: Colors.black26),
                          // color: Colors.amber,
                          borderRadius:
                              const BorderRadius.all(Radius.circular(10.0))),*/
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 10,
                                ),
                                const Text('按摩强度'),
                                const SizedBox(width: 20),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup5Index = 0;
                                      massageStrengthNum = 0x64;
                                    });
                                    writeMToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup5Index == 0
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup5Index == 0
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("高",
                                        style: TextStyle(
                                            color: _selectedGroup5Index == 0
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup5Index = 1;
                                      massageStrengthNum = 0x4B;
                                    });
                                    writeMToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup5Index == 1
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup5Index == 1
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("中",
                                        style: TextStyle(
                                            color: _selectedGroup5Index == 1
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                                const SizedBox(width: 15),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedGroup5Index = 2;
                                      massageStrengthNum = 0x32;
                                    });
                                    writeMToBle();
                                  },
                                  child: AnimatedContainer(
                                    width: 65,
                                    height: 35,
                                    alignment: Alignment.center,
                                    duration: const Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(18.0)),
                                      // shape: BoxShape.circle,
                                      border: Border.all(
                                          color: _selectedGroup5Index == 2
                                              ? Colors.pinkAccent
                                              : Colors.black),
                                      color: _selectedGroup5Index == 2
                                          ? Colors.pinkAccent
                                          : Colors.white,
                                    ),
                                    child: Text("低",
                                        style: TextStyle(
                                            color: _selectedGroup5Index == 2
                                                ? Colors.white
                                                : Colors.black)),
                                  ),
                                ),
                              ],
                            )),

                        /*massage animation*/
                        Container(
                          height: 65,
                          margin:
                          const EdgeInsets.only(top: 5.0, left: 10, right: 10),
                          child: Visibility(
                            visible: _isMassageGifShow,
                            replacement: Image.asset(
                              'images/massage_0.png',
                              width: 100.0,
                            ),
                            // maintainState: true,
                            // maintainAnimation: true,
                            maintainSize: false,
                            child: Image.asset(
                              'images/massage_active.gif',
                              width: 100.0,
                            ),
                          ),
                        ),

                        //start&stop warm Button
                        Container(
                            margin:
                            const EdgeInsets.only(top: 5, left: 10, right: 10),
                            height: 50,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.pinkAccent, width: 1),
                                      shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(30.0),
                                              right: Radius.circular(0.0))),
                                      padding: const EdgeInsets.fromLTRB(
                                          30.0, 10.0, 30.0, 10.0),
                                    ),
                                    onPressed: () => startMassageDataSend(),
                                    child: const Text('开始按摩',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                        ))),
                                OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      side: const BorderSide(
                                          color: Colors.pinkAccent, width: 1),
                                      shape: const RoundedRectangleBorder(
                                        // borderRadius: BorderRadius.all(Radius.circular(10))
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(0.0),
                                              right: Radius.circular(30.0))),
                                      padding: const EdgeInsets.fromLTRB(
                                          30.0, 10.0, 30.0, 10.0),
                                    ),
                                    onPressed: () => stopMassageDataSend(),
                                    child: const Text('停止按摩',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                        ))),
                              ],
                            ))
                      ],
                    ),
                  ),
                ]))));
  }

  /*write warm data list*/
  writeWToBle() async {
    var b2 = warmGearNum;
    var b3 = warmTimeHighNum;
    var b4 = warmTimeLowNum;
    var b5 = 0x01; //加热1分钟
    var b6 = 0x1E; //暂停35秒
    //校验和，2-7相加后取低8位
    var bSum = 0x31 + b2 + b3 + b4 + b5 + b6 + 0x00;
    var checkSum = bSum & 0xff;
    List<int> warmDataList = ([0xFF, 0x31, b2, b3, b4, b5, b6, 0x00, checkSum]);
    if (isWarming) {
      await connectedDeviceChar.write(warmDataList, withoutResponse: true);
    }
  }

  /*write massage data list*/
  writeMToBle() async {
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

  /*send warm on data*/
  startWarmDataSend() async {
    var b2 = warmGearNum;
    var b3 = warmTimeHighNum;
    var b4 = warmTimeLowNum;
    var b5 = 0x01; //加热1分钟
    var b6 = 0x1E; //暂停35秒
    //校验和，2-7相加后取低8位
    var bSum = 0x31 + b2 + b3 + b4 + b5 + b6 + 0x00;
    var checkSum = bSum & 0xff;
    List<int> startWarmWriteDataList =
    ([0xFF, 0x31, b2, b3, b4, b5, b6, 0x00, checkSum]);
    if (isCharging) {
      showToastHint('充电状态不能开启加热');
    } else if (Global.isConnected) {
      await connectedDeviceChar.write(startWarmWriteDataList,
          withoutResponse: true);
      if (kDebugMode) {
        print('发送开启加热指令： $startWarmWriteDataList');
      }
      setState(() {
        isWarming = true;
        _isWarmGifShow = true;
      });
      // showToastHint('已开启加热');
    } else {
      showToastHint('请连接设备');
    }
  }

/*send warm off data*/
  stopWarmDataSend() async {
    List<int> stopWarmWriteDataList =
    ([0xff, 0x30, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x30]);
    if (Global.isConnected == true) {
      if (isWarming == true) {
        await connectedDeviceChar.write(stopWarmWriteDataList,
            withoutResponse: true);
        if (kDebugMode) {
          print('发达关闭加热指令： $stopWarmWriteDataList');
        }
        setState(() {
          isWarming = false;
          _isWarmGifShow = false;
        });
        // showToastHint('已停止加热');
      } else {
        showToastHint('设备未开启加热');
      }
    } else {
      showToastHint('请连接设备');
    }
  }

  /*send massage on data*/
  startMassageDataSend() async {
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
  stopMassageDataSend() async {
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

/*disconnect the connected device*/
  disconnectConnectedDevice() {
    bleInstance.connectedDevices.then((connectedDevices) {
      if (connectedDevices.isNotEmpty) {
        connectedDevices.map((device) async {
          return await device.disconnect();
        });
      }
    });
    if (kDebugMode) {
      print('${bleInstance.connectedDevices} is disconnected');
    }

    if (Global.isConnected == true) {
      Global.connectedDevice.disconnect();
      Global.isConnected = false;
      if (kDebugMode) {
        print(
            'Global.connectedDevice ${Global
                .connectedDevice}  is disconnected');
      }
    }
  }

  /*get the connected device characteristic data and update the option*/
  refreshHomePage() async {
    if (kDebugMode) {
      print('已连接设备是：  ${Global.connectedDevice.name}');
    }
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
      if (value == null) {
        if (kDebugMode) {
          print("蓝牙返回空数据！！");
        }
        return;
      }
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
        if (kDebugMode) {
          print(data[i]);
        }
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
        if (kDebugMode) {
          print('value[7] = ${value[value.length - 1]}');
        }
        if (kDebugMode) {
          print('data[7] = ' + data[data.length - 1]);
        }
        if (kDebugMode) {
          print('data[0] = ' + data[0]);
        }
        var checkSum1a = checkSum1.toRadixString(16);
        if (checkSum1a.length < 2) {
          checkSum1a = '0$checkSum1a';
        }
        var checkSum1To16 = '0x$checkSum1a';
        if (kDebugMode) {
          print('checkSum1To16 = $checkSum1To16');
        }
        /*bool a = (data[0] == '0xff');
        bool b = (checkSum1To16 == data[data.length - 1]);*/

        if (data[0] == '0xff' && checkSum1To16 == data[data.length - 1]) {
          if (kDebugMode) {
            print('data[1] is' + data[1]);
          }
          /*judge it's warm control data*/
          if (data[1] == '0x31') {
            setState(() {
              isWarming = true;
              _isWarmGifShow = true;
            });

            // judge warm gear
            if (kDebugMode) {
              print('data[2] is' + data[2]);
            }
            switch (data[2]) {
              case '0x5f':
                setState(() {
                  _selectedGroup1Index = 0;
                });
                break;
              case '0x4b':
                setState(() {
                  _selectedGroup1Index = 1;
                });
                break;
              case '0x37':
                setState(() {
                  _selectedGroup1Index = 2;
                });
                break;
            }
          }

          if (data[1] == '0x30') {
            setState(() {
              isWarming = false;
              _isWarmGifShow = false;
            });
          }
/*it's massage control data*/
          if (data[1] == '0xc1') {
            setState(() {
              isMassaging = true;
              _isMassageGifShow = true;
            });
            /*update massage model*/
            if (kDebugMode) {
              print('data[2] is' + data[2]);
            }
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
            /*case '0x03':
                setState(() {
                  massageModeChoice = '慢揉';
                });
                break;
              case '0x04':
                setState(() {
                  massageModeChoice = '锤打';
                });
                break;
              case '0x05':
                setState(() {
                  massageModeChoice = '跳跃';
                });
                break;*/
            }

            /*update massage strength*/
            if (kDebugMode) {
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
            }
          }

          if (data[1] == '0xc0') {
            setState(() {
              isMassaging = false;
              _isMassageGifShow = false;
            });
          }

          /*update battery situation, no matter warm or massage, it's the same*/
          if (kDebugMode) {
            print('data[7] is' + data[7]);
          }
          switch (data[7]) {
            case '0x00':
              setState(() {
                _isToFindPageHide = true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-4.png';
              });
              break;
            case '0x01':
              setState(() {
                _isToFindPageHide = true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-3.png';
              });
              break;
            case '0x02':
              setState(() {
                _isToFindPageHide = true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-2.png';
              });
              break;
            case '0x03':
              setState(() {
                _isToFindPageHide = true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-1.png';
              });
              break;
            case '0x10':
              setState(() {
                _isToFindPageHide = true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-4.png';
              });
              break;
            case '0x11':
              setState(() {
                _isToFindPageHide = true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-3.png';
              });
              break;
            case '0x12':
              setState(() {
                _isToFindPageHide = true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-2.png';
              });
              break;
            case '0x13':
              setState(() {
                _isToFindPageHide = true;
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


  //scan for  the last connected device and try to connect to it
  loadLastDeviceId() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastDeviceId = prefs.getString('lastDeviceId');
    if (kDebugMode) {
      print('lastDeviceId is $lastDeviceId');
    }
    if (lastDeviceId != null) {
      scanDevices();
      loadLastDevice(lastDeviceId);
    }
  }

  scanDevices() {
    bleInstance.startScan(timeout: const Duration(seconds: 3));
    if (kDebugMode) {
      print('主界面搜索设备');
    }
  }

  loadLastDevice(String lastDeviceId)  {
      bleInstance.scanResults.listen(
              (List<ScanResult> results) {
            for (ScanResult result in results) {
              if (result.device.id.toString() == lastDeviceId) {
                bleInstance.stopScan();
                if (kDebugMode) {
                  print('正在准备连接设备 ${result.device.name}');
                }
                showProgressDialog('正在连接设备 ${result.device.name}');
                connectLastDevice(result.device);
              }
            }
          }
      );
  }
    //connect the last connected device
    connectLastDevice(BluetoothDevice device) async {
      try {
        await device.connect(
            timeout: const Duration(seconds: 10), autoConnect: false);
        setState(() {
          Global.connectedDevice = device;
          if (kDebugMode) {
            print('主界面已连接最后一次连接设备 ${Global.connectedDevice}');
          }
          Global.isConnected = true;
        });
        refreshHomePage();
        if(!mounted) return;
        Navigator.pop(context);
        if (kDebugMode) {
          print('连接窗口释放');
        }

      } catch (e) {
        if (kDebugMode) {
          print('连接设备失败：$e');
        }
        showDialog(
          context: context,
          builder: (context) =>
              AlertDialog(
                title: const Text('自动重连失败'),
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

//load the last connected device
    /*loadLastConnectedDevice() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? lastDeviceId = prefs.getString('lastDeviceId');
    if (kDebugMode) {
      print('lastDeviceId is $lastDeviceId');
    }
  if(lastDeviceId!=null){
    bleInstance.startScan(timeout: const Duration(seconds: 3));
    if (kDebugMode) {
      print('主界面初始化搜索完成');
    }
    bleInstance.scanResults.listen(
          (List<ScanResult> results)  {
        for (ScanResult result in results) {
          if (kDebugMode) {
            print('主界面搜索到的设备： ${result.device}');
          }
          if (result.device.id.toString() == lastDeviceId) {
            if (kDebugMode) {
              print('主界面找到最后一次连接设备： ${result.device}');
            }
            bleInstance.stopScan();
            showProgressDialog('正在连接设备 ${result.device.name}' );
            connectLastDevice(result.device);
            if (!mounted) return;
            Navigator.of(context).pop();
          }
        }
      },
    );
  }
  }*/
//connect the last connected device
    /*connectLastDevice(BluetoothDevice device) async{
    try {
      await device.connect(
          timeout: const Duration(seconds: 10), autoConnect: false);

      if(mounted){
        setState(() {
          Global.connectedDevice = device;
          if (kDebugMode) {
            print('主界面已连接最后一次连接设备 ${Global.connectedDevice}');
          }
          Global.isConnected = true;
        });

      }
      updateControlPage();

    } catch (e) {
      if (kDebugMode) {
        print('连接设备失败：$e');
      }
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('自动重连失败'),
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
  }*/

    Future<void> showProgressDialog(String message) async {
      return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Dialog(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(width: 16),
                  Text(message),
                ],
              ),
            ),
          );
        },
      );
    }
  } // class MyHomePageState end

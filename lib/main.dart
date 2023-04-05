import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'common/global.dart';
// import 'ble_manage.dart';
import 'ble_3.dart';


enum WarmGear { high, middle, low }

enum WarmTime { one, five, ten }

/*enum WarmTimePeriod { one, three, five }

enum WarmPauseTime { ten, twenty, thirty }*/

enum MassageMode { zero, one, two }

enum MassageTime { quarter, half, one }

enum MassageStrength { high, middle, low }

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {"/": (_) => MyHomePage(), "/ble": (_) => FindDevicesScreen()},
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
    print('这里进行操作');
    print('bleInstance.connectedDevices is ' + bleInstance.connectedDevices.toString());
    // setState(() {
    //   connectedDeviceNameText=Global.connectedDevice.name;
    // });

    bleInstance.connectedDevices.then((connectedDevices) {
      if (connectedDevices.isEmpty) {
        print('no connected device');
        setState(() {
          connectedDeviceNameText = '未连接设备';
          _isToFindPageHide=false;
          _isBatteryHide = true;
          _isChargeHide = true;
          Global.isConnected = false;
        });
      } else {
        updateControlPage();
      }
    });
  }

  FlutterBluePlus bleInstance = FlutterBluePlus.instance;
  String connectedDeviceNameText = '未连接设备';
  var warmGearChoice = '高';
  var warmTimeChoice = '1小时';
  var warmGearNum = 0x64;
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    print('inistate home page');
    // if (Global.isConnected == false)  {
    //   print('no connected device');
    // } else {
    //   updateControlPage();
    // }
  }

  @override
  void dispose() {
    disconnectConnectedDevice();
    print('dispose');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return WillPopScope(
        onWillPop: () async {
          if (_lastQuitTime == null ||
              DateTime.now().difference(_lastQuitTime!).inSeconds > 1) {
            print('再按一次Back键退出');
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('再按一次返回键退出')));
            _lastQuitTime = DateTime.now();
            return false;
          } else {
            print('退出');
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
                '沣趣理疗文胸',
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
                            builder: (_) => FindDevicesScreen()),
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
                        borderRadius: BorderRadius.all(Radius.circular(10.0))),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                        ),
                        Expanded(
                          child: Text(connectedDeviceNameText),
                        ),
                        Offstage(
                          offstage: _isToFindPageHide,
                          child: TextButton(
                              onPressed: () => {
                                Navigator.of(context)
                                    .push(
                                  MaterialPageRoute(
                                      builder: (_) => FindDevicesScreen()),
                                )
                                // .then((val) => val ? _getRequests() : null);
                                    .then((val) => _getRequests())
                              },
                              child: Text('搜索设备',
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
                        SizedBox(
                          width: 20,
                        )
                      ],
                    ),
                  ),
                  /*warm control widget*/
                  Container(
                    child: Column(
                      children: [
                        //warm gear widget
                        Container(
                            margin:
                            const EdgeInsets.only(top: 8, left: 10, right: 10),
                            height: 50,
                            decoration: BoxDecoration(
                                border:
                                Border.all(width: 1.0, color: Colors.black26),
                                // color: Colors.amber,
                                borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(child: Text('加热档位')),
                                TextButton(
                                    onPressed: () => warmGearDialog(context),
                                    child: Text(warmGearChoice,
                                        style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 15.0,
                                        ))),
                                // Icon(Icons.arrow_right),
                                // Image.asset('images/arrow_right.png'),
                                IconButton(
                                    onPressed: () => warmGearDialog(context),
                                    icon: Image.asset(
                                      'images/arrow_right.png',
                                      width: 10,
                                    ))
                              ],
                            )),
                        //warm time widget
                        Container(
                            margin:
                            const EdgeInsets.only(top: 8, left: 10, right: 10),
                            height: 50,
                            decoration: BoxDecoration(
                                border:
                                Border.all(width: 1.0, color: Colors.black26),
                                // color: Colors.amber,
                                borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(child: Text('加热时间')),
                                TextButton(
                                    onPressed: () => warmTimeDialog(context),
                                    child: Text(warmTimeChoice,
                                        style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 15.0,
                                        ))),
                                // Icon(Icons.arrow_right)
                                IconButton(
                                    onPressed: () => warmTimeDialog(context),
                                    icon: Image.asset(
                                      'images/arrow_right.png',
                                      width: 10,
                                    ))
                              ],
                            )),
                        //warm period time & warm pause time widget
                        /*Container(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        height: 45,
                        color: Colors.lightGreen,
                        child: Row(
                          children: [
                            SizedBox(width: 20,),
                            Expanded(child: Text('加热')),
                            TextButton(
                                onPressed: () => warmPeriodTimeDialog(context),
                                child: Text(warmTimePeriodChoice)
                            ),
                            Icon(Icons.arrow_right),
                            SizedBox(width: 50,),
                            Expanded(child: Text('暂停')),
                            TextButton(
                                onPressed: () => warmPauseTimeDialog(context),
                                child: Text(warmPauseTimeChoice)
                            ),
                            Icon(Icons.arrow_right),
                            SizedBox(width: 20,),
                          ],
                        )),*/
                        /*warm animation*/
                        Container(
                          height: 80,
                          margin: const EdgeInsets.only(left: 10, right: 10),
                          child: Visibility(
                            child: Image.asset('images/heating_low_active.gif'),
                            visible: _isWarmGifShow,
                            replacement: Image.asset('images/heating_low.png'),
                            // maintainState: true,
                            // maintainAnimation: true,
                            maintainSize: false,
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
                                      side: BorderSide(
                                          color: Colors.pinkAccent, width: 1),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(30.0),
                                              right: Radius.circular(0.0))),
                                      padding: EdgeInsets.fromLTRB(
                                          30.0, 10.0, 30.0, 10.0),
                                    ),
                                    onPressed: () => startWarmDataSend(),
                                    child: Text('开始加热',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                        ))),
                                // SizedBox(width: 30,),
                                OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                          color: Colors.pinkAccent, width: 1),
                                      shape: RoundedRectangleBorder(
                                        // borderRadius: BorderRadius.all(Radius.circular(10))
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(0.0),
                                              right: Radius.circular(30.0))),
                                      padding: EdgeInsets.fromLTRB(
                                          30.0, 10.0, 30.0, 10.0),
                                    ),
                                    onPressed: () => stopWarmDataSend(),
                                    child: Text('停止加热',
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
                    child: Column(
                      children: [
                        /*massage mode widget*/
                        Container(
                            margin:
                            const EdgeInsets.only(top: 10, left: 10, right: 10),
                            height: 50,
                            decoration: BoxDecoration(
                                border:
                                Border.all(width: 1.0, color: Colors.black26),
                                // color: Colors.amber,
                                borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(child: Text('按摩模式')),
                                TextButton(
                                    onPressed: () => massageModeDialog(context),
                                    child: Text(massageModeChoice,
                                        style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 15.0,
                                        ))),
                                // Icon(Icons.arrow_right)
                                IconButton(
                                    onPressed: () => massageModeDialog(context),
                                    icon: Image.asset(
                                      'images/arrow_right.png',
                                      width: 10,
                                    ))
                              ],
                            )),
                        /*massage time widget*/
                        Container(
                            margin:
                            const EdgeInsets.only(top: 8, left: 10, right: 10),
                            height: 50,
                            decoration: BoxDecoration(
                                border:
                                Border.all(width: 1.0, color: Colors.black26),
                                // color: Colors.amber,
                                borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(child: Text('按摩时间')),
                                TextButton(
                                    onPressed: () => massageTimeDialog(context),
                                    child: Text(massageTimeChoice,
                                        style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 15.0,
                                        ))),
                                // Icon(Icons.arrow_right)
                                IconButton(
                                    onPressed: () => massageTimeDialog(context),
                                    icon: Image.asset(
                                      'images/arrow_right.png',
                                      width: 10,
                                    ))
                              ],
                            )),
                        /*massage strength widget*/
                        Container(
                            margin:
                            const EdgeInsets.only(top: 8, left: 10, right: 10),
                            height: 50,
                            decoration: BoxDecoration(
                                border:
                                Border.all(width: 1.0, color: Colors.black26),
                                // color: Colors.amber,
                                borderRadius:
                                BorderRadius.all(Radius.circular(10.0))),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 20,
                                ),
                                Expanded(child: Text('按摩强度')),
                                TextButton(
                                    onPressed: () => massageStrengthDialog(context),
                                    child: Text(massageStrengthChoice,
                                        style: TextStyle(
                                          color: Colors.pinkAccent,
                                          fontSize: 15.0,
                                        ))),
                                // Icon(Icons.arrow_right)
                                IconButton(
                                    onPressed: () => massageStrengthDialog(context),
                                    icon: Image.asset(
                                      'images/arrow_right.png',
                                      width: 10,
                                    ))
                              ],
                            )),

                        /*massage animation*/
                        Container(
                          height: 80,
                          margin:
                          const EdgeInsets.only(top: 5.0, left: 10, right: 10),
                          child: Visibility(
                            child: Image.asset(
                              'images/massage_active.gif',
                              width: 100.0,
                            ),
                            visible: _isMassageGifShow,
                            replacement: Image.asset(
                              'images/massage_0.png',
                              width: 100.0,
                            ),
                            // maintainState: true,
                            // maintainAnimation: true,
                            maintainSize: false,
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
                                      side: BorderSide(
                                          color: Colors.pinkAccent, width: 1),
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(30.0),
                                              right: Radius.circular(0.0))),
                                      padding: EdgeInsets.fromLTRB(
                                          30.0, 10.0, 30.0, 10.0),
                                    ),
                                    onPressed: () => startMassageDataSend(),
                                    child: Text('开始按摩',
                                        style: TextStyle(
                                          fontSize: 15.0,
                                        ))),
                                OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.black,
                                      backgroundColor: Colors.white,
                                      side: BorderSide(
                                          color: Colors.pinkAccent, width: 1),
                                      shape: RoundedRectangleBorder(
                                        // borderRadius: BorderRadius.all(Radius.circular(10))
                                          borderRadius: BorderRadius.horizontal(
                                              left: Radius.circular(0.0),
                                              right: Radius.circular(30.0))),
                                      padding: EdgeInsets.fromLTRB(
                                          30.0, 10.0, 30.0, 10.0),
                                    ),
                                    onPressed: () => stopMassageDataSend(),
                                    child: Text('停止按摩',
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

//warm gear dialog--------------------------
  Future warmGearDialog(BuildContext context) async {
    final warmGearOption = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('加热档位'),
          children: [
            SimpleDialogOption(
              child: Text('高'),
              onPressed: () {
                Navigator.pop(context, WarmGear.high);
              },
            ),
            SimpleDialogOption(
              child: Text('中'),
              onPressed: () {
                Navigator.pop(context, WarmGear.middle);
              },
            ),
            SimpleDialogOption(
              child: Text('低'),
              onPressed: () {
                Navigator.pop(context, WarmGear.low);
              },
            ),
          ],
        );
      },
    );
    //setting warm gear
    switch (warmGearOption) {
      case WarmGear.high:
        setState(() {
          warmGearChoice = '高';
        });
        warmGearNum = 0x55;
        break;
      case WarmGear.middle:
        setState(() {
          warmGearChoice = '中';
        });
        warmGearNum = 0x46;
        break;
      case WarmGear.low:
        setState(() {
          warmGearChoice = '低';
        });
        warmGearNum = 0x37;
        break;
      default:
        warmGearChoice = '中';
        warmGearNum = 0x46;
    }
  }

  //warm time dialog--------------------------
  Future warmTimeDialog(BuildContext context) async {
    final warmTimeOption = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('加热时间'),
          children: [
            SimpleDialogOption(
              child: Text('1小时'),
              onPressed: () {
                Navigator.pop(context, WarmTime.one);
              },
            ),
            SimpleDialogOption(
              child: Text('5小时'),
              onPressed: () {
                Navigator.pop(context, WarmTime.five);
              },
            ),
            SimpleDialogOption(
              child: Text('10小时'),
              onPressed: () {
                Navigator.pop(context, WarmTime.ten);
              },
            ),
            /* SimpleDialogOption(
              child: Text('3小时'),
              onPressed: () {
                Navigator.pop(context, WarmTime.three);
              },
            ),
            SimpleDialogOption(
              child: Text('4小时'),
              onPressed: () {
                Navigator.pop(context, WarmTime.four);
              },
            ),*/
          ],
        );
      },
    );
    //setting warm time
    switch (warmTimeOption) {
      case WarmTime.one:
        setState(() {
          warmTimeChoice = '1小时';
        });
        warmTimeHighNum = 0x00;
        warmTimeLowNum = 0x3C;
        break;
      case WarmTime.five:
        setState(() {
          warmTimeChoice = '5小时';
        });
        warmTimeHighNum = 0x01;
        warmTimeLowNum = 0x2C;
        break;
      case WarmTime.ten:
        setState(() {
          warmTimeChoice = '10小时';
        });
        warmTimeHighNum = 0x02;
        warmTimeLowNum = 0x58;
        break;
    /*case WarmTime.three:
        setState(() {
          warmTimeChoice = '3小时';
        });
        warmTimeNum = 0xB4;
        break;
      case WarmTime.four:
        setState(() {
          warmTimeChoice = '4小时';
        });
        warmTimeNum = 0xF0;
        break;*/
      default:
        warmTimeChoice = '1小时';
        warmTimeHighNum = 0x00;
        warmTimeLowNum = 0x3C;
    }
  }

//warm period time dialog--------------------------
  /*Future warmPeriodTimeDialog(BuildContext context) async {
    final warmPeriodTimeOption = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('加热'),
          children: [
            SimpleDialogOption(
              child: Text('1分钟'),
              onPressed: () {
                Navigator.pop(context, WarmTimePeriod.one);
              },
            ),
            SimpleDialogOption(
              child: Text('3分钟'),
              onPressed: () {
                Navigator.pop(context, WarmTimePeriod.three);
              },
            ),
            SimpleDialogOption(
              child: Text('5分钟'),
              onPressed: () {
                Navigator.pop(context, WarmTimePeriod.five);
              },
            ),
          ],
        );
      },
    );
    //setting warm period time
    switch (warmPeriodTimeOption) {
      case WarmTimePeriod.one:
        setState(() {
          warmTimePeriodChoice = '1分钟';
        });
        warmPeriodTimeNum = 0x01;
        break;
      case WarmTimePeriod.three:
        setState(() {
          warmTimePeriodChoice = '3分钟';
        });
        warmPeriodTimeNum = 0x03;
        break;
      case WarmTimePeriod.five:
        setState(() {
          warmTimePeriodChoice = '5分钟';
        });
        warmPeriodTimeNum = 0x05;
        break;
      default:
        warmTimePeriodChoice = '1分钟';
        warmPeriodTimeNum = 0x01;
    }
  }*/

//warm pause time dialog--------------------------
  /*Future warmPauseTimeDialog(BuildContext context) async {
    final warmPauseTimeOption = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('暂停'),
          children: [
            SimpleDialogOption(
              child: Text('10秒'),
              onPressed: () {
                Navigator.pop(context, WarmPauseTime.ten);
              },
            ),
            SimpleDialogOption(
              child: Text('20秒'),
              onPressed: () {
                Navigator.pop(context, WarmPauseTime.twenty);
              },
            ),
            SimpleDialogOption(
              child: Text('30秒'),
              onPressed: () {
                Navigator.pop(context, WarmPauseTime.thirty);
              },
            ),
          ],
        );
      },
    );
    //setting warm pause time
    switch (warmPauseTimeOption) {
      case WarmPauseTime.ten:
        setState(() {
          warmPauseTimeChoice = '10秒';
        });
        warmPauseTimeNum = 0x0A;
        break;
      case WarmPauseTime.twenty:
        setState(() {
          warmPauseTimeChoice = '20秒';
        });
        warmPauseTimeNum = 0x14;
        break;
      case WarmPauseTime.thirty:
        setState(() {
          warmPauseTimeChoice = '30秒';
        });
        warmPauseTimeNum = 0x1E;
        break;
      default:
        warmPauseTimeChoice = '10秒';
        warmPauseTimeNum = 0x0A;
    }
  }*/

//massage mode dialog--------------------------
  Future massageModeDialog(BuildContext context) async {
    final massageModeOption = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('按摩模式'),
          children: [
            SimpleDialogOption(
              child: Text('持续'),
              onPressed: () {
                Navigator.pop(context, MassageMode.zero);
              },
            ),
            SimpleDialogOption(
              child: Text('舒缓'),
              onPressed: () {
                Navigator.pop(context, MassageMode.one);
              },
            ),
            SimpleDialogOption(
              child: Text('轻快'),
              onPressed: () {
                Navigator.pop(context, MassageMode.two);
              },
            ),
            /*SimpleDialogOption(
              child: Text('慢揉'),
              onPressed: () {
                Navigator.pop(context, MassageMode.three);
              },
            ),
            SimpleDialogOption(
              child: Text('锤打'),
              onPressed: () {
                Navigator.pop(context, MassageMode.four);
              },
            ),
            SimpleDialogOption(
              child: Text('跳跃'),
              onPressed: () {
                Navigator.pop(context, MassageMode.five);
              },
            ),*/
          ],
        );
      },
    );
    //setting massage mode
    switch (massageModeOption) {
      case MassageMode.zero:
        setState(() {
          massageModeChoice = '持续';
        });
        massageModeNum = 0x00;
        break;
      case MassageMode.one:
        setState(() {
          massageModeChoice = '舒缓';
        });
        massageModeNum = 0x01;
        break;
      case MassageMode.two:
        setState(() {
          massageModeChoice = '轻快';
        });
        massageModeNum = 0x02;
        break;
    /*case MassageMode.three:
        setState(() {
          massageModeChoice = '慢揉';
        });
        massageModeNum = 0x03;
        break;
      case MassageMode.four:
        setState(() {
          massageModeChoice = '捶打';
        });
        massageModeNum = 0x04;
        break;
      case MassageMode.five:
        setState(() {
          massageModeChoice = '跳跃';
        });
        massageModeNum = 0x05;
        break;*/
      default:
        massageModeChoice = '持续';
        massageModeNum = 0x00;
    }
  }

  //massage time dialog--------------------------
  Future massageTimeDialog(BuildContext context) async {
    final massageTimeOption = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('按摩时间'),
          children: [
            SimpleDialogOption(
              child: Text('15分钟'),
              onPressed: () {
                Navigator.pop(context, MassageTime.quarter);
              },
            ),
            SimpleDialogOption(
              child: Text('30分钟'),
              onPressed: () {
                Navigator.pop(context, MassageTime.half);
              },
            ),
            SimpleDialogOption(
              child: Text('1小时'),
              onPressed: () {
                Navigator.pop(context, MassageTime.one);
              },
            ),
          ],
        );
      },
    );
    //setting warm time
    switch (massageTimeOption) {
      case MassageTime.quarter:
        setState(() {
          massageTimeChoice = '15分钟';
        });
        massageTimeHighNum = 0x00;
        massageTimeLowNum = 0x0F;
        break;
      case MassageTime.half:
        setState(() {
          massageTimeChoice = '30分钟';
        });
        massageTimeHighNum = 0x00;
        massageTimeLowNum = 0x1E;
        break;
      case MassageTime.one:
        setState(() {
          massageTimeChoice = '1小时';
        });
        massageTimeHighNum = 0x00;
        massageTimeLowNum = 0x3C;
        break;
      default:
        massageTimeChoice = '15分钟';
        massageTimeHighNum = 0x00;
        massageTimeLowNum = 0x0F;
    }
  }

  //massage strength dialog--------------------------
  Future massageStrengthDialog(BuildContext context) async {
    final massageStrengthOption = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('按摩强度'),
          children: [
            SimpleDialogOption(
              child: Text('高'),
              onPressed: () {
                Navigator.pop(context, MassageStrength.high);
              },
            ),
            SimpleDialogOption(
              child: Text('中'),
              onPressed: () {
                Navigator.pop(context, MassageStrength.middle);
              },
            ),
            SimpleDialogOption(
              child: Text('低'),
              onPressed: () {
                Navigator.pop(context, MassageStrength.low);
              },
            ),
          ],
        );
      },
    );
    //setting warm time
    switch (massageStrengthOption) {
      case MassageStrength.high:
        setState(() {
          massageStrengthChoice = '高';
        });
        massageStrengthNum = 0x64;
        break;
      case MassageStrength.middle:
        setState(() {
          massageStrengthChoice = '中';
        });
        massageStrengthNum = 0x4B;
        break;
      case MassageStrength.low:
        setState(() {
          massageStrengthChoice = '低';
        });
        massageStrengthNum = 0x32;
        break;
      default:
        massageStrengthChoice = '低';
        massageStrengthNum = 0x32;
    }
  }

  /*send warm on data*/
  startWarmDataSend() async {
    var b2 = warmGearNum;
    print(b2);
    var b3 = warmTimeHighNum;
    var b4 = warmTimeLowNum;
    var b5 = 0x01; //加热1分钟
    var b6 = 0x23; //暂停35秒
    //校验和，2-7相加后取低8位
    var bSum = 0x31 + b2 + b3 + b4 + b5 + b6 + 0x00;
    var checkSum = bSum & 0xff;
    print(bSum);
    print(checkSum);

    List<int> startWarmWriteDataList =
    ([0xFF, 0x31, b2, b3, b4, b5, b6, 0x00, checkSum]);
    print(
        'this is the warm on data list: ' + startWarmWriteDataList.toString());
    if (isCharging == true) {
      showToastHint('充电状态不能开启加热');
    } else if (Global.isConnected == true) {
      await connectedDeviceChar.write(startWarmWriteDataList,
          withoutResponse: true);
      print('now send the warm on data to connectedDevice ' +
          startWarmWriteDataList.toString());
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
        print('now send the warm off data to connectedDevice ' +
            stopWarmWriteDataList.toString());
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
    print('this is the massage on data list: ' +
        startMassageWriteDataList.toString());
    if (isCharging == true) {
      showToastHint('充电状态不能开启按摩');
    } else if (Global.isConnected == true) {
      await connectedDeviceChar.write(startMassageWriteDataList,
          withoutResponse: true);
      print('now send the massage on data to connectedDevice ' +
          startMassageWriteDataList.toString());
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
        print('now send the massage off data to connectedDevice ' +
            stopMassageWriteDataList.toString());
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
    print(bleInstance.connectedDevices.toString() + ' is disconnected');

    if (Global.isConnected == true) {
      Global.connectedDevice.disconnect();
      Global.isConnected = false;
      print('Global.connectedDevice is disconnected');
    }
  }

  /*get the connected device characteristic data and update the option*/
  updateControlPage() async {
    // await bleInstance.connectedDevices.then((list) => {
    print('connected device is not  empty');
    print('connectedDevice is  ' + Global.connectedDevice.name);
    setState(() {
      connectedDeviceNameText = Global.connectedDevice.name;
    });

    // print('the connected device is ' + Global.connectedDevice.name);
    List<BluetoothService> _services =
    await Global.connectedDevice.discoverServices();
    for (BluetoothService s in _services) {
      if (s.uuid.toString().toUpperCase().substring(4, 8) == "FFF0") {
        print(s.uuid);
        for (BluetoothCharacteristic c in s.characteristics) {
          if (c.uuid.toString().toUpperCase().substring(4, 8) == "FFF1") {
            print('c is ' + c.uuid.toString());
            connectedDeviceChar =
                c; // get the characteristic of the connected device
            print('connected device characteristic uuid is ' +
                connectedDeviceChar.uuid.toString());
          }
        }
      }
    }
    await connectedDeviceChar.setNotifyValue(true);
    connectedDeviceChar.value.listen((value) {
      // do something with new value
      // print("我是蓝牙返回数据 - $value");
      if (value == null) {
        print("蓝牙返回空数据！！");
        return;
      }
      List data = [];
      for (var i = 0; i < value.length; i++) {
        // print(value[i]);
        String dataStr = value[i].toRadixString(16);
        if (dataStr.length < 2) {
          dataStr = "0" + dataStr;
        }
        String dataEndStr = "0x" + dataStr;
        data.add(dataEndStr);
        // print(dataStr);
        print(data[i]);
      }
      print("我是蓝牙返回数据 - $data");
      var sum1 = 0;
      if (value.length > 2) {
        for (var i = 1; i < value.length - 1; i++) {
          sum1 = sum1 + value[i];
        }
        var checkSum1 = sum1 & 0xff;
        print('sum1 = ' + sum1.toString());
        print('checkSum1 = ' + checkSum1.toString());
        print('value[7] = ' + value[value.length - 1].toString());
        print('data[7] = ' + data[data.length - 1]);
        print('data[0] = ' + data[0]);
        var checkSum1a = checkSum1.toRadixString(16);
        if (checkSum1a.length < 2) {
          checkSum1a = '0' + checkSum1a;
        }
        var checkSum1To16 = '0x' + checkSum1a;
        print('checkSum1To16 = ' + checkSum1To16);
        bool a = (data[0] == '0xff');
        bool b = (checkSum1To16 == data[data.length - 1]);
        print('a = ' + a.toString());
        print('b = ' + b.toString());
        if (data[0] == '0xff' && checkSum1To16 == data[data.length - 1]) {
          print('data[1] is ' + data[1]);
          /*judge it's warm control data*/
          if (data[1] == '0x31') {
            setState(() {
              isWarming = true;
              _isWarmGifShow = true;
            });

            /*judge warm gear */
            /*print('data[3] is ' + data[3]);
            switch (data[3]) {
              case '0x64':
                setState(() {
                  warmGearChoice = '高温';
                });
                break;
              case '0x4B':
                setState(() {
                  warmGearChoice = '中温';
                });
                break;
              case '0x32':
                setState(() {
                  warmGearChoice = '低温';
                });
                break;
            }*/
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
            print('data[2] is ' + data[2]);
            /*switch (data[2]) {
              case '0x00':
                setState(() {
                  massageModeChoice = '持续';
                });
                break;
              case '0x01':
                setState(() {
                  massageModeChoice = '舒缓';
                });
                break;
              case '0x02':
                setState(() {
                  massageModeChoice = '轻快';
                });
                break;
              case '0x03':
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
                break;
            }*/

            /*update massage strength*/
            print('data[4] is ' + data[4]);
            print('data[5] is ' + data[5]);
            /*switch (data[4]) {
              case '0x64':
                setState(() {
                  massageStrengthChoice = '3级';
                });
                break;
              case '0x4B':
                setState(() {
                  massageStrengthChoice = '2级';
                });
                break;
              case '0x32':
                setState(() {
                  massageStrengthChoice = '1级';
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
          print('data[7] is ' + data[7]);
          switch (data[7]) {
            case '0x00':
              setState(() {
                _isToFindPageHide=true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-4.png';
              });
              break;
            case '0x01':
              setState(() {
                _isToFindPageHide=true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-3.png';
              });
              break;
            case '0x02':
              setState(() {
                _isToFindPageHide=true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-2.png';
              });
              break;
            case '0x03':
              setState(() {
                _isToFindPageHide=true;
                _isChargeHide = true;
                isCharging = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-1.png';
              });
              break;
            case '0x10':
              setState(() {
                _isToFindPageHide=true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-4.png';
              });
              break;
            case '0x11':
              setState(() {
                _isToFindPageHide=true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-3.png';
              });
              break;
            case '0x12':
              setState(() {
                _isToFindPageHide=true;
                isCharging = true;
                _isChargeHide = false;
                _isBatteryHide = false;
                batteryImageLink = 'images/battery-2.png';
              });
              break;
            case '0x13':
              setState(() {
                _isToFindPageHide=true;
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
} // class MyHomePageState end

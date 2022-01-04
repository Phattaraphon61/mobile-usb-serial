import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:usb_serial/transaction.dart';
import 'package:usb_serial/usb_serial.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String datainfo = "";
  UsbPort _port;
  String _status = "Idle";
  List<Widget> _ports = [];
  List<Widget> _serialData = [];
  StreamSubscription<String> _subscription;
  Transaction<String> _transaction;
  int _deviceId;
  TextEditingController _textController = TextEditingController();
  int coin = 0;
  int check = 0;
  int mode = 0;

  Future<bool> _connectTo(device) async {
    _serialData.clear();

    if (_subscription != null) {
      _subscription.cancel();
      _subscription = null;
    }

    if (_transaction != null) {
      _transaction.dispose();
      _transaction = null;
    }

    if (_port != null) {
      _port.close();
      _port = null;
    }

    if (device == null) {
      setState(() {
        _deviceId = null;
        _status = "Disconnected";
      });
      return true;
    }

    _port = await device.create();
    if (!await _port.open()) {
      setState(() {
        _status = "Failed to open port";
      });
      return false;
    }

    _deviceId = device.deviceId;
    await _port.setDTR(true);
    await _port.setRTS(true);
    await _port.setPortParameters(
        115200, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);

    _transaction = Transaction.stringTerminated(
        _port.inputStream, Uint8List.fromList([13, 10]));

    _subscription = _transaction.stream.listen((String line) {
      if (line.toString() != "") {
        setState(() {
          datainfo = line.toString().split(" ").toString()[1] + "k";
          _serialData.add(Text(line));
          if (_serialData.length > 20) {
            _serialData.removeAt(0);
          }
        });
      }
      if (line.toString().split(" ").toString()[1] == 'C' && mode != 0) {
        setState(() {
          coin += 10;
          if (mode == 1 && coin == 30) {
            mode = 0;
            coin = 0;
            check = 0;
          }
          if (mode == 2 && coin == 20) {
            mode = 0;
            coin = 0;
            check = 0;
          }
        });
      }
    });

    setState(() {
      _status = "Connected";
    });
    return true;
  }

  void _getPorts() async {
    _ports = [];
    List<UsbDevice> devices = await UsbSerial.listDevices();
    print(devices);

    devices.forEach((device) {
      _ports.add(ListTile(
          leading: Icon(Icons.usb),
          title: Text(device.productName),
          subtitle: Text(device.manufacturerName),
          trailing: RaisedButton(
            child:
                Text(_deviceId == device.deviceId ? "Disconnect" : "Connect"),
            onPressed: () {
              _connectTo(_deviceId == device.deviceId ? null : device)
                  .then((res) {
                _getPorts();
              });
            },
          )));
    });

    setState(() {
      print(_ports);
    });
  }

  @override
  void initState() {
    Timer mytime = Timer.periodic(Duration(seconds: 2), (timer) async {
      await _port.write(Uint8List.fromList([13, 10]));
    });
    super.initState();

    UsbSerial.usbEventStream.listen((UsbEvent event) {
      _getPorts();
    });

    _getPorts();
  }

  @override
  void dispose() {
    super.dispose();
    _connectTo(null);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Colors.blue,
          // appBar: AppBar(
          //   title: const Text('USB Serial Plugin example app'),
          // ),
          body: check == 0
              ? SingleChildScrollView(
                  child: Container(
                  child: Column(children: <Widget>[
                    Text(
                      _ports.length > 0 ? "" : "",
                    ),
                    if (_deviceId == null) ...[..._ports],
                    SizedBox(
                      height: 80,
                    ),
                    Text(
                      'จ่ายง่ายได้ซัก',
                      style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent),
                    ),
                    Container(
                      child: Column(
                        children: [
                          SizedBox(
                            height: 40,
                          ),
                          new InkWell(
                            onTap: () async {
                              print("STANDARD");
                              String data = 'N' + "\r\n";
                              await _port
                                  .write(Uint8List.fromList(data.codeUnits));
                              setState(() {
                                mode = 1;
                                check = 2;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 24.0),
                              height: 250,
                              child: Card(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        title: const Text(
                                          'มาตรฐาน',
                                          style: TextStyle(
                                              fontSize: 30, color: Colors.blue),
                                        ),
                                        subtitle: Text(
                                          'STANDARD',
                                          style: TextStyle(
                                              color:
                                                  Colors.blue.withOpacity(0.6)),
                                        ),
                                      ),
                                      ListTile(
                                        title: const Text(
                                          'รายละเอียด : ',
                                          style: TextStyle(
                                              fontSize: 25,
                                              color: Colors.black),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 50),
                                        child: Text(
                                          'เวลา : 40',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 50),
                                        child: Text(
                                          'ราคา : 30',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          new InkWell(
                            onTap: () async {
                              print("QUICK");
                              String data = 'Q' + "\r\n";
                              await _port
                                  .write(Uint8List.fromList(data.codeUnits));
                              setState(() {
                                mode = 2;
                                check = 2;
                              });
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 24.0),
                              height: 250,
                              child: Card(
                                color: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Container(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        title: const Text(
                                          'ซักด่วน',
                                          style: TextStyle(
                                              fontSize: 30, color: Colors.blue),
                                        ),
                                        subtitle: Text(
                                          'QUICK',
                                          style: TextStyle(
                                              color:
                                                  Colors.blue.withOpacity(0.6)),
                                        ),
                                      ),
                                      ListTile(
                                        title: const Text(
                                          'รายละเอียด : ',
                                          style: TextStyle(
                                              fontSize: 25,
                                              color: Colors.black),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 50),
                                        child: Text(
                                          'เวลา : 25',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black),
                                        ),
                                      ),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 50),
                                        child: Text(
                                          'ราคา : 20',
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                        ],
                      ),
                    ),
                    // Text('Status: $_status\n'),
                    // ListTile(
                    //   title: TextField(
                    //     controller: _textController,
                    //     decoration: InputDecoration(
                    //       border: OutlineInputBorder(),
                    //       labelText: 'Text To Send',
                    //     ),
                    //   ),
                    //   trailing: RaisedButton(
                    //     child: Text("Send"),
                    //     onPressed: _port == null
                    //         ? null
                    //         : () async {
                    //             if (_port == null) {
                    //               return;
                    //             }
                    //             String data = _textController.text + "\r\n";
                    //             await _port.write(Uint8List.fromList(data.codeUnits));
                    //             _textController.text = "";
                    //           },
                    //   ),
                    // ),
                    // Column(
                    //   children: [

                    // Text(
                    //   "datainfo is :" + datainfo,
                    // ),
                    // Text(
                    //   "Coin is :" + coin.toString(),
                    // ),
                    // Text(
                    //   "Result Data",
                    // ),
                    // ..._serialData,
                    //   ],
                    // ),
                  ]),
                ))
              : check == 2
                  ? Center(child: Text("หน้าสอง" + coin.toString()))
                  : null,
        ));
  }
}

import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import 'palette.dart';
import 'transport.dart';

enum ConnectionState { connected, loading, disconnected }

enum ESCCalibration { min, max, none }

class Settings extends StatefulWidget {
  final ConnectSocket socket;

  const Settings({super.key, required this.socket});

  @override
  State<StatefulWidget> createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  static int portNum = defualtPortNum;
  static SocketHandshake handshake = defaultHandshake;

  static var connectionState = ConnectionState.disconnected;

  static Set<String> hosts = {};
  static StreamSubscription<String> scanSubscription =
      Stream<String>.empty().listen((_) {});
  static bool isScanning = false;
  static double loadingProgress = 0.0;

  void getLocalIpAddresses() async {
    if (isScanning) return;
    isScanning = true;
    scanSubscription = ConnectSocket.scanNetwork((progress) {
      if (!mounted) {
        loadingProgress = progress;
      } else {
        setState(() {
          loadingProgress = progress;
        });
      }
    }).listen((host) {
      hosts.add(host);
    }, onDone: () {
      isScanning = false;
    });
  }

  Future<String?> getConnectionInfo(BuildContext context) async {
    String? result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setState) {
          scanSubscription.onData((host) {
            setState(() {
              hosts.add(host);
            });
          });
          return SimpleDialog(
            backgroundColor: palette.hHighlight,
            children: <Widget>[
              ...hosts.map((host) => SimpleDialogOption(
                    onPressed: () {
                      Navigator.pop(context, host);
                    },
                    child: Text(
                      host,
                      style: TextStyle(color: palette.text),
                    ),
                  )),
              // ...dialogOptions,
              SimpleDialogOption(
                  onPressed: () {
                    final textField = TextEditingController();
                    showText("Enter custom IP", textField).then((_) {
                      if (!context.mounted) return;
                      Navigator.pop(context, textField.text);
                    });
                  },
                  child: Text(
                    "Custom",
                    style: TextStyle(color: palette.text),
                  )),
              SimpleDialogOption(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: palette.text),
                  )),
            ],
          );
        });
      },
    );

    scanSubscription.onData((host) {
      hosts.add(host);
    });
    return result;
  }

  Future<void> showText(String text, [TextEditingController? textField]) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            text,
            style: TextStyle(color: palette.text),
          ),
          content: textField != null
              ? TextField(
                  controller: textField,
                  style: TextStyle(color: palette.text),
                )
              : null,
          backgroundColor: palette.hHighlight,
          actions: <Widget>[
            if (textField != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  textField.text = "";
                },
                child: Text(
                  "CANCEL",
                  style: TextStyle(color: palette.text),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(
                "OK",
                style: TextStyle(color: palette.text),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: AlignmentDirectional.topCenter,
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              "Settings",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: palette.text),
            ),
            const SizedBox(height: 4),
            Text(
              "Configure settings for connecting and communicating with the submarine.",
              style: TextStyle(fontSize: 16, color: palette.lText),
            ),
            const SizedBox(height: 16),
            Text(
              "Submarine Connection",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 128,
                    maxHeight: 40,
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: palette.text,
                      backgroundColor: palette.accent,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () async {
                      if (connectionState == ConnectionState.disconnected) {
                        String host = await getConnectionInfo(context) ?? "";
                        if (host.isNotEmpty) {
                          setState(() {
                            connectionState = ConnectionState.loading;
                          });
                          SocketResult result = await widget.socket
                              .connect(host, portNum, handshake,
                                  onError: (SocketException error) {
                            setState(() {
                              connectionState = ConnectionState.disconnected;
                            });
                            showText(error.toString());
                          }, onDisconnect: () {
                            setState(() {
                              connectionState = ConnectionState.disconnected;
                            });
                          });
                          if (result.ok) {
                            hosts.add(host);
                            setState(() {
                              connectionState = ConnectionState.connected;
                            });
                          } else {
                            setState(() {
                              connectionState = ConnectionState.disconnected;
                            });
                            String msg = result.error.toString();
                            await showText(
                                msg.toString().substring(0, msg.indexOf(" (")));
                          }
                        }
                      } else if (connectionState == ConnectionState.connected) {
                        await widget.socket.close();
                        setState(() {
                          connectionState = ConnectionState.disconnected;
                        });
                      }
                    },
                    child: connectionState == ConnectionState.loading
                        ? Center(
                            child: LoadingAnimationWidget.staggeredDotsWave(
                                color: palette.text, size: 30))
                        : Text(connectionState == ConnectionState.disconnected
                            ? "Connect"
                            : "Disconnect"),
                  ),
                ),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 128,
                    maxHeight: 40,
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: palette.text,
                      backgroundColor: palette.accent,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: isScanning
                        ? () async {
                            await scanSubscription.cancel();
                            setState(() {
                              isScanning = false;
                            });
                          }
                        : () {
                            hosts.clear();
                            getLocalIpAddresses();
                            setState(() {
                              isScanning = true;
                            });
                          },
                    child: isScanning
                        ? const Text("Stop Scan")
                        : const Text("Scan Network"),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                    width: 200,
                    height: 40,
                    child: Column(
                      children: <Widget>[
                        Text(
                          "Scan progress: ${loadingProgress.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 20,
                            color: palette.text,
                          ),
                        ),
                        LinearProgressIndicator(
                          value: loadingProgress,
                          color: palette.accent,
                          backgroundColor: palette.text,
                        ),
                      ],
                    )),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 128,
                    maxHeight: 40,
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: palette.text,
                      backgroundColor: palette.accent,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () async {
                      if (connectionState == ConnectionState.disconnected) {
                        showText("Requires an active connection");
                        return;
                      }
                      final result = await showDialog<ESCCalibration>(
                          context: context,
                          builder: (context) {
                            return StatefulBuilder(
                                builder: (context, setState) {
                              scanSubscription.onData((host) {
                                setState(() {
                                  hosts.add(host);
                                });
                              });
                              return SimpleDialog(
                                backgroundColor: palette.hHighlight,
                                children: <Widget>[
                                  ...{
                                    'Send maximum values': ESCCalibration.max,
                                    'Send minimum values': ESCCalibration.min,
                                    'CANCEL': ESCCalibration.none,
                                  }.entries.map((option) => SimpleDialogOption(
                                        onPressed: () {
                                          Navigator.pop(context, option.value);
                                        },
                                        child: Text(
                                          option.key,
                                          style: TextStyle(color: palette.text),
                                        ),
                                      )),
                                ],
                              );
                            });
                          });
                      // ...dialogOptions,
                      switch (result) {
                        case ESCCalibration.max:
                          widget.socket.motorSpeed(1.0);
                          break;
                        case ESCCalibration.min:
                          widget.socket.motorSpeed(0.0);
                          break;
                        case ESCCalibration.none:
                        default:
                          break;
                      }
                    },
                    child: const Text("Calibrate ESC"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[],
            ),
            const SizedBox(height: 8),
            Text(
              "Network options",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: palette.text,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 128,
                    maxHeight: 40,
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: palette.text,
                      backgroundColor: palette.accent,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      final textField = TextEditingController();
                      textField.text = portNum.toString();
                      showText("Enter A Port Number", textField).then((_) {
                        if (textField.text.isEmpty) return;
                        int? val = int.tryParse(textField.text);
                        if (val == null) {
                          showText("Enter a valid number");
                        } else {
                          portNum = val;
                        }
                      });
                    },
                    child: const Text("Set Net Port"),
                  ),
                ),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 128,
                    maxHeight: 40,
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: palette.text,
                      backgroundColor: palette.accent,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      final textField = TextEditingController();
                      textField.text = handshake.send;
                      showText("Enter Handshake to Send", textField).then((_) {
                        if (textField.text.isEmpty) return;
                        handshake.send = textField.text;
                      });
                    },
                    child: const Text("Set Handshake Send"),
                  ),
                ),
                const SizedBox(width: 16),
                ConstrainedBox(
                  constraints: const BoxConstraints(),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: palette.text,
                      backgroundColor: palette.accent,
                      textStyle: const TextStyle(fontSize: 16),
                    ),
                    onPressed: () {
                      final textField = TextEditingController();
                      textField.text = handshake.recv;
                      showText("Enter Handshake to Recieve", textField)
                          .then((_) {
                        if (textField.text.isEmpty) return;
                        handshake.recv = textField.text;
                      });
                    },
                    child: const Text("Set Handshake Recieve"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "Submarine (Beta)",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: palette.text,
              ),
            ),
            const Row(
              children: <Widget>[],
            ),
          ],
        )));
  }

  @override
  void dispose() {
    scanSubscription.cancel();
    isScanning = false;
    super.dispose();
  }
}

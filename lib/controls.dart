import 'package:flutter/material.dart';

import 'flutter_joystick/flutter_joystick.dart';

import 'transport.dart';
import 'palette.dart';

class Livestream extends StatelessWidget {
  const Livestream({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      child: Container(
        decoration: BoxDecoration(
            border: Border.all(width: 5, color: palette.lHighlight),
            borderRadius: const BorderRadius.all(Radius.circular(8))),
        child: Image.asset("assets/submarine.jpg"), // this will be a stream
      ),
    );
  }
}

enum Steering { speed, angle }

class Controls extends StatefulWidget {
  final ConnectSocket socket;

  const Controls({super.key, required this.socket});

  @override
  State<StatefulWidget> createState() => ControlsState();
}

class ControlsState extends State<Controls> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: palette.backgorund,
        child: Stack(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: Joystick(
                      listener: (StickDragDetails details) async {
                        await widget.socket.motorSpeed(details.y);
                      },
                      mode: JoystickMode.vertical,
                    ),
                  ),
                  const Expanded(
                    flex: 3,
                    child: Livestream(),
                  ),
                  Expanded(
                    child: Joystick(
                      listener: (StickDragDetails details) async {
                        await widget.socket.steerX(details.x);
                        await widget.socket.steerY(details.y);
                      },
                      mode: JoystickMode.all,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

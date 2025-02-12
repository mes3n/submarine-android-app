import 'package:flutter/material.dart';

import '../../palette.dart';

class JoystickStick extends StatelessWidget {
  const JoystickStick({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: palette.accent,
        // boxShadow: [
        //   BoxShadow(
        //     color: Colors.blue.withOpacity(0.5),
        //     spreadRadius: 5,
        //     blurRadius: 7,
        //     offset: const Offset(0, 3),
        //   )
        // ],
        // gradient: LinearGradient(
        //   begin: Alignment.topCenter,
        //   end: Alignment.bottomCenter,
        //   colors: [
        //     Colors.lightBlue.shade900,
        //     Colors.lightBlue.shade400,
        //   ],
        // ),
      ),
    );
  }
}

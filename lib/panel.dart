import 'package:flutter/material.dart';

import 'controls.dart';
import 'settings.dart';

import 'palette.dart';

import 'transport.dart';

enum WidgetMarker { controls, settings }

class MainPanel extends StatefulWidget {
  const MainPanel({super.key});

  @override
  State<StatefulWidget> createState() => MainPanelState();
}

class MainPanelState extends State<MainPanel> {
  var _selectedWidget = WidgetMarker.controls;
  static final _socket = ConnectSocket();

  static final Map<WidgetMarker, Widget> _widgetMap = {
    WidgetMarker.controls: Controls(socket: _socket),
    WidgetMarker.settings: Settings(socket: _socket),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      color: palette.backgorund,
      child: Stack(
        children: <Widget>[
          Align(
            alignment: Alignment.center,
            child: _widgetMap[_selectedWidget],
          ),
          Align(
            alignment: const Alignment(0.98, 0.95),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.accent,
              ),
              child: PopupMenuButton(
                icon: const Icon(
                  Icons.more_vert_outlined,
                ),
                color: palette.hHighlight,
                itemBuilder: (context) => <PopupMenuItem>[
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 4),
                        Text("Settings",
                            style: TextStyle(color: palette.accent)),
                        const SizedBox(width: 20),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedWidget = WidgetMarker.settings;
                      });
                    },
                  ),
                  PopupMenuItem(
                    child: Row(
                      children: [
                        Icon(
                          Icons.gamepad_outlined,
                          color: palette.accent,
                        ),
                        const SizedBox(width: 4),
                        Text("Controls",
                            style: TextStyle(color: palette.accent)),
                        const SizedBox(width: 20),
                      ],
                    ),
                    onTap: () {
                      setState(() {
                        _selectedWidget = WidgetMarker.controls;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _socket.close();
    super.dispose();
  }
}

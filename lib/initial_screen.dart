import 'package:flutter/material.dart';

class InitialScreen extends StatelessWidget {
  final List<Widget> buttons;
  final double centralButtonDiameter;
  final double bottomPadding;
  InitialScreen({
    super.key,
    required this.buttons,
    required this.centralButtonDiameter,
    required this.bottomPadding,
  }) {
    assert(buttons.length.isEven);
  }

  @override
  Widget build(BuildContext context) {
    const edgePaddingFlex = 1;
    const betweenButtonsPaddingFlex = 3;
    const betweenButtonAndCentralButtonPaddingFlex = 2;

    final rowChildren = <Widget>[];
    for (var i = 0; i < buttons.length; ++i) {
      if (i == 0) {
        rowChildren.add(const Spacer(flex: edgePaddingFlex));
        rowChildren.add(buttons.first);
      } else {
        rowChildren.add(Spacer(
          flex: i == buttons.length ~/ 2 ? betweenButtonAndCentralButtonPaddingFlex : betweenButtonsPaddingFlex,
        ));

        rowChildren.add(buttons[i]);
        if (i == buttons.length - 1) {
          rowChildren.add(const Spacer(flex: edgePaddingFlex));
        }
      }
      if (i + 1 == buttons.length ~/ 2) {
        rowChildren.add(const Spacer(flex: betweenButtonAndCentralButtonPaddingFlex));
        rowChildren.add(SizedBox.square(dimension: centralButtonDiameter));
      }
    }
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(flex: 1),
          Text(
            'Events',
            style: TextStyle(
              color: Colors.blue.shade900,
              fontSize: 35,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(flex: 2),
          Padding(
            padding: EdgeInsets.only(bottom: bottomPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: rowChildren,
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'gum_animation/gum_animation.dart';
import 'initial_screen.dart';

void main() {
  runApp(
    const MaterialApp(
      home: Material(
        child: Home(),
      ),
    ),
  );
}

class Home extends StatelessWidget {
  const Home({super.key});

  double get _buttonDiameter => 50;
  double get _bottomPadding => 10;

  @override
  Widget build(BuildContext context) {
    return GumAnimation(
      buttonDiameter: _buttonDiameter,
      finalColor: Colors.white,
      mainColor: Colors.blue,
      bottomPadding: _bottomPadding,
      initialScreen: InitialScreen(
        buttons: [
          for (final icon in [
            Icons.language,
            Icons.search,
            Icons.power,
            Icons.podcasts,
          ])
            IconButton(
              onPressed: () {},
              icon: Icon(icon),
              color: Colors.purple,
            ),
        ],
        centralButtonDiameter: _buttonDiameter,
        bottomPadding: _bottomPadding,
      ),
      menuList: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final name in ['Reminder', 'Camera', 'Attachment', 'Text Note', 'Attachment', 'Text Note'])
              Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: TextButton(
                  style: ButtonStyle(
                    overlayColor: MaterialStateProperty.all(
                      Colors.amber,
                    ),
                  ),
                  onPressed: () {},
                  child: Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                    ),
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

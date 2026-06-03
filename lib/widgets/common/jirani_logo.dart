import 'package:flutter/material.dart';

class JiraniLogo extends StatelessWidget {
  const JiraniLogo({super.key, this.height = 82});

  final double height;

  static const _lightLogo = 'assets/In-app-logo-Jirani.png';
  static const _darkLogo = 'assets/In-app-logo-dark-mode-Jirani.png';

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;

    return Image.asset(
      brightness == Brightness.dark ? _darkLogo : _lightLogo,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Jirani',
    );
  }
}

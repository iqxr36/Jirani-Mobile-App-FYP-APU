import 'package:flutter/material.dart';

class JiraniLogo extends StatelessWidget {
  const JiraniLogo({super.key, this.height = 82});

  final double height;

  static const _logo = 'assets/In-app Jirani no background.png';

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _logo,
      height: height,
      fit: BoxFit.contain,
      semanticLabel: 'Jirani',
    );
  }
}

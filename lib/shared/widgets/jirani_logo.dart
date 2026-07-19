// Programmer Name : Mr. Faisal Mohammed Ezzaddin Saif Ahmed
// Programme Name  : jirani_logo.dart (Dart source file)
// Description     : Jirani - a community trust marketplace for verified residents to borrow items, offer services, connect with neighbors, and build reputation.
// First Written on: Saturday,13-June-2026
// Last Edited on  : Saturday,18-July-2026

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

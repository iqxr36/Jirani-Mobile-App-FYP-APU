import 'package:flutter/material.dart';

class SavedItemsView extends StatelessWidget {
  const SavedItemsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Items')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Saved items will be implemented in a later phase.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class SuperadminScreen extends StatelessWidget {
  const SuperadminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Superadmin Dashboard"),
      ),
      body: const Center(
        child: Text(
          "Welcome, Superadmin!",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}

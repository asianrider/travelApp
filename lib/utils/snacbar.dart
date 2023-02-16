import 'package:flutter/material.dart';

extension SnackBarContext on BuildContext {
  void openSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Container(
        alignment: Alignment.centerLeft,
        height: 60,
        child: Text(
          message,
          style: TextStyle(
            fontSize: 14,
          ),
        ),
      ),
      action: SnackBarAction(
        label: 'Ok',
        textColor: Colors.blueAccent,
        onPressed: () {},
      ),
    ));
  }
}

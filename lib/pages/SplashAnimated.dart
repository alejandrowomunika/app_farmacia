import 'package:flutter/material.dart';


class SplashAnimated extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pushReplacementNamed(context, "/");
    });

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image.asset('assets/splash.gif'),
      ),
    );
  }
}

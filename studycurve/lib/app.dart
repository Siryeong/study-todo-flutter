import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:studycurve/login.dart';
import 'package:studycurve/home.dart';

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study with me',
      home: Login(),
      initialRoute: '/login',
      onGenerateRoute: _getRoute,
    );
  }

  Route<dynamic>? _getRoute(RouteSettings settings) {
    if (settings.name == '/login') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => Login(),
        fullscreenDialog: true,
      );
    }

    if (settings.name == '/home') {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (BuildContext context) => Home(),
        fullscreenDialog: true,
      );
    }

    return null;
  }
}

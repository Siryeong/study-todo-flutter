import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:studycurve/calendar.dart';
import 'package:studycurve/complete.dart';
import 'package:studycurve/settings.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<Widget> screens = [Calendar(), Complete(), Settings()];
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: screens[_selected]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selected,
        items: const [
          BottomNavigationBarItem(
            label: 'calendar',
            icon: Icon(Icons.calendar_today),
          ),
          BottomNavigationBarItem(
            label: 'complete',
            icon: Icon(Icons.check),
          ),
          BottomNavigationBarItem(
            label: 'settings',
            icon: Icon(Icons.settings),
          ),
        ],
        onTap: _bottomNavigationTap,
      ),
    );
  }

  void _bottomNavigationTap(int index) {
    setState(() {
      _selected = index;
    });
  }
}

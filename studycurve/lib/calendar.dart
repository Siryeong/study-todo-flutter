import 'package:intl/intl.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

import 'utils.dart';

class Calendar extends StatefulWidget {
  const Calendar({Key? key}) : super(key: key);

  @override
  _CalendarState createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  final _auth = FirebaseAuth.instance.currentUser;
  late final CollectionReference dateCollection;
  late final CollectionReference taskCollection;

  late final ValueNotifier<List<Event>> _selectedEvents;

  final frequency = ['1', '2', '3', '4', '5'];
  String _frequency = '1';

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = kToday;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    initCollection();
    _selectedDay = _focusedDay;
    _selectedEvents = ValueNotifier(_getEventsForDay(_selectedDay!));
    getEventByDate();
    getEventByTask();
  }

  void initCollection() {
    dateCollection = FirebaseFirestore.instance
        .collection(_auth!.uid)
        .doc('documents')
        .collection('byDate');

    taskCollection = FirebaseFirestore.instance
        .collection(_auth!.uid)
        .doc('documents')
        .collection('byTask');
  }

  String dateToString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  void getEventByDate() async {
    await dateCollection.get().then((value) {
      for (var v in value.docs) {
        final _events = {
          DateTime.parse(v.id): List.generate(
              v['tasks'].length, (index) => Event.fromJson(v['tasks'][index]))
        };
        kEvents.addAll(_events);
      }
    });
    setState(() {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  void getEventByTask() {
    taskCollection.get().then((value) {
      for (var v in value.docs) {
        final _tasks = {
          v.id: List.generate(
              v['dates'].length, (index) => Task.fromJson(v['dates'][index]))
        };
        kTasks.addAll(_tasks);
      }
    });
  }

  @override
  void dispose() {
    _selectedEvents.dispose();
    super.dispose();
  }

  void _addTaskByDate(Event e) {
    for (double i = 0; i < double.parse(_frequency); i += 1) {
      var tmp = _selectedDay!.add(Duration(days: exp(i / 1.5).round() - 1));
      if (kEvents[tmp] == null) {
        kEvents.addAll({
          tmp: [e]
        });
      } else {
        kEvents[tmp]!.add(e);
      }
      dateCollection.doc(dateToString(tmp)).set({
        'tasks': List.generate(
            kEvents[tmp]!.length, (index) => kEvents[tmp]![index].toJson())
      });
    }
  }

  void _addDateByTask(Event e) {
    if (kTasks[e.title] == null) {
      kTasks.addAll({
        e.title: List.generate(
          int.parse(_frequency),
          (index) => Task(
            date: dateToString(_selectedDay!
                .add(Duration(days: exp(index.toDouble() / 1.5).round() - 1))),
          ),
        )
      });
    } else {
      for (double index = 0; index < double.parse(_frequency); index += 1) {
        kTasks[e.title]!.add(
          Task(
            date: dateToString(
              _selectedDay!
                  .add(Duration(days: exp(index.toDouble() / 1.5).round() - 1)),
            ),
          ),
        );
      }
    }
    kTasks[e.title]!.sort();
    taskCollection.doc(e.title).set({
      'dates': List.generate(
          kTasks[e.title]!.length, (i) => kTasks[e.title]![i].toJson())
    });
  }

  void addEvent(Event e) {
    _addTaskByDate(e);
    _addDateByTask(e);
    setState(() {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  void _deleteTaskByDate(int index) {
    Event _tmp = kEvents[_selectedDay]!.elementAt(index);
    kEvents[_selectedDay]!.removeAt(index);
    for (int i = 0; i < kTasks[_tmp.title]!.length; i++) {
      if (kTasks[_tmp.title]!.elementAt(i).date ==
          dateToString(_selectedDay!)) {
        kTasks[_tmp.title]!.removeAt(i);
        break;
      }
    }

    if (kEvents[_selectedDay]!.isEmpty) {
      dateCollection.doc(dateToString(_selectedDay!)).delete();
    } else {
      dateCollection.doc(dateToString(_selectedDay!)).set({
        'tasks': List.generate(kEvents[_selectedDay]!.length,
            (index) => kEvents[_selectedDay]![index].toJson())
      });
    }

    if (kTasks[_tmp.title]!.isEmpty) {
      taskCollection.doc(_tmp.title).delete();
    } else {
      taskCollection.doc(_tmp.title).set({
        'dates': List.generate(
            kTasks[_tmp.title]!.length, (i) => kTasks[_tmp.title]![i].toJson())
      });
    }
  }

  void deleteEvent(int index) {
    _deleteTaskByDate(index);
    setState(() {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  void _updateTaskByDate(int index) {
    Event _tmp = kEvents[_selectedDay]!.elementAt(index);
    kEvents[_selectedDay]!.removeAt(index);
    for (int i = 0; i < kTasks[_tmp.title]!.length; i++) {
      if (kTasks[_tmp.title]!.elementAt(i).date ==
          dateToString(_selectedDay!)) {
        kTasks[_tmp.title]![i].finished = true;
        break;
      }
    }

    if (kEvents[_selectedDay]!.isEmpty) {
      dateCollection.doc(dateToString(_selectedDay!)).delete();
    } else {
      dateCollection.doc(dateToString(_selectedDay!)).set({
        'tasks': List.generate(kEvents[_selectedDay]!.length,
            (index) => kEvents[_selectedDay]![index].toJson())
      });
    }
    taskCollection.doc(_tmp.title).set({
      'dates': List.generate(
          kTasks[_tmp.title]!.length, (i) => kTasks[_tmp.title]![i].toJson())
    });
  }

  void updateEvent(int index) {
    _updateTaskByDate(index);
    setState(() {
      _selectedEvents.value = _getEventsForDay(_selectedDay!);
    });
  }

  List<Event> _getEventsForDay(DateTime day) {
    // Implementation example
    return kEvents[day] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _selectedEvents.value = _getEventsForDay(selectedDay);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar<Event>(
          firstDay: kFirstDay,
          lastDay: kLastDay,
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          headerStyle: const HeaderStyle(
            titleCentered: true,
            headerPadding: EdgeInsets.all(30.0),
            formatButtonVisible: false,
            leftChevronVisible: false,
            rightChevronVisible: false,
          ),
          calendarFormat: _calendarFormat,
          eventLoader: _getEventsForDay,
          calendarStyle: const CalendarStyle(
            markerSize: 5.0,
            markersMaxCount: 1,
          ),
          rowHeight: 48.0,
          onDaySelected: _onDaySelected,
          onFormatChanged: (format) {
            if (_calendarFormat != format) {
              setState(() {
                _calendarFormat = format;
              });
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
        ),
        IconButton(
          onPressed: inputEvent,
          icon: const Icon(Icons.add_circle_outline),
          iconSize: 30.0,
        ),
        Expanded(
          child: ValueListenableBuilder<List<Event>>(
            valueListenable: _selectedEvents,
            builder: (context, value, _) {
              return RefreshIndicator(
                displacement: 20.0,
                child: ListView.builder(
                  itemCount: value.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                      ),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(width: 0.1),
                        ),
                      ),
                      child: ListTile(
                        onLongPress: () {
                          updateEvent(index);
                        },
                        title: Text('${value[index]}'),
                        trailing: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              deleteEvent(index);
                            }),
                      ),
                    );
                  },
                ),
                onRefresh: inputEvent,
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> inputEvent() async {
    String input = '';
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Study List'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(hintText: 'Enter your Task'),
                      onChanged: (String value) {
                        input = value;
                      },
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  const Text('Frequency : '),
                  StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                    return DropdownButton(
                      value: _frequency,
                      items: frequency.map((e) {
                        return DropdownMenuItem(
                          child: Text(e),
                          value: e,
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _frequency = val.toString();
                        });
                      },
                    );
                  }),
                ],
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                addEvent(Event(title: input));
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}

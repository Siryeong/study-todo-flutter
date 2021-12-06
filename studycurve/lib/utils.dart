// Copyright 2019 Aleksander Woźniak
// SPDX-License-Identifier: Apache-2.0

import 'dart:collection';

import 'package:table_calendar/table_calendar.dart';

/// Example event class.
class Event {
  String title;
  bool finished;

  Event({required this.title, this.finished = false});

  Event.fromJson(Map<String, Object?> json)
      : this(
          title: json['title']! as String,
          finished: json['finished']! as bool,
        );

  Map<String, Object?> toJson() {
    return {'title': title, 'finished': finished};
  }

  @override
  String toString() => title;
}

class Task implements Comparable<Task> {
  String date;
  bool finished;

  Task({required this.date, this.finished = false});

  Task.fromJson(Map<String, Object?> json)
      : this(
          date: json['date'] as String,
          finished: json['finished'] as bool,
        );

  Map<String, Object?> toJson() {
    return {'date': date, 'finished': finished};
  }

  @override
  int compareTo(Task other) {
    return date.compareTo(other.date);
  }
}

/// Example events.
///
/// Using a [LinkedHashMap] is highly recommended if you decide to use a map.
final kEvents = LinkedHashMap<DateTime, List<Event>>(
  equals: isSameDay,
  hashCode: getHashCode,
);

int getHashCode(DateTime key) {
  return key.day + key.month * 100 + key.year * 10000;
}

final kTasks = LinkedHashMap<String, List<Task>>(
  equals: (String a, String b) {
    return a == b;
  },
);

/// Returns a list of [DateTime] objects from [first] to [last], inclusive.
List<DateTime> daysInRange(DateTime first, DateTime last) {
  final dayCount = last.difference(first).inDays + 1;
  return List.generate(
    dayCount,
    (index) => DateTime.utc(first.year, first.month, first.day + index),
  );
}

final kToday = DateTime.now();
final kFirstDay = DateTime(kToday.year, kToday.month - 4, kToday.day);
final kLastDay = DateTime(kToday.year, kToday.month + 4, kToday.day);

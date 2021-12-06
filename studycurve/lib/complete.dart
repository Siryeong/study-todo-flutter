import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter_slidable/flutter_slidable.dart';

import 'dart:core';

import 'utils.dart';

class Complete extends StatefulWidget {
  const Complete({Key? key}) : super(key: key);

  @override
  _CompleteState createState() => _CompleteState();
}

class _CompleteState extends State<Complete> with TickerProviderStateMixin {
  final _auth = FirebaseAuth.instance.currentUser;
  late final CollectionReference dateCollection;
  late final CollectionReference taskCollection;

  @override
  void initState() {
    super.initState();
    initCollection();
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

  void getEventByDate() {
    dateCollection.get().then((value) {
      for (var v in value.docs) {
        final _events = {
          DateTime.parse(v.id): List.generate(
              v['tasks'].length, (index) => Event.fromJson(v['tasks'][index]))
        };
        kEvents.addAll(_events);
      }
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
  Widget build(BuildContext context) {
    TabController _tabController = TabController(length: 2, vsync: this);
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: Colors.black,
          tabs: const [
            Tab(child: Text('Progress')),
            Tab(child: Text('Complete')),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              Center(
                child: FutureBuilder(
                  future: taskCollection.get(),
                  builder: (BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something Wrong');
                    }
                    if (snapshot.hasData && snapshot.data!.docs.isEmpty) {
                      return const Text('Add Tasks');
                    }
                    if (snapshot.connectionState == ConnectionState.done) {
                      return ListView(
                        children: snapshot.data!.docs
                            .map((DocumentSnapshot document) {
                          Map<String, dynamic> data =
                              document.data()! as Map<String, dynamic>;
                          return Dismissible(
                            key: Key(document.id),
                            child: Card(
                                child: Column(
                              children: [
                                Container(
                                  alignment: Alignment.centerLeft,
                                  padding:
                                      const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                  child: Text(
                                    document.id,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(12, 4, 12, 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: List.generate(
                                        data['dates'].length,
                                        (i) => data['dates'][i]['finished'] ==
                                                false
                                            ? const Icon(Icons.cancel_outlined,
                                                color: Colors.grey)
                                            : const Icon(
                                                Icons.check_circle_outline,
                                                color: Colors.green,
                                              )),
                                  ),
                                )
                              ],
                            )),
                          );
                        }).toList(),
                      );
                    }
                    return const Text('Loading...');
                  },
                ),
              ),
              Center(
                child: Text('world'),
              ),
            ],
          ),
        )
      ],
    );
  }
}

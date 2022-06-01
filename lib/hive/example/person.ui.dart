import 'dart:math';

import 'package:flutter/material.dart';
import 'package:workcake/hive/example/person.model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HiveExampleUi extends StatefulWidget {
  @override
  _HiveExampleUiState createState() => _HiveExampleUiState();
}

class _HiveExampleUiState extends State<HiveExampleUi> {
  var cha;

  @override
  void initState() {
    super.initState();
    _openBox();
  }


  @override
  void dispose() async {
    await Future.delayed(Duration(seconds: 2));
    Hive.close();
    super.dispose();
  }

  Future _openBox() async {

    cha = await Hive.openBox('per');
    // need re render
    setState(() {});
    return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hive example"),
      ),
      body: Column(
        children: <Widget>[
          Wrap(
            children: <Widget>[
              TextButton(
                child: Text("Add item "),
                onPressed: () async {
                  PersonModel personModel = PersonModel(
                      Random().nextInt(100),
                      ""
                      "Vivek",
                      DateTime.now(),
                      false);
                   cha.add(personModel);
                   
             
                },
              ),
              TextButton(
                child: Text("Delete item "),
                onPressed: () {
                  int lastIndex = cha.toMap().length - 1;
                  if (lastIndex >= 0) cha.deleteAt(lastIndex);
                },
              ),
              TextButton(
                child: Text("Update item "),
                onPressed: () {
                  int lastIndex = cha.toMap().length - 1;
                  if (lastIndex < 0) return;

                  PersonModel personModel =
                      cha.values.toList()[lastIndex];
                  personModel.birthDate = DateTime.now();
                  cha.putAt(lastIndex, personModel);
                },
              ),
            ],
          ),
          Text("Data in database"),
          cha == null
              ? Text("Box is not initialized")
              : Expanded(
                  // ignore: deprecated_member_use
                  child: WatchBoxBuilder(
                    box: cha,
                    builder: (context, box) {
                      Map<dynamic, dynamic> raw = box.toMap();
                      List list = raw.values.where((element) {
                        print(element.status);
                        return true;}).toList();

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          PersonModel personModel = list[index];
                          return ListTile(
                            title: Text(personModel.name),
                            leading: Text(personModel.id.toString()),
                            subtitle: Text(
                                personModel.birthDate.toLocal().toString()),
                          );
                        },
                      );
                    },
                  ),
                )
        ],
      ),
    );
  }
}

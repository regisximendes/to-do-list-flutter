import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(MaterialApp(home: Home()));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  void initState() {
    super.initState();

    _readFile().then((data) => {
          setState(() {
            _itemsList = json.decode(data);
          })
        });
  }

  final _textFieldController = TextEditingController();

  List _itemsList = [];

  Map<String, dynamic> _lastItemRemoved = Map();
  int _lastPosistionRemoved;

  void _addTask() {
    setState(() {
      Map<String, dynamic> task = new Map();
      task["title"] = _textFieldController.text;
      task["done"] = false;
      _itemsList.add(task);

      _saveData();
      _clearTextField();
    });
  }

  void _clearTextField() {
    _textFieldController.text = "";
  }

  Future<Null> _refresh() async {
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _itemsList.sort((a, b) {
        if (a["done"] && !b["done"])
          return 1;
        else if (!a["done"] && b["done"])
          return 2;
        else
          return 0;
      });
      _saveData();
    });

    return Null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("To Do"),
        centerTitle: true,
        backgroundColor: Colors.orangeAccent,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(16),
            child: Row(
              children: <Widget>[
                Expanded(
                    child: TextField(
                  controller: _textFieldController,
                  decoration: InputDecoration(
                      labelText: "New task",
                      labelStyle: TextStyle(color: Colors.orangeAccent)),
                )),
                RaisedButton(
                  child: Text("ADD"),
                  onPressed: _addTask,
                  color: Colors.orangeAccent,
                  textColor: Colors.white,
                )
              ],
            ),
          ),
          Expanded(
              child: RefreshIndicator(
                  child: ListView.builder(
                      padding: EdgeInsets.only(top: 16),
                      itemCount: _itemsList.length,
                      itemBuilder: viewHolder),
                  onRefresh: _refresh))
        ],
      ),
    );
  }

  Widget viewHolder(context, index) {
    return Dismissible(
      key: Key(index.toString()),
      onDismissed: (direction) {
        setState(() {
          _lastItemRemoved = Map.from(_itemsList[index]);
          _lastPosistionRemoved = index;
          _itemsList.removeAt(index);

          _saveData();

          final snackbar = SnackBar(
            content: Text("Tasl ${_lastItemRemoved["title"]} deleted"),
            action: SnackBarAction(
                label: "undo",
                onPressed: () {
                  setState(() {
                    _itemsList.insert(_lastPosistionRemoved, _lastItemRemoved);
                    _saveData();
                  });
                }),
            duration: Duration(seconds: 2),
          );

          Scaffold.of(context).showSnackBar(snackbar);
        });
      },
      background: Container(
        color: Colors.red,
        child: Align(
          alignment: Alignment(-0.9, 0.0),
          child: Icon(Icons.delete),
        ),
      ),
      direction: DismissDirection.startToEnd,
      child: CheckboxListTile(
        onChanged: (checked) {
          setState(() {
            _itemsList[index]["done"] = checked;
            _saveData();
          });
        },
        title: Text(_itemsList[index]["title"]),
        value: _itemsList[index]["done"],
        secondary: CircleAvatar(
          child: Icon(
            _itemsList[index]["done"] ? Icons.check : Icons.error,
            color: Colors.orangeAccent,
          ),
        ),
      ),
    );
  }

  Future<File> _getFile() async {
    var directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async {
    String data = json.encode(_itemsList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readFile() async {
    try {
      var file = await _getFile();
      return file.readAsString();
    } catch (e) {
      return null;
    }
  }
}

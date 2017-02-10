# Dart observables for flutter

A micro framework inspired by  vue's observables (small, simple).

The name was derived from mendix's mobx for react.

## Model
todo/lib/todo.dart
```dart
import 'package:dobx/dobx.dart' show PubSub, ObservableList;

// this boilerplate is usually generated by a compiler with something like:
/// message Todo {
///   required string title = 1;
///   optional bool completed = 2; [ default = false ];
/// }
class Todo {
  static Todo create(String title, {
    bool completed,
  }) {
    assert (title != null);
    return new Todo()
      .._title = title
      .._completed = completed;
  }

  static Todo createObservable(String title, {
    bool completed = false,
  }) {
    assert (title != null);
    return new _Todo()
      .._title = title
      .._completed = completed;
  }

  String _title;
  bool _completed;

  get title => _title;
  set title(String title) { _title = title; }

  get completed => _completed;
  set completed(bool completed) { _completed = completed; }
}

class _Todo extends Todo with PubSub {

  get title { sub(1); return _title; }
  set title(String title) { if (title != null && title == _title) return; _title = title ?? ''; pub(1); }

  get completed { sub(2); return _completed; }
  set completed(bool completed) { if (completed != null && completed == _completed) return; _completed = completed ?? false; pub(2); }
}

// ==================================================
// The app with the observables

class App {
  final List<Todo> _todos = new ObservableList<Todo>();
  final Todo pnew;

  App(String initialText) : pnew = Todo.createObservable(initialText);
  
  // passing null subscribes the caller if tracking is on.
  List<Todo> get todos => _todos.sublist(null);
}
```

## Flutter app
lib/main.dart
```dart
import 'package:flutter/material.dart';
import 'package:dobx/dobx.dart';
import 'package:todo/todo.dart';

void main() {
  runApp(new AppWidget());
}

// Dynamic parts
enum Root {
  $todo_input,
  $todo_list,
}

class AppWidget extends StatelessWidget {
  final App app = new App('');
  // widget factory for the reactive views
  final WF wf = WF.get(0);
  
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Todo List',
      home: new Scaffold(
        appBar: new AppBar(
          title: new Text('Todo List'),
          bottom: new ui.AppBarWidget(newBar),
        ),
        body: new Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: wf.$($todo_list, Root.$todo_list),
        ),
      ),
    );
  }

  Widget newBar(BuildContext context) {
    return new Column(
      children: <Widget>[
        ui.fluid_box(ui.input_label('What needs to be done?'),
        ui.fluid_box(wf.$($todo_input, Root.$todo_input)),
      ],
    );
  }

  void onTitleChanged(InputValue iv) {
    final String title = iv.text.trim();
    if (title.isEmpty) return;

    // newest first
    app.todos.insert(0, Todo.create(title, completed: false));
    // pass null to force clear
    app.pnew.title = null;
  }

  Widget $todo_input(BuildContext context) {
    return ui.fluid_input(app.pnew.title, onTitleChanged);
  }
  
  Widget $todo_list(BuildContext context) {
    // build your todo list
  }
```

You can find the example's code in [todo_example](https://github.com/dbox/todo_example)


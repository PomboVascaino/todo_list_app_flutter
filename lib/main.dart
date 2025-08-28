import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'task_model.dart';


void main() {
runApp(const TodoListApp());
}


class TodoListApp extends StatelessWidget {
const TodoListApp({Key? key}) : super(key: key);


@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Todo List App',
theme: ThemeData(
primarySwatch: Colors.indigo,
),
home: const TasksPage(),
);
}
}


class TasksPage extends StatefulWidget {
const TasksPage({Key? key}) : super(key: key);


@override
State<TasksPage> createState() => _TasksPageState();
}


class _TasksPageState extends State<TasksPage> {
final List<Task> _tasks = [];
final String _storageKey = 'tasks_data';
bool _isLoading = true;


@override
void initState() {
super.initState();
_loadTasks();
}


Future<void> _loadTasks() async {
setState(() => _isLoading = true);
final prefs = await SharedPreferences.getInstance();
final jsonString = prefs.getString(_storageKey);
if (jsonString != null && jsonString.isNotEmpty) {
try {
final List<dynamic> data = jsonDecode(jsonString);
_tasks.clear();
for (var item in data) {
if (item is Map<String, dynamic>) {
_tasks.add(Task.fromMap(item));
} else if (item is String) {
// in case it was encoded as json strings
_tasks.add(Task.fromMap(jsonDecode(item)));
}
}
} catch (e) {
// problema ao desserializar -> ignora e zera
_tasks.clear();
}
}
setState(() => _isLoading = false);
}


Future<void> _saveTasks() async {
final prefs = await SharedPreferences.getInstance();
final List<Map<String, dynamic>> toSave = _tasks.map((t) => t.toMap()).toList();
await prefs.setString(_storageKey, jsonEncode(toSave));
}


void _addTask(Task task) {
setState(() {
_tasks.add(task);
});
_saveTasks();
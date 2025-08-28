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
      title: 'Tarefas do Dia',
      theme: ThemeData(primarySwatch: Colors.indigo),
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
          } else if (item is Map) {
            _tasks.add(Task.fromMap(Map<String, dynamic>.from(item)));
          } else if (item is String) {
            _tasks.add(Task.fromMap(jsonDecode(item)));
          }
        }
      } catch (e) {
        _tasks.clear();
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> toSave = _tasks
        .map((t) => t.toMap())
        .toList();
    await prefs.setString(_storageKey, jsonEncode(toSave));
  }

  void _addTask(Task task) {
    setState(() {
      _tasks.add(task);
    });
    _saveTasks();
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
    _saveTasks();
  }

  void _toggleDone(int index, bool? value) {
    if (value == null) return;
    setState(() {
      _tasks[index].isDone = value;
    });
    _saveTasks();
  }

  int get _completedCount => _tasks.where((t) => t.isDone).length;

  Future<void> _clearCompleted() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover concluídas?'),
        content: const Text('Deseja remover todas as tarefas concluídas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _tasks.removeWhere((t) => t.isDone);
      });
      _saveTasks();
    }
  }

  void _editTask(int index) async {
    final controller = TextEditingController(text: _tasks[index].title);
    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Editar tarefa'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Título'),
          onSubmitted: (_) => Navigator.of(ctx).pop(controller.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _tasks[index].title = result;
      });
      _saveTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Tarefas'),
        actions: [
          IconButton(
            tooltip: 'Remover concluídas',
            onPressed: _tasks.any((t) => t.isDone) ? _clearCompleted : null,
            icon: const Icon(Icons.delete_sweep),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 16.0,
            ),
            child: Center(child: Text('Concluídas: $_completedCount')),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _tasks.isEmpty
          ? const Center(child: Text('Nenhuma tarefa. Toque + para adicionar.'))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: _tasks.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final task = _tasks[index];
                return Dismissible(
                  key: ValueKey(task.title + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.redAccent,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) => _removeTask(index),
                  child: ListTile(
                    leading: Checkbox(
                      value: task.isDone,
                      onChanged: (v) => _toggleDone(index, v),
                    ),
                    title: GestureDetector(
                      onTap: () => _editTask(index),
                      child: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isDone
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeTask(index),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final Task? newTask = await Navigator.of(
            context,
          ).push<Task?>(MaterialPageRoute(builder: (_) => const AddTaskPage()));
          if (newTask != null) _addTask(newTask);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class AddTaskPage extends StatefulWidget {
  final Task? initialTask;
  const AddTaskPage({Key? key, this.initialTask}) : super(key: key);

  @override
  State<AddTaskPage> createState() => _AddTaskPageState();
}

class _AddTaskPageState extends State<AddTaskPage> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTask?.title ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final task = Task(title: text, isDone: widget.initialTask?.isDone ?? false);
    Navigator.of(context).pop(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.initialTask == null ? 'Adicionar Tarefa' : 'Editar Tarefa',
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Título da tarefa'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _save, child: const Text('Salvar')),
          ],
        ),
      ),
    );
  }
}

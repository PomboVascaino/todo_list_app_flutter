import 'dart:convert';

class Task {
  String title;
  bool isDone;

  Task({required this.title, this.isDone = false});

  Map<String, dynamic> toMap() {
    return {'title': title, 'isDone': isDone};
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(title: map['title'] ?? '', isDone: map['isDone'] ?? false);
  }

  String toJson() => jsonEncode(toMap());

  factory Task.fromJson(String source) => Task.fromMap(jsonDecode(source));
}

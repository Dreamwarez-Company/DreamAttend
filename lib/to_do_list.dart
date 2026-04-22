import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/models/todo_task.dart';
import '/services/todo_service.dart';
import 'utils/app_layout.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ToDo List',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const ToDoList(),
    );
  }
}

class ToDoList extends StatefulWidget {
  const ToDoList({super.key});

  @override
  ToDoListState createState() => ToDoListState();
}

class ToDoListState extends State<ToDoList> {
  final ToDoService _todoService = ToDoService();
  List<ToDoTask> _tasks = [];
  final TextEditingController _taskController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _todoService.fetchTasks();
      setState(() => _tasks = tasks);
    } catch (e) {
      _showError('Failed to load tasks: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _addTask() async {
    if (_taskController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final newTask = await _todoService.createTask(
        _taskController.text.trim(),
      );
      setState(() {
        _tasks.insert(0, newTask);
        _taskController.clear();
      });
    } catch (e) {
      _showError('Failed to add task: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTask(int index) async {
    final taskId = _tasks[index].id;
    if (taskId == null) return;

    setState(() => _isLoading = true);
    try {
      await _todoService.deleteTask(taskId);
      setState(() => _tasks.removeAt(index));
    } catch (e) {
      _showError('Failed to delete task: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleCompletion(int index) async {
    final task = _tasks[index];
    if (task.id == null) return;

    setState(() => _isLoading = true);
    try {
      final updatedTask = await _todoService.toggleTaskCompletion(task);
      setState(() {
        _tasks[index] = updatedTask;
      });
    } catch (e) {
      _showError('Failed to update task: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    errorSnackBar('Error', message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FB),
      appBar: AppBar(
        title: const Text('To-Do List'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 7, 56, 80),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      hintText: 'Enter a new task',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _addTask(),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 7, 56, 80),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addTask,
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color.fromARGB(255, 7, 56, 80),
            ),
          Expanded(
            child: _tasks.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks yet. Add one!',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    color: const Color.fromARGB(255, 7, 56, 80),
                    child: ListView.builder(
                      itemCount: _tasks.length,
                      itemBuilder: (context, index) {
                        final task = _tasks[index];
                        return Dismissible(
                          key: Key('task-${task.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          onDismissed: (_) => _deleteTask(index),
                          confirmDismiss: (_) async {
                            return await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Confirm Delete'),
                                content: const Text(
                                  'Are you sure you want to delete this task?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: CheckboxListTile(
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  decoration: task.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: task.createdAt != null
                                  ? Text(
                                      DateFormat(
                                        'MM dd, yyyy - hh:mm a',
                                      ).format(task.createdAt!),
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                              value: task.isCompleted,
                              onChanged: (_) => _toggleCompletion(index),
                              secondary: IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () => _deleteTask(index),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

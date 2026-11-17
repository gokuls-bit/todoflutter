import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

void main() {
  runApp(const TodoApp());
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  void _toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ProTodo',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF10B981),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: TodoScreen(onToggleTheme: _toggleTheme, themeMode: _themeMode),
    );
  }
}

enum TaskCategory { work, personal, urgent }

class Todo {
  Todo({
    required this.title,
    this.isCompleted = false,
    this.category = TaskCategory.personal,
  });

  final String title;
  bool isCompleted;
  TaskCategory category;
}

class TodoScreen extends StatefulWidget {
  const TodoScreen({
    required this.onToggleTheme,
    required this.themeMode,
    super.key,
  });

  final VoidCallback onToggleTheme;
  final ThemeMode themeMode;

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  final List<Todo> _todos = [
    Todo(title: 'Review MERN stack project architecture', category: TaskCategory.work),
    Todo(title: 'Hit the gym for an intense upper-body session', category: TaskCategory.urgent, isCompleted: true),
    Todo(title: 'Practice guitar chords for new song', category: TaskCategory.personal),
  ];
  
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  
  String _filter = 'All';
  TaskCategory _selectedCategory = TaskCategory.personal;
  String _searchQuery = '';
  
  final GlobalKey _screenshotKey = GlobalKey();
  bool _isSharing = false;

  void _addTodo() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;

    setState(() {
      _todos.insert(0, Todo(title: title, category: _selectedCategory));
      _controller.clear();
    });
  }

  void _toggleTodo(Todo todo, bool? value) {
    setState(() {
      todo.isCompleted = value ?? false;
    });
  }

  void _deleteTodo(Todo todo) {
    setState(() {
      _todos.remove(todo);
    });
  }

  List<Todo> get _filteredTodos {
    return _todos.where((todo) {
      // Filter by status/tab
      bool matchesTab = true;
      if (_filter == 'Pending') matchesTab = !todo.isCompleted;
      if (_filter == 'Completed') matchesTab = todo.isCompleted;

      // Filter by search query
      bool matchesSearch = todo.title.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesTab && matchesSearch;
    }).toList();
  }

  Future<void> _shareScreenshot() async {
    setState(() => _isSharing = true);
    try {
      // Find the render boundary for the main card container
      final boundary = _screenshotKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final xFile = XFile.fromData(
        pngBytes,
        mimeType: 'image/png',
        name: 'mytodo_summary.png',
      );

      await Share.shareXFiles(
        [xFile],
        text: '🚀 Check out my current productivity status on ProTodo!',
      );
    } catch (e) {
      if (kDebugMode) print('Error sharing screenshot: $e');
    } finally {
      setState(() => _isSharing = false);
    }
  }

  Color _getCategoryColor(TaskCategory category) {
    switch (category) {
      case TaskCategory.work:
        return Colors.blue;
      case TaskCategory.urgent:
        return Colors.redAccent;
      case TaskCategory.personal:
        return Colors.green;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = _todos.where((todo) => todo.isCompleted).length;
    final progress = _todos.isEmpty ? 0.0 : completedCount / _todos.length;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.tealAccent),
            SizedBox(width: 8),
            Text(
              'ProTodo Workspace',
              style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              widget.themeMode == ThemeMode.dark
                  ? Icons.wb_sunny_rounded
                  : Icons.nightlight_round,
            ),
            tooltip: 'Toggle Theme',
            onPressed: widget.onToggleTheme,
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Progress Screenshot',
            onPressed: _isSharing ? null : _shareScreenshot,
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: RepaintBoundary(
              key: _screenshotKey,
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Dashboard Status Card with Progress Bar
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Stay focused & unstoppable!',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$completedCount of ${_todos.length} tasks completed',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 8,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add Task Section
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            onSubmitted: (_) => _addTodo(),
                            decoration: InputDecoration(
                              hintText: 'What needs to be done?',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: const Icon(Icons.edit_note_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Category Dropdown Selector
                        DropdownButton<TaskCategory>(
                          value: _selectedCategory,
                          underline: const SizedBox(),
                          borderRadius: BorderRadius.circular(12),
                          items: TaskCategory.values.map((cat) {
                            return DropdownMenuItem<TaskCategory>(
                              value: cat,
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getCategoryColor(cat),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(cat.name.toUpperCase()),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedCategory = val);
                          },
                        ),
                        const SizedBox(width: 10),
                        IconButton.filled(
                          onPressed: _addTodo,
                          icon: const Icon(Icons.add_rounded),
                          tooltip: 'Add task',
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Search Field
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search tasks...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['All', 'Pending', 'Completed'].map((filter) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(filter),
                              selected: _filter == filter,
                              onSelected: (_) => setState(() => _filter = filter),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Todo Items List
                    Expanded(
                      child: _filteredTodos.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.task_alt,
                                      size: 64,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outline
                                          .withValues(alpha: 0.5)),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No tasks found. Time to relax or add a new one!',
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredTodos.length,
                              itemBuilder: (context, index) {
                                final todo = _filteredTodos[index];

                                return Card(
                                  elevation: 1,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    leading: Checkbox(
                                      value: todo.isCompleted,
                                      onChanged: (val) => _toggleTodo(todo, val),
                                    ),
                                    title: Text(
                                      todo.title,
                                      style: TextStyle(
                                        decoration: todo.isCompleted
                                            ? TextDecoration.lineThrough
                                            : TextDecoration.none,
                                        color: todo.isCompleted
                                            ? Theme.of(context)
                                                .colorScheme
                                                .outline
                                            : null,
                                      ),
                                    ),
                                    subtitle: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: _getCategoryColor(todo.category),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          todo.category.name.toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: _getCategoryColor(todo.category),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () => _deleteTodo(todo),
                                      tooltip: 'Delete task',
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
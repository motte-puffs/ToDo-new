import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(TodoListAdapter());
  Hive.registerAdapter(TodoTaskAdapter());

  final box = await Hive.openBox<TodoList>('todoBox');

  seedInitialData(box);

  runApp(const TodoApp());
}

void seedInitialData(Box<TodoList> box) {
  if (box.isNotEmpty) return;

  box.addAll([
    TodoList(
      name: 'College',
      tasks: [
        TodoTask(title: 'Finish electronics assignment'),
        TodoTask(title: 'Submit DSA report'),
        TodoTask(title: 'Python quiz',isStarred: true),
        TodoTask(title: 'Operating Systems presentation', isCompleted: true),
      ],
    ),
    TodoList(
      name: 'Personal',
      tasks: [
        TodoTask(title: 'Buy groceries'),
        TodoTask(title: 'Call mom', isStarred: true),
        TodoTask(title: 'Book train tickets'),
        TodoTask(title: 'Bike service', isCompleted: true),
      ],
    ),
    TodoList(
      name: 'Watch-List',
      tasks: [
        TodoTask(title: 'The Sopranos'),
        TodoTask(title: 'Berserk'),
        TodoTask(title: 'Reservoir dogs'),
      ],
    ),
  ]);
}


class TodoApp extends StatelessWidget {
  const TodoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'JetBrainsMono',
        scaffoldBackgroundColor: const Color(0xFF141413),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF121212),
          elevation: 0,
        ),
      ),
      home: const TodoHomePage(),
    );
  }
}

@HiveType(typeId: 0)
class TodoList extends HiveObject {
  @HiveField(0)
  String name;

  @HiveField(1)
  List<TodoTask> tasks;

  TodoList({required this.name, required this.tasks});
}

@HiveType(typeId: 1)
class TodoTask extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  bool isCompleted;

  @HiveField(2)
  bool isStarred;

  TodoTask({
    required this.title,
    this.isCompleted = false,
    this.isStarred = false,
  });
}

class TodoHomePage extends StatefulWidget {
  const TodoHomePage({super.key});

  @override
  State<TodoHomePage> createState() => _TodoHomePageState();
}

class _TodoHomePageState extends State<TodoHomePage> {
  bool zigzag = true;
  String search = '';
  final box = Hive.box<TodoList>('todoBox');

  List<TodoList> get lists {
    final data = box.values.toList();
    if (search.isEmpty) return data;
    return data.where((l) {
      return l.name.toLowerCase().contains(search.toLowerCase()) ||
          l.tasks.any((t) =>
              t.title.toLowerCase().contains(search.toLowerCase()));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.view_week),
          onPressed: () => setState(() => zigzag = !zigzag),
        ),
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'SEARCH...',
            border: InputBorder.none,
          ),
          onChanged: (v) => setState(() => search = v),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => box.clear(),
          ),
        ],
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (_, __, ___) {
          return zigzag ? _zigzagView() : _gridView();
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addList,
        child: const Icon(Icons.add),
      ),
    );
  }

Widget _zigzagView() {
  final width = MediaQuery.of(context).size.width;

  return ListView.builder(
    padding: const EdgeInsets.symmetric(vertical: 8),
    itemCount: lists.length,
    itemBuilder: (_, i) {
      final list = lists[i];
      final isLeft = i.isEven;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
          child: GestureDetector(
            onTap: () => _openList(list),
            child: Container(
              width: width * 0.85,
              padding: EdgeInsets.fromLTRB(
                isLeft ? 12 : 24,
                16,
                isLeft ? 24 : 12,
                16,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1c1c1b),

                borderRadius: BorderRadius.only(
                  topLeft:
                      isLeft ? Radius.zero : const Radius.circular(16),
                  bottomLeft:
                      isLeft ? Radius.zero : const Radius.circular(16),
                  topRight:
                      isLeft ? const Radius.circular(16) : Radius.zero,
                  bottomRight:
                      isLeft ? const Radius.circular(16) : Radius.zero,
                ),

                border: Border(
                  left: isLeft
                      ? BorderSide.none
                      : BorderSide(
                          color: Colors.grey.shade700,
                          width: 1,
                        ),
                  right: isLeft
                      ? BorderSide(
                          color: Colors.grey.shade700,
                          width: 1,
                        )
                      : BorderSide.none,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => _editListName(list),
                    child: Text(
                      list.name.toUpperCase(),
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Divider(
                    color: Colors.grey.shade700,
                    height: 1,
                  ),
                  const SizedBox(height: 6),
                  ...list.tasks
                      .where((t) => !t.isCompleted)
                      .take(4)
                      .map(_previewTask),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}


  Widget _gridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: lists.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemBuilder: (_, i) {
        final list = lists[i];
        return GestureDetector(
          onTap: () => _openList(list),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1c1c1b),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _editListName(list),
                  child: Text(
                    list.name.toUpperCase(),
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const Divider(),
                ...list.tasks
                    .where((t) => !t.isCompleted)
                    .take(4)
                    .map(_previewTask),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _previewTask(TodoTask task) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              setState(() {
                task.isCompleted = !task.isCompleted;
              });
            },
            child: Icon(
              task.isCompleted
                  ? Icons.check_box
                  : Icons.check_box_outline_blank,
              size: 18,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              task.title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          Visibility(
            visible: task.isStarred,
            maintainSize: true,
            maintainState: true,
            maintainAnimation: true,
            child: const Icon(
              Icons.star,
              size: 18,
              color: Colors.amber,
            ),
          ),
        ],
      ),
    );
  }

  void _addList() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New List'),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (c.text.isNotEmpty) {
                box.add(TodoList(name: c.text, tasks: []));
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editListName(TodoList list) {
    final c = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit List'),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              list.name = c.text;
              list.save();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _openList(TodoList list) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListDetailsPage(list: list),
      ),
    );
  }
}

class ListDetailsPage extends StatefulWidget {
  final TodoList list;
  const ListDetailsPage({super.key, required this.list});

  @override
  State<ListDetailsPage> createState() => _ListDetailsPageState();
}

class _ListDetailsPageState extends State<ListDetailsPage> {
  @override
  Widget build(BuildContext context) {
    final important =
        widget.list.tasks.where((t) => t.isStarred && !t.isCompleted).toList();
    final normal =
        widget.list.tasks.where((t) => !t.isStarred && !t.isCompleted).toList();
    final completed =
        widget.list.tasks.where((t) => t.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(title: Text(widget.list.name)),
      body: ListView(
        children: [
          if (important.isNotEmpty) _heading('IMPORTANT'),
          ...important.map(_taskTile),
          if (normal.isNotEmpty) _heading('TASKS'),
          ...normal.map(_taskTile),
          if (completed.isNotEmpty) _heading('COMPLETED'),
          ...completed.map(_taskTile),
          const SizedBox(height: 80),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onPressed: _deleteList,
          child: const Text(
            'DELETE LIST',
            style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _heading(String t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        t,
        style: const TextStyle(letterSpacing: 1.6, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _taskTile(TodoTask task) {
    return ListTile(
      leading: Checkbox(
        value: task.isCompleted,
        onChanged: (_) {
          setState(() {
            task.isCompleted = !task.isCompleted;
            widget.list.save();
          });
        },
      ),
      title: GestureDetector(
        onTap: () => _editTask(task),
        child: Text(
          task.title,
          style: TextStyle(
            decoration:
                task.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              task.isStarred ? Icons.star : Icons.star_border,
              color: task.isStarred ? Colors.amber : Colors.grey,
            ),
            onPressed: () {
              setState(() {
                task.isStarred = !task.isStarred;
                widget.list.save();
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                widget.list.tasks.remove(task);
                widget.list.save();
              });
            },
          ),
        ],
      ),
    );
  }

  void _editTask(TodoTask task) {
    final c = TextEditingController(text: task.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Task'),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              task.title = c.text;
              widget.list.save();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addTask() {
    final c = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(controller: c),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (c.text.isNotEmpty) {
                widget.list.tasks.add(TodoTask(title: c.text));
                widget.list.save();
                setState(() {});
                Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _deleteList() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete List'),
        content: const Text('This will permanently delete the list and all tasks.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              widget.list.delete();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class TodoListAdapter extends TypeAdapter<TodoList> {
  @override
  final int typeId = 0;

  @override
  TodoList read(BinaryReader reader) {
    return TodoList(
      name: reader.readString(),
      tasks: reader.readList().cast<TodoTask>(),
    );
  }

  @override
  void write(BinaryWriter writer, TodoList obj) {
    writer.writeString(obj.name);
    writer.writeList(obj.tasks);
  }
}

class TodoTaskAdapter extends TypeAdapter<TodoTask> {
  @override
  final int typeId = 1;

  @override
  TodoTask read(BinaryReader reader) {
    return TodoTask(
      title: reader.readString(),
      isCompleted: reader.readBool(),
      isStarred: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, TodoTask obj) {
    writer.writeString(obj.title);
    writer.writeBool(obj.isCompleted);
    writer.writeBool(obj.isStarred);
  }
}

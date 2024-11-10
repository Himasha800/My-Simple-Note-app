
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:note_app/screens/note_detail.dart';
import 'package:note_app/models/note.dart';
import 'package:note_app/utils/database_helper.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(const NoteApp());
}

class NoteApp extends StatefulWidget {
  const NoteApp({super.key});

  @override
  State<NoteApp> createState() => _NoteAppState();
}

class _NoteAppState extends State<NoteApp> {
  bool _isDarkMode = false; // Tracks if dark mode is on or off

  void _toggleTheme(bool isOn) {
    setState(() {
      _isDarkMode = isOn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Notes App',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 77, 72, 240),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(255, 60, 63, 65), // Dark mode AppBar color
        ),
      ),
      home: NoteList(
        isDarkMode: _isDarkMode,
        onToggleTheme: _toggleTheme,
      ),
    );
  }
}

class NoteList extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const NoteList({
    required this.isDarkMode,
    required this.onToggleTheme,
    super.key,
  });

  @override
  State<StatefulWidget> createState() {
    return NoteListState();
  }
}

class NoteListState extends State<NoteList> {
  DatabaseHelper databaseHelper = DatabaseHelper();
  late List<Note> noteList = [];
  int count = 0;
  bool _isGridView = false; // Tracks if in grid view mode

  @override
  Widget build(BuildContext context) {
    updateListview();

    // Set the AppBar title color based on dark or light mode
    Color titleColor = widget.isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'My Notes',
          style: TextStyle(color: titleColor), // Dynamic title color
        ),
        backgroundColor: widget.isDarkMode
            ? const Color.fromARGB(255, 125, 125, 130) // Dark mode color for AppBar
            : const Color.fromARGB(255, 77, 72, 240), // Light mode color for AppBar
        actions: [
          // Button to toggle between list and grid view
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView; // Toggle between grid and list
              });
            },
          ),
          // Dark mode toggle switch
          Switch(
            value: widget.isDarkMode,
            onChanged: widget.onToggleTheme,
            activeColor: Colors.white,
            inactiveThumbColor: Colors.grey,
          ),
        ],
      ),
      body: getNoteView(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          debugPrint('FAB clicked');
          navigateToDetail(Note('', '', 2), 'Add Note');
        },
        tooltip: 'Add Note',
        backgroundColor: widget.isDarkMode
            ? const Color.fromARGB(255, 128, 127, 131) // Match AppBar color in dark mode
            : const Color.fromARGB(255, 31, 6, 219), // Original color in light mode
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget getNoteView() {
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    TextStyle? titleStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: isDarkMode ? Colors.white : Colors.black87,
        );

    if (_isGridView) {
      // Grid view with 2 columns
      return GridView.builder(
        itemCount: count,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 4.0,
          crossAxisSpacing: 4.0,
        ),
        itemBuilder: (BuildContext context, int position) {
          return Card(
            color: isDarkMode
                ? const Color.fromARGB(255, 60, 63, 65)
                : const Color.fromARGB(255, 221, 240, 251),
            elevation: 2.0,
            
            child: GestureDetector(
              onTap: () {
                // Navigate to detail for editing when tapped
                navigateToDetail(noteList[position], 'Edit Note');
              },



            child: GridTile(
              header: Padding(
                padding: const EdgeInsets.all(4.0),
                child: CircleAvatar(
                  backgroundColor: getPriorityColor(noteList[position].priority),
                  child: getPriorityIcon(noteList[position].priority),
                ),
              ),
              footer: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  noteList[position].title,
                  style: titleStyle?.copyWith(
                    fontSize: 16.0, // Increase the font size
                    fontWeight: FontWeight.bold, // Make the title bold
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              child: Center(
                child: Text(
                  noteList[position].date,
                  style: TextStyle(
                    color: isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
            )
          );
        },
      );
    } else {
      // List view
      return ListView.builder(
        itemCount: count,
        itemBuilder: (BuildContext context, int position) {
          return Card(
            color: isDarkMode
                ? const Color.fromARGB(255, 60, 63, 65)
                : const Color.fromARGB(255, 221, 240, 251),
            elevation: 2.0,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: getPriorityColor(noteList[position].priority),
                child: getPriorityIcon(noteList[position].priority),
              ),
              title: Text(
                noteList[position].title,
                style: titleStyle?.copyWith(
                fontSize: 16.0, // Increase the font size
                fontWeight: FontWeight.bold, // Make the title bold
              ),
              ),
              subtitle: Text(
                noteList[position].date,
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              trailing: GestureDetector(
                child: const Icon(
                  Icons.delete,
                  color: Color.fromARGB(255, 120, 117, 117),
                ),
                onTap: () {
                  _delete(context, noteList[position]);
                },
              ),
              onTap: () {
                debugPrint("ListTile Tapped");
                navigateToDetail(noteList[position], 'Edit Note');
              },
            ),
          );
        },
      );
    }
  }

  Color getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return const Color.fromARGB(217, 251, 159, 169);
      case 2:
        return const Color.fromARGB(255, 245, 221, 7);
      default:
        return Colors.yellow;
    }
  }

  Icon getPriorityIcon(int priority) {
    switch (priority) {
      case 1:
        return const Icon(Icons.play_arrow);
      case 2:
        return const Icon(Icons.keyboard_arrow_right);
      default:
        return const Icon(Icons.keyboard_arrow_right);
    }
  }

  void _delete(BuildContext context, Note note) async {
    if (note.id != null) {
      int result = await databaseHelper.deleteNote(note.id!);
      if (result != 0) {
        _showSnackBar(context, 'Note Deleted Successfully');
        updateListview();
      }
    } else {
      _showSnackBar(context, 'Note ID is null. Deletion failed.');
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void navigateToDetail(Note note, String title) async {
    final bool? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) {
        return NoteDetail(note, title);
      }),
    );

    if (result != null && result) {
      updateListview();
    }
  }

  void updateListview() {
    final Future<Database> dbFuture = databaseHelper.initializeDatabase();
    dbFuture.then((database) {
      Future<List<Note>> noteListFuture = databaseHelper.getNoteList();
      noteListFuture.then((noteList) {
        setState(() {
          this.noteList = noteList;
          count = noteList.length;
        });
      });
    });
  }
}

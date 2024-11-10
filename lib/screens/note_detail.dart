
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:note_app/models/note.dart';
import 'package:note_app/utils/database_helper.dart';
import 'package:intl/intl.dart';

class NoteDetail extends StatefulWidget {
  final String appBarTitle;
  final Note note;

  const NoteDetail(this.note, this.appBarTitle, {super.key});

  @override
  State<StatefulWidget> createState() {
    return NoteDetailState(this.note, this.appBarTitle);
  }
}

class NoteDetailState extends State<NoteDetail> {
  static final _priorities = ['High', 'Low'];

  DatabaseHelper helper = DatabaseHelper();

  String appBarTitle;
  Note note;

  TextEditingController titleController = TextEditingController();
  TextEditingController descriptionController = TextEditingController();

  NoteDetailState(this.note, this.appBarTitle);

  @override
  Widget build(BuildContext context) {
    TextStyle? textStyle = Theme.of(context).textTheme.titleLarge;

    titleController.text = note.title;
    descriptionController.text = note.description ?? '';

    // Determine colors based on the current theme (light or dark mode)
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final Color appBarBackgroundColor = isDarkMode
        ? Colors.grey[800]!
        : const Color.fromARGB(255, 77, 72, 240);
    const Color appBarTitleColor = Colors.white;

    // Button background colors based on the theme
    final Color buttonBackgroundColor = isDarkMode
        ? Colors.grey[800]!
        : const Color.fromARGB(255, 5, 165, 240);
    const Color buttonTextColor = Colors.white;

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: () async {
        moveToLastScreen(false);
        return Future.value(false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            appBarTitle,
            style: const TextStyle(
              color: appBarTitleColor,
            ),
          ),
          backgroundColor: appBarBackgroundColor,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: appBarTitleColor,
            ),
            onPressed: () {
              moveToLastScreen(false);
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.only(top: 15.0, left: 10.0, right: 10.0),
          child: ListView(
            children: <Widget>[
              ListTile(
                title: DropdownButton(
                  items: _priorities.map((String dropDownStringItem) {
                    return DropdownMenuItem<String>(
                      value: dropDownStringItem,
                      child: Text(dropDownStringItem),
                    );
                  }).toList(),
                  style: textStyle,
                  value: getPriorityAsString(note.priority),
                  onChanged: (valueSelectedByUser) {
                    setState(() {
                      debugPrint('User selected $valueSelectedByUser');
                      updatePriorityAsInt(valueSelectedByUser!);
                    });
                  },
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: TextField(
                  controller: titleController,
                  style: textStyle,
                  onChanged: (value) {
                    debugPrint('Something changed in Title Text Field');
                    updateTitle();
                  },
                  decoration: InputDecoration(
                    labelText: 'Title',
                    labelStyle: textStyle,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                  ),
                ),
              ),
              // Description
                 Padding(
                   padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                   child: SingleChildScrollView(
                     child: TextField(
                     controller: descriptionController,
                     style: textStyle,
                     maxLines: null,  // Allows text to grow vertically
                     keyboardType: TextInputType.multiline,  // Enables multiline input
                     onChanged: (value) {
                       debugPrint('Something changed in Description Text Field');
                       updateDescription();
                      },
                      decoration: InputDecoration(
                        labelText: 'Description',
                        labelStyle: textStyle,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                    ),
                  ),
                ),

              // Save and Delete buttons
              Padding(
                padding: const EdgeInsets.only(top: 15.0, bottom: 15.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: buttonTextColor, // Text color
                          backgroundColor: buttonBackgroundColor, // Background color for Save button
                          textStyle: const TextStyle(fontSize: 18.0),
                        ),
                        child: const Text('Save'),
                        onPressed: () {
                          setState(() {
                            debugPrint("Save button clicked");
                            _save();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 5.0),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          foregroundColor: buttonTextColor, // Text color
                          backgroundColor: buttonBackgroundColor, // Background color for Delete button
                          textStyle: const TextStyle(fontSize: 18.0),
                        ),
                        child: const Text('Delete'),
                        onPressed: () {
                          setState(() {
                            debugPrint("Delete button clicked");
                            _delete();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void moveToLastScreen(bool result) {
    Navigator.pop(context, result);
  }

  void updatePriorityAsInt(String value) {
    switch (value) {
      case 'High':
        note.priority = 1;
        break;
      case 'Low':
        note.priority = 2;
        break;
    }
  }

  String getPriorityAsString(int value) {
    switch (value) {
      case 1:
        return _priorities[0];
      case 2:
        return _priorities[1];
      default:
        return _priorities[1];
    }
  }

  void updateTitle() {
    note.title = titleController.text;
  }

  void updateDescription() {
    note.description = descriptionController.text;
  }

  void _save() async {
    moveToLastScreen(true);

    note.date = DateFormat.yMMMd().format(DateTime.now());
    int result;
    if (note.id != null) {
      result = await helper.updateNote(note);
    } else {
      result = await helper.insertNote(note);
    }

    if (result != 0) {
      _showAlertDialog('Status', 'Note Saved Successfully');
    } else {
      _showAlertDialog('Status', 'Problem Saving Note');
    }
  }

  void _delete() async {
    moveToLastScreen(true);
    if (note.id == null) {
      _showAlertDialog('Status', 'The Note was deleted');
      return;
    }

    int result = await helper.deleteNote(note.id!);
    if (result != 0) {
      _showAlertDialog('Status', 'Note Deleted Successfully');
    } else {
      _showAlertDialog('Status', 'Error Occurred while Deleting Note');
    }
  }

  void _showAlertDialog(String title, String message) {
    AlertDialog alertDialog = AlertDialog(
      title: Text(title),
      content: Text(message),
    );
    showDialog(
      context: context,
      builder: (_) => alertDialog,
    );
  }
}

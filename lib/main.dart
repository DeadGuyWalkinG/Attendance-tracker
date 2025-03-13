import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(AttendanceManagerApp());
}

class AttendanceManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance Manager',
      theme: ThemeData(
        // **Primary Color Scheme (Indigo & Amber as Accent)**
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.indigo).copyWith(secondary: Colors.amberAccent),
        // accentColor is deprecated, using colorScheme.secondary instead
        scaffoldBackgroundColor: Colors.grey[100], // Light background, using scaffoldBackgroundColor
        fontFamily: 'Roboto',

        // **AppBar Theme**
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.indigo[700], // Darker shade of primary
          titleTextStyle: TextStyle(
            color: Colors.white, // White title text
            fontSize: 20.0,
            fontWeight: FontWeight.bold,
          ),
          centerTitle: true, // Keep title centered
          elevation: 2, // Subtle shadow
        ),

        // **Card Theme**
        cardTheme: CardTheme(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)), // Rounded corners
        ),

        // **ElevatedButton Theme**
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Colors.indigo),
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0))
            ),
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 20, vertical: 12)
            ),
            elevation: MaterialStateProperty.all<double>(2),
          ),
        ),

        // **TextButton Theme (for dialog actions)**
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Colors.indigo),
            padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                EdgeInsets.symmetric(horizontal: 16, vertical: 8)
            ),
          ),
        ),

        // **Dialog Theme**
        dialogTheme: DialogTheme(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
          elevation: 4,
        ),

        // **FloatingActionButton Theme**
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.amberAccent, // Accent FAB color
          foregroundColor: Colors.black87, // Text/icon color on FAB
          elevation: 3,
        ),

        // **IconButton Theme**
        iconTheme: IconThemeData(
          color: Colors.grey[700], // Default icon color
        ),

        // **Text Theme**
        textTheme: TextTheme(
          headlineSmall: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.black87), // Titles
          bodyMedium: TextStyle(fontSize: 16.0, color: Colors.black87), // Default body text
          titleMedium: TextStyle(fontSize: 18.0, fontStyle: FontStyle.italic, color: Colors.grey[600]), // Subtitles/hints, replacing subtitle1
        ),
      ),
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Box? subjectsBox;
  Box? settingsBox; // New settings box
  bool _isHiveInitialized = false;
  int _alertPercentageLimit = 75; // Default limit

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    try {
      subjectsBox = await Hive.openBox('subjectsBox');
      settingsBox = await Hive.openBox('settingsBox'); // Open settings box
      _loadSettings(); // Load settings after opening box
      setState(() {
        _isHiveInitialized = true;
      });
    } catch (e) {
      print("Error initializing Hive: $e");
    }
  }

  Future<void> _loadSettings() async {
    final limit = settingsBox!.get('alertLimit');
    if (limit != null) {
      setState(() {
        _alertPercentageLimit = limit as int;
      });
    } else {
      _saveSettings(); // Save default if not found
    }
  }

  Future<void> _saveSettings() async {
    await settingsBox!.put('alertLimit', _alertPercentageLimit);
  }

  void _addSubject(String subjectName, int attendedClasses, int totalClasses) {
    if (!_isHiveInitialized ||
        subjectsBox == null ||
        subjectName.trim().isEmpty) return;
    subjectsBox!
        .put(subjectName, {'attended': attendedClasses, 'total': totalClasses});
    setState(() {});
  }

  void _removeSubject(String subjectName) {
    if (!_isHiveInitialized || subjectsBox == null) return;
    subjectsBox!.delete(subjectName);
    setState(() {});
  }

  void _markAttendance(String subjectName, bool present) {
    if (!_isHiveInitialized || subjectsBox == null) return;
    final subject = subjectsBox!.get(subjectName);
    if (subject is Map) {
      subject['total'] = (subject['total'] as num).toInt() + 1;
      if (present)
        subject['attended'] = (subject['attended'] as num).toInt() + 1;
      subjectsBox!.put(subjectName, subject);
      setState(() {});
    }
  }

  void _updateSubjectClasses(
      String subjectName, int attendedClasses, int totalClasses) {
    if (!_isHiveInitialized || subjectsBox == null) return;
    if (attendedClasses > totalClasses) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
            Text('Attended classes cannot be greater than total classes.')),
      );
      return;
    }
    final subject = subjectsBox!.get(subjectName);
    if (subject is Map) {
      subject['attended'] = attendedClasses;
      subject['total'] = totalClasses;
      subjectsBox!.put(subjectName, subject);
      setState(() {});
    }
  }

  double _calculateAttendancePercentage() {
    if (!_isHiveInitialized || subjectsBox == null || subjectsBox!.isEmpty)
      return 0.0;
    int totalClasses = 0, totalAttended = 0;
    for (var key in subjectsBox!.keys) {
      var subject = subjectsBox!.get(key);
      if (subject is Map) {
        totalClasses += (subject['total'] as num).toInt();
        totalAttended += (subject['attended'] as num).toInt();
      }
    }
    return totalClasses == 0 ? 0.0 : (totalAttended / totalClasses) * 100;
  }

  void _showMarkAttendanceDialog(BuildContext context, String subjectName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Mark Attendance for $subjectName'),
        actions: [
          TextButton(
            onPressed: () {
              _markAttendance(subjectName, false);
              Navigator.of(ctx).pop();
            },
            child: Text('Absent'),
          ),
          ElevatedButton(
            onPressed: () {
              _markAttendance(subjectName, true);
              Navigator.of(ctx).pop();
            },
            child: Text('Present'),
          ),
        ],
      ),
    );
  }

  void _showLimitPercentageDialog(BuildContext context) {
    int tempLimit = _alertPercentageLimit; // Use temp variable for dialog limit

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Change Alert Limit'),
        content: StatefulBuilder(
          // StatefulBuilder to update dialog content
          builder: (BuildContext context, StateSetter dialogSetState) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.remove),
                  onPressed: () {
                    if (tempLimit > 0) {
                      dialogSetState(() {
                        // Update dialog-local state
                        tempLimit -= 5;
                      });
                    }
                  },
                ),
                Text('${tempLimit}%', style: TextStyle(fontSize: 18)),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () {
                    if (tempLimit < 95) {
                      dialogSetState(() {
                        // Update dialog-local state
                        tempLimit += 5;
                      });
                    }
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                // Update DashboardPage state with the temporary limit
                _alertPercentageLimit = tempLimit;
              });
              _saveSettings(); // Save the updated limit
              Navigator.of(ctx).pop();
            },
            child: Text('Set Limit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isHiveInitialized) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final double attendancePercentage = _calculateAttendancePercentage();

    return Scaffold(
      appBar: AppBar(title: Text('Attendance Manager')),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Apply background color from theme - Corrected property name
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 5,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              color: attendancePercentage < _alertPercentageLimit &&
                  attendancePercentage > 0
                  ? Colors.redAccent
                  : Colors.green,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Overall Attendance',
                        style: TextStyle(fontSize: 18, color: Colors.white)),
                    SizedBox(height: 8),
                    Text('${attendancePercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    if (attendancePercentage < _alertPercentageLimit &&
                        attendancePercentage > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '⚠️ Attendance is below ${_alertPercentageLimit}%! Attend more classes.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: subjectsBox!.isEmpty
                  ? Center(
                child: Text(
                  'No subjects added yet! Use the "+" button to add subjects.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              )
                  : ListView.builder(
                itemCount: subjectsBox!.length,
                itemBuilder: (context, index) {
                  final subjectName = subjectsBox!.keyAt(index);
                  final subject = subjectsBox!.get(subjectName) as Map;
                  double attendance = 0.0;
                  if (subject is Map) {
                    attendance = subject['total'] == 0
                        ? 0.0
                        : (subject['attended'] / subject['total']) * 100;
                  }

                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(subjectName,
                              style: Theme.of(context).textTheme.headlineSmall), // Use headlineSmall from theme - Corrected property name
                          SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: attendance / 100,
                              backgroundColor: Colors.grey.shade300,
                              color: attendance < _alertPercentageLimit &&
                                  attendance > 0
                                  ? Colors.redAccent
                                  : Colors.green,
                              minHeight: 12,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Attendance: ${subject['attended']}/${subject['total']} (${attendance.toStringAsFixed(1)}%)',
                            style: Theme.of(context).textTheme.bodyMedium, // Use bodyMedium from theme - Corrected property name
                          ),
                          if (attendance < _alertPercentageLimit &&
                              subject['total'] > 0)
                            Text(
                              '⚠️ Below ${_alertPercentageLimit}%! Attend more.',
                              style: TextStyle(color: Colors.red),
                            ),
                          Row(
                            // Row containing ExpansionTile and Edit/Delete Icons
                            mainAxisAlignment: MainAxisAlignment
                                .start, // <---- Changed to start alignment
                            crossAxisAlignment: CrossAxisAlignment
                                .center, // Align items vertically in the center
                            children: [
                              IconButton(
                                // Dropdown Arrow Button - Replaces ExpansionTile's arrow
                                icon: Icon(Icons.expand_more),
                                padding: EdgeInsets
                                    .zero, // Remove default padding
                                constraints:
                                BoxConstraints(), // Remove default constraints
                                onPressed: () {
                                  // Find the ExpansionTile in the widget tree and toggle its expansion
                                  _toggleExpansion(context, subjectName);
                                },
                              ),
                              IconButton(
                                // Edit Icon
                                icon:
                                Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showMarkAttendanceDialog(
                                        context, subjectName),
                              ),
                              IconButton(
                                // Delete Icon
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _removeSubject(subjectName),
                              ),
                            ],
                          ),
                          _buildExpansionContent(subjectName,
                              subject), // Render expansion content conditionally
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              FloatingActionButton(
                heroTag: "limitButton",
                onPressed: () => _showLimitPercentageDialog(context),
                child: Icon(Icons.settings),
                tooltip: 'Change Alert Limit',
                mini: true,
              ),
              FloatingActionButton(
                heroTag: "addButton",
                onPressed: () {
                  TextEditingController _subjectController =
                  TextEditingController();
                  TextEditingController _attendedClassesController =
                  TextEditingController();
                  TextEditingController _totalClassesController =
                  TextEditingController();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Add Subject'),
                      content: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextField(
                              controller: _subjectController,
                              decoration: InputDecoration(
                                  labelText: 'Subject Name', // More descriptive label
                                  hintText: 'Enter subject name',
                                  border: OutlineInputBorder()), // Added border
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: _attendedClassesController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: 'Attended Classes', // More descriptive label
                                  hintText: 'Already attended classes',
                                  border: OutlineInputBorder()), // Added border
                            ),
                            SizedBox(height: 10),
                            TextField(
                              controller: _totalClassesController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                  labelText: 'Total Classes', // More descriptive label
                                  hintText: 'Total no. of classes',
                                  border: OutlineInputBorder()), // Added border
                            ),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            String subjectName = _subjectController.text.trim();
                            String attendedClassesStr =
                            _attendedClassesController.text.trim();
                            String totalClassesStr =
                            _totalClassesController.text.trim();

                            if (subjectName.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Subject name cannot be empty.')),
                              );
                              return;
                            }

                            int? attendedClasses =
                            int.tryParse(attendedClassesStr);
                            int? totalClasses = int.tryParse(totalClassesStr);

                            if (attendedClasses == null ||
                                totalClasses == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Please enter valid integer values for attended and total classes.')),
                              );
                              return;
                            }
                            if (attendedClasses > totalClasses) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        'Attended classes cannot be greater than total classes.')),
                              );
                              return;
                            }

                            _addSubject(
                                subjectName, attendedClasses, totalClasses);
                            Navigator.of(ctx).pop();
                          },
                          child: Text('Add'),
                        ),
                      ],
                    ),
                  );
                },
                child: Icon(Icons.add),
                mini: true,
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: null,
    );
  }

  // --- New functions to handle ExpansionTile functionality ---

  Map<String, bool> _expansionStates =
  {}; // Track expansion state for each subject

  void _toggleExpansion(BuildContext context, String subjectName) {
    setState(() {
      _expansionStates[subjectName] = !(_expansionStates[subjectName] ?? false);
    });
  }

  Widget _buildExpansionContent(String subjectName, Map subject) {
    if (_expansionStates[subjectName] ?? false) {
      return Padding(
        // Added padding for visual separation
        padding: const EdgeInsets.only(top: 10.0),
        child: Row(
          children: [
            Text("Attended: "),
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                int attended = subject['attended'] as int;
                if (attended > 0) {
                  _updateSubjectClasses(
                      subjectName, attended - 1, subject['total'] as int);
                }
              },
            ),
            Text('${subject['attended']}'),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                int attended = subject['attended'] as int;
                int total = subject['total'] as int;
                if (attended < total) {
                  _updateSubjectClasses(subjectName, attended + 1, total);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Attended classes cannot be greater than total classes.')),
                  );
                }
              },
            ),
            Spacer(),
            Text("Total: "),
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                int total = subject['total'] as int;
                int attended = subject['attended'] as int;
                if (total > 0 && total > attended) {
                  _updateSubjectClasses(subjectName, attended, total - 1);
                }
              },
            ),
            Text('${subject['total']}'),
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                int total = subject['total'] as int;
                _updateSubjectClasses(
                    subjectName, subject['attended'] as int, total + 1);
              },
            ),
          ],
        ),
      );
    } else {
      return Container(); // Return empty container when not expanded
    }
  }
}
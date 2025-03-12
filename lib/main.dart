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
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
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

  @override
  void initState() {
    super.initState();
    _initializeHive();
  }

  Future<void> _initializeHive() async {
    subjectsBox = await Hive.openBox('subjectsBox');
    setState(() {});
  }

  void _addSubject(String subjectName) {
    if (subjectsBox == null || subjectName.trim().isEmpty) return;
    subjectsBox!.put(subjectName, {'attended': 0, 'total': 0});
    setState(() {});
  }

  void _removeSubject(String subjectName) {
    if (subjectsBox == null) return;
    subjectsBox!.delete(subjectName);
    setState(() {});
  }

  void _markAttendance(String subjectName, bool present) {
    if (subjectsBox == null) return;
    final subject = subjectsBox!.get(subjectName);
    subject['total'] = (subject['total'] as num).toInt() + 1;
    if (present) subject['attended'] = (subject['attended'] as num).toInt() + 1;
    subjectsBox!.put(subjectName, subject);
    setState(() {});
  }

  double _calculateAttendancePercentage() {
    if (subjectsBox == null || subjectsBox!.isEmpty) return 0.0;
    int totalClasses = 0, totalAttended = 0;
    for (var key in subjectsBox!.keys) {
      var subject = subjectsBox!.get(key);
      totalClasses += (subject['total'] as num).toInt();
      totalAttended += (subject['attended'] as num).toInt();
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


  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Hive.openBox('subjectsBox'),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        subjectsBox = snapshot.data as Box;
        final double attendancePercentage = _calculateAttendancePercentage();

        return Scaffold(
          appBar: AppBar(title: Text('Attendance Manager'), centerTitle: true),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 5,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  color: attendancePercentage < 75 && attendancePercentage > 0 ? Colors.redAccent : Colors.green,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Overall Attendance', style: TextStyle(fontSize: 18, color: Colors.white)),
                        SizedBox(height: 8),
                        Text('${attendancePercentage.toStringAsFixed(1)}%',
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                        if (attendancePercentage < 75 && attendancePercentage > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text('⚠️ Attendance is below 75%! Attend more classes.',
                                style: TextStyle(color: Colors.white)),
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
                            final subject = subjectsBox!.get(subjectName);
                            final attendance = subject['total'] == 0
                                ? 0.0
                                : (subject['attended'] / subject['total']) * 100;
                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 8),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(subjectName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                    SizedBox(height: 8),
                                    LinearProgressIndicator(
                                      value: attendance / 100,
                                      backgroundColor: Colors.grey.shade300,
                                      color: attendance < 75 && attendance > 0 ? Colors.redAccent : Colors.green,
                                      minHeight: 10,
                                    ),
                                    SizedBox(height: 8),
                                    Text('Attendance: ${subject['attended']}/${subject['total']} (${attendance.toStringAsFixed(1)}%)'),
                                    if (attendance < 75 && subject['total'] > 0)
                                      Text('⚠️ Below 75%! Attend more.', style: TextStyle(color: Colors.red)),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit, color: Colors.blue),
                                          onPressed: () => _showMarkAttendanceDialog(context, subjectName),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeSubject(subjectName),
                                        ),
                                      ],
                                    ),
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
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              TextEditingController _subjectController = TextEditingController();
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text('Add Subject'),
                  content: TextField(controller: _subjectController, decoration: InputDecoration(hintText: 'Enter subject name')),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel')),
                    ElevatedButton(
                      onPressed: () {
                        if (_subjectController.text.isNotEmpty) _addSubject(_subjectController.text.trim());
                        Navigator.of(ctx).pop();
                      },
                      child: Text('Add'),
                    ),
                  ],
                ),
              );
            },
            child: Icon(Icons.add),
          ),
        );
      },
    );
  }
}

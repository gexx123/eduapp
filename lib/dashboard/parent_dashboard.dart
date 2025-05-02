import 'package:flutter/material.dart';

class ParentDashboard extends StatelessWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    // For now, use mock data. Replace with Firestore queries for real data.
    final studentInfo = {
      'schoolCode': 'EGERGG',
      'studentName': 'Alex Smith',
      'rollNumber': '8A15',
      'class': '8A',
      'classTeacher': 'Ms. Johnson',
    };
    final attendance = {
      'present': 115,
      'total': 120,
      'absent': 5,
      'percentage': 95.8,
    };
    final performance = {
      'grade': 'A',
      'average': 41.3,
      'highestSubject': 'Mathematics',
      'highestMarks': 45,
      'lowestSubject': 'English',
      'lowestMarks': 38,
    };
    final marks = [
      {'subject': 'Mathematics', 'assessment': 'FA1', 'marks': 45, 'grade': 'A'},
      {'subject': 'Science', 'assessment': 'FA1', 'marks': 42, 'grade': 'A'},
      {'subject': 'English', 'assessment': 'FA1', 'marks': 38, 'grade': 'B'},
      {'subject': 'Social Studies', 'assessment': 'FA1', 'marks': 40, 'grade': 'A'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Parent Dashboard'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      backgroundColor: Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 6),
            Text(
              "View your child's academic progress",
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            SizedBox(height: 18),
            // Student Info
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.account_circle, size: 38, color: Colors.blue.shade700),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Student Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Text('School Code: ', style: TextStyle(color: Colors.black54)),
                              Text(studentInfo['schoolCode'].toString()),
                              SizedBox(width: 18),
                              Text('Class: ', style: TextStyle(color: Colors.black54)),
                              Text(studentInfo['class'].toString()),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.visibility, size: 16, color: Colors.blueGrey),
                              SizedBox(width: 4),
                              Text('Student Name: ', style: TextStyle(color: Colors.black54)),
                              Text(studentInfo['studentName'].toString()),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Text('Roll Number: ', style: TextStyle(color: Colors.black54)),
                              Text(studentInfo['rollNumber'].toString()),
                              SizedBox(width: 18),
                              Text('Class Teacher: ', style: TextStyle(color: Colors.black54)),
                              Text(studentInfo['classTeacher'].toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 14),
            // Attendance & Performance Row
            Row(
              children: [
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.event_available, color: Colors.blue),
                              SizedBox(width: 8),
                              Text('Attendance Summary', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text('Present Days   ${attendance['present']} / ${attendance['total']}', style: TextStyle(fontSize: 15)),
                          Text('Absent Days    ${attendance['absent']}', style: TextStyle(fontSize: 15)),
                          Text('Attendance Percentage', style: TextStyle(color: Colors.black54)),
                          SizedBox(height: 5),
                          LinearProgressIndicator(
                            value: (attendance['percentage'] as double) / 100.0,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.blue,
                          ),
                          SizedBox(height: 5),
                          Text('${attendance['percentage']}%', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.show_chart, color: Colors.indigo),
                              SizedBox(width: 8),
                              Text('Academic Performance', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Overall Grade', style: TextStyle(color: Colors.black54)),
                                  Text(performance['grade'].toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Average Marks', style: TextStyle(color: Colors.black54)),
                                  Text('${performance['average']} / 50', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text('Highest in Subject: ${performance['highestSubject'].toString()} (${performance['highestMarks']}/50)', style: TextStyle(color: Colors.green)),
                          Text('Needs Improvement: ${performance['lowestSubject'].toString()} (${performance['lowestMarks']}/50)', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            // Tabs
            DefaultTabController(
              length: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TabBar(
                    labelColor: Colors.blue,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: Colors.blue,
                    tabs: [
                      Tab(text: 'Academic Marks'),
                      Tab(text: 'Detailed Attendance'),
                      Tab(text: 'Announcements'),
                    ],
                  ),
                  SizedBox(
                    height: 300,
                    child: TabBarView(
                      children: [
                        // Academic Marks Tab
                        Card(
                          margin: EdgeInsets.only(top: 14),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Academic Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 8),
                                Text("View your child's marks across different subjects", style: TextStyle(color: Colors.black54)),
                                SizedBox(height: 14),
                                Table(
                                  border: TableBorder.all(color: Colors.grey.shade200),
                                  columnWidths: {
                                    0: FlexColumnWidth(2),
                                    1: FlexColumnWidth(2),
                                    2: FlexColumnWidth(2),
                                    3: FlexColumnWidth(1),
                                  },
                                  children: [
                                    TableRow(
                                      decoration: BoxDecoration(color: Colors.grey.shade100),
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Assessment', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Marks', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                    ...marks.map((m) => TableRow(
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(m['subject'].toString()),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(m['assessment'].toString()),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text('${m['marks']} / 50'),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.all(8.0),
                                          child: Text(m['grade'].toString(), style: TextStyle(color: m['grade'] == 'A' ? Colors.green : Colors.orange)),
                                        ),
                                      ],
                                    )).toList(),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Detailed Attendance Tab
                        Card(
                          margin: EdgeInsets.only(top: 14),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Detailed Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 8),
                                Text('Feature coming soon!', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                        ),
                        // Announcements Tab
                        Card(
                          margin: EdgeInsets.only(top: 14),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Announcements', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                SizedBox(height: 8),
                                Text('No announcements yet.', style: TextStyle(color: Colors.black54)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

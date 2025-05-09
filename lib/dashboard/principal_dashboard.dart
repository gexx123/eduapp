import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import '../models/class.dart';
import '../class_management/view_marks_report_page.dart'; // Correct import path

class PrincipalDashboardPage extends StatefulWidget {
  final String schoolName;
  final String schoolCode;
  const PrincipalDashboardPage({super.key, required this.schoolName, required this.schoolCode});

  @override
  State<PrincipalDashboardPage> createState() => _PrincipalDashboardPageState();
}

class _PrincipalDashboardPageState extends State<PrincipalDashboardPage> {
  bool showSuccessBanner = true;
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 700;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 36, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.school, color: Color(0xFF5B8DEE), size: 32),
                  SizedBox(width: 10),
                  Text(widget.schoolName.isEmpty ? 'School Name' : widget.schoolName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 18 : 22)),
                  SizedBox(width: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(0xFFF4F4FD),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Text('School Code: ', style: TextStyle(fontSize: isMobile ? 11 : 13, color: Colors.black54)),
                        SelectableText(widget.schoolCode, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 11 : 13, color: Color(0xFF5B8DEE))),
                        SizedBox(width: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () async {
                            await Clipboard.setData(ClipboardData(text: widget.schoolCode));
                            setState(() { showSuccessBanner = false; });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('School code copied!')),
                            );
                          },
                          child: Icon(Icons.copy, size: 14, color: Colors.black38),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(Icons.menu, size: 28, color: Colors.black87),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.account_circle, color: Colors.blueGrey, size: 28),
                    onSelected: (value) async {
                      if (value == 'profile') {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Profile'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('User Name:'),
                                SizedBox(height: 4),
                                Text('Principal', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 12),
                                Text('School:'),
                                SizedBox(height: 4),
                                Text(widget.schoolName, style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(height: 12),
                                Text('School Code:'),
                                SizedBox(height: 4),
                                Text(widget.schoolCode, style: TextStyle(fontWeight: FontWeight.bold)),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Close'),
                              ),
                            ],
                          ),
                        );
                      } else if (value == 'logout') {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Log Out'),
                            content: Text('Are you sure you want to log out?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await Future.delayed(Duration(milliseconds: 100));
                                  try {
                                    await FirebaseAuth.instance.signOut();
                                  } catch (_) {}
                                  Navigator.of(context).pushNamedAndRemoveUntil('/landing', (route) => false);
                                },
                                child: Text('Log Out', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'profile',
                        child: Row(
                          children: [
                            Icon(Icons.person, color: Colors.blueGrey, size: 20),
                            SizedBox(width: 8),
                            Text('Profile'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.redAccent, size: 20),
                            SizedBox(width: 8),
                            Text('Log Out'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 28, vertical: isMobile ? 14 : 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Banner
              if (showSuccessBanner)
                Container(
                  margin: EdgeInsets.only(bottom: isMobile ? 10 : 18),
                  padding: EdgeInsets.all(isMobile ? 10 : 18),
                  decoration: BoxDecoration(
                    color: Color(0xFFE8F9ED),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color(0xFFB7EACD)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.verified_user, color: Color(0xFF38B36A)),
                      SizedBox(width: 10),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(color: Color(0xFF38B36A), fontSize: isMobile ? 13 : 15),
                            children: [
                              TextSpan(text: 'School Created Successfully!\n', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(
                                text: 'Share this code with teachers and parents: ',
                                style: TextStyle(fontWeight: FontWeight.normal, color: Colors.black87),
                              ),
                              TextSpan(
                                text: widget.schoolCode,
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF38B36A)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Stats Row
              Wrap(
                spacing: isMobile ? 8 : 20,
                runSpacing: isMobile ? 8 : 20,
                children: [
                  _teacherCountCard(isMobile),
                  SizedBox(
                    width: isMobile ? double.infinity : 200,
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 18, horizontal: isMobile ? 12 : 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: StreamBuilder<int>(
                        stream: FirestoreService().getTotalStudentCountForSchool(widget.schoolCode),
                        builder: (context, snapshot) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.person, color: Color(0xFF5B8DEE)),
                                  SizedBox(width: 10),
                                  Text('Students', style: TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                snapshot.hasData ? '${snapshot.data}' : '...',
                                style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  _statCard('Pending Tasks', '5', Icons.assignment, Color(0xFF5B8DEE), isMobile),
                  _statCard('Completed Tasks', '12', Icons.assignment_turned_in, Color(0xFF5B8DEE), isMobile),
                ],
              ),
              SizedBox(height: isMobile ? 16 : 28),
              // Custom Tabs
              _customTabBar(isMobile),
              SizedBox(height: 10),
              Builder(
                builder: (context) {
                  if (tabIndex == 0) {
                    return _classesTab(isMobile);
                  } else if (tabIndex == 1) {
                    return _tasksTab(isMobile);
                  } else {
                    return _reportsTab(isMobile);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _customTabBar(bool isMobile) {
    final tabs = ['Classes', 'Tasks', 'Reports'];
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFFF4F4FD),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 8, vertical: 6),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = tabIndex == i;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => setState(() => tabIndex = i),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: isMobile ? 12 : 22),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: selected
                      ? Border.all(color: Color(0xFFBBAAFE), width: 2)
                      : Border.all(color: Colors.transparent, width: 2),
                  boxShadow: selected
                      ? [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0, 2))]
                      : [],
                ),
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: selected ? Colors.black : Colors.black54,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    fontSize: isMobile ? 14 : 16,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, bool isMobile) {
    return Container(
      width: isMobile ? double.infinity : 200,
      padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 18, horizontal: isMobile ? 12 : 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      margin: EdgeInsets.only(bottom: isMobile ? 8 : 0),
      child: Row(
        children: [
          Icon(icon, color: color, size: isMobile ? 22 : 28),
          SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: isMobile ? 12 : 14, color: Colors.black54)),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 22)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _teacherCountCard(bool isMobile) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService().teacherCountStream(widget.schoolCode),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _statCard('Teachers', '...', Icons.groups, Color(0xFF5B8DEE), isMobile);
        }
        if (snapshot.hasError) {
          return _statCard('Teachers', 'Err', Icons.groups, Color(0xFF5B8DEE), isMobile);
        }
        final count = snapshot.data?.docs.length ?? 0;
        return _statCard('Teachers', count.toString(), Icons.groups, Color(0xFF5B8DEE), isMobile);
      },
    );
  }

  Widget _classesTab(bool isMobile) {
    return StreamBuilder<List<SchoolClass>>(
      stream: FirestoreService().getClassesForSchool(widget.schoolCode),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final classes = snapshot.data!;
        if (classes.isEmpty) {
          return Center(child: Text('No classes found.'));
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: classes.length,
          separatorBuilder: (_, __) => Divider(),
          itemBuilder: (context, idx) {
            final c = classes[idx];
            final classId = '${c.className}_${c.section}';
            return ListTile(
              title: Text('Class ${c.className}${c.section}'),
              subtitle: Row(
                children: [
                  StreamBuilder<int>(
                    stream: FirestoreService().getStudentCountForClass(widget.schoolCode, classId),
                    builder: (context, snap) => Text(
                      snap.hasData ? '${snap.data} students' : '...',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Class Teacher: ' + (c.classTeacherName != null && c.classTeacherName!.trim().isNotEmpty
                      ? c.classTeacherName!
                      : 'Unassigned')),
                ],
              ),
              trailing: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: Color(0xFF5B8DEE).withOpacity(0.1),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: Color(0xFF5B8DEE).withOpacity(0.3)),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ViewMarksReportPage(
                        schoolCode: widget.schoolCode,
                        classId: classId,
                        className: c.className,
                        section: c.section,
                        exam: null,
                      ),
                    ),
                  );
                },
                icon: Icon(Icons.visibility_outlined, size: 18, color: Color(0xFF5B8DEE)),
                label: Text(
                  'View Report',
                  style: TextStyle(
                    color: Color(0xFF5B8DEE),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _tasksTab(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(isMobile ? 10 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Task Management', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 20)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFBBAAFE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: TextStyle(fontWeight: FontWeight.bold),
                  elevation: 0,
                ),
                onPressed: () {},
                child: Text('Create New Task'),
              ),
            ],
          ),
          SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: isMobile ? 26 : 48,
              horizontalMargin: 0,
              columns: [
                DataColumn(label: Text('Task', style: TextStyle(fontWeight: FontWeight.w500))),
                DataColumn(label: Text('Assigned To', style: TextStyle(fontWeight: FontWeight.w500))),
                DataColumn(label: Text('Due Date', style: TextStyle(fontWeight: FontWeight.w500))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w500))),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text('Submit Term Reports')),
                  DataCell(Text('All Teachers')),
                  DataCell(Text('2025-05-01')),
                  DataCell(Text('Pending')),
                ]),
              ],
              dataRowMinHeight: isMobile ? 38 : 48,
              dataRowMaxHeight: isMobile ? 48 : 60,
              headingRowHeight: isMobile ? 32 : 40,
              dividerThickness: 0.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportsTab(bool isMobile) {
    return Container(
      margin: EdgeInsets.only(top: 12),
      padding: EdgeInsets.all(isMobile ? 10 : 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Academic Reports', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 16 : 20)),
          SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: isMobile ? 26 : 48,
              horizontalMargin: 0,
              columns: [
                DataColumn(label: Text('Report', style: TextStyle(fontWeight: FontWeight.w500))),
                DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.w500))),
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.w500))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w500))),
              ],
              rows: [
                DataRow(cells: [
                  DataCell(Text('Term 1 Results')),
                  DataCell(Text('10A')),
                  DataCell(Text('2025-04-15')),
                  DataCell(ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF5B8DEE),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      elevation: 0,
                    ),
                    onPressed: () {},
                    child: Text('View Details'),
                  )),
                ]),
              ],
              dataRowMinHeight: isMobile ? 38 : 48,
              dataRowMaxHeight: isMobile ? 48 : 60,
              headingRowHeight: isMobile ? 32 : 40,
              dividerThickness: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

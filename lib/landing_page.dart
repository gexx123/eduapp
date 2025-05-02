import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'auth/signup_page.dart';

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 800;
    final isTablet = width >= 800 && width < 1200;
    final horizontalPad = isMobile ? 12.0 : isTablet ? 36.0 : 80.0;
    final sectionSpacing = isMobile ? 32.0 : 48.0;
    final cardSpacing = isMobile ? 14.0 : 24.0;
    final cardPad = isMobile ? 16.0 : 28.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FC),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isMobile ? 20 : 40,
            horizontal: horizontalPad,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Section
              isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildLeftTop(context, isMobile, cardPad),
                        SizedBox(height: cardSpacing),
                        _buildRightTop(isMobile),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: _buildLeftTop(context, isMobile, cardPad),
                        ),
                        SizedBox(width: cardSpacing * 2),
                        Expanded(
                          flex: 7,
                          child: _buildRightTop(isMobile),
                        ),
                      ],
                    ),
              SizedBox(height: sectionSpacing),
              // Key Features
              Text(
                'Key Features',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: cardSpacing),
              isMobile
                  ? Column(
                      children: [
                        _featureCard(
                          icon: Icons.school,
                          title: 'For Principals',
                          desc:
                              'Manage school operations, assign tasks to teachers, generate question papers, and view comprehensive reports.',
                          color: Color(0xFF5B8DEE),
                          isMobile: isMobile,
                          cardPad: cardPad,
                        ),
                        SizedBox(height: cardSpacing),
                        _featureCard(
                          icon: Icons.person,
                          title: 'For Teachers',
                          desc:
                              'View assigned tasks, manage classes, upload student marks, and generate academic reports.',
                          color: Color(0xFFFFA726),
                          isMobile: isMobile,
                          cardPad: cardPad,
                        ),
                        SizedBox(height: cardSpacing),
                        _featureCard(
                          icon: Icons.family_restroom,
                          title: 'For Parents',
                          desc:
                              'Monitor your child\'s academic performance, attendance, and stay updated with school announcements.',
                          color: Color(0xFFAA5BDE),
                          isMobile: isMobile,
                          cardPad: cardPad,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _featureCard(
                            icon: Icons.school,
                            title: 'For Principals',
                            desc:
                                'Manage school operations, assign tasks to teachers, generate question papers, and view comprehensive reports.',
                            color: Color(0xFF5B8DEE),
                            isMobile: isMobile,
                            cardPad: cardPad,
                          ),
                        ),
                        SizedBox(width: cardSpacing),
                        Expanded(
                          child: _featureCard(
                            icon: Icons.person,
                            title: 'For Teachers',
                            desc:
                                'View assigned tasks, manage classes, upload student marks, and generate academic reports.',
                            color: Color(0xFFFFA726),
                            isMobile: isMobile,
                            cardPad: cardPad,
                          ),
                        ),
                        SizedBox(width: cardSpacing),
                        Expanded(
                          child: _featureCard(
                            icon: Icons.family_restroom,
                            title: 'For Parents',
                            desc:
                                'Monitor your child\'s academic performance, attendance, and stay updated with school announcements.',
                            color: Color(0xFFAA5BDE),
                            isMobile: isMobile,
                            cardPad: cardPad,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: sectionSpacing),
              // Advanced Capabilities
              Text(
                'Advanced Capabilities',
                style: TextStyle(
                  fontSize: isMobile ? 22 : 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: cardSpacing),
              isMobile
                  ? Column(
                      children: [
                        _featureCard(
                          icon: Icons.auto_awesome,
                          title: 'AI-Powered Question Papers',
                          desc:
                              'Generate comprehensive question papers with AI-assisted technology, filter by difficulty and topics.',
                          color: Color(0xFF8A6DFE),
                          isMobile: isMobile,
                          cardPad: cardPad,
                        ),
                        SizedBox(height: cardSpacing),
                        _featureCard(
                          icon: Icons.bar_chart,
                          title: 'Comprehensive Reports',
                          desc:
                              'Access detailed academic reports with visualization to track progress over time.',
                          color: Color(0xFF5B8DEE),
                          isMobile: isMobile,
                          cardPad: cardPad,
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _featureCard(
                            icon: Icons.auto_awesome,
                            title: 'AI-Powered Question Papers',
                            desc:
                                'Generate comprehensive question papers with AI-assisted technology, filter by difficulty and topics.',
                            color: Color(0xFF8A6DFE),
                            isMobile: isMobile,
                            cardPad: cardPad,
                          ),
                        ),
                        SizedBox(width: cardSpacing),
                        Expanded(
                          child: _featureCard(
                            icon: Icons.bar_chart,
                            title: 'Comprehensive Reports',
                            desc:
                                'Access detailed academic reports with visualization to track progress over time.',
                            color: Color(0xFF5B8DEE),
                            isMobile: isMobile,
                            cardPad: cardPad,
                          ),
                        ),
                      ],
                    ),
              SizedBox(height: sectionSpacing),
              // Call to Action
              Text(
                'Ready to transform your educational institution?',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10),
              Text(
                'Join EduLink today and experience a modern approach to school management, collaboration, and student success.',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8A6DFE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 24 : 40,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupPage()),
                    );
                  },
                  child: const Text('Create Your Account'),
                ),
              ),
              SizedBox(height: sectionSpacing),
              // Footer
              Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EduLink',
                          style: TextStyle(
                            color: Color(0xFF8A6DFE),
                            fontWeight: FontWeight.bold,
                            fontSize: isMobile ? 14 : 16,
                          ),
                        ),
                        Text(
                          'Smart Educational Platform',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 14,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '\u00a9 2025 EduLink. All rights reserved.',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: Colors.black45,
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

  Widget _buildLeftTop(BuildContext context, bool isMobile, double cardPad) {
    return Padding(
      padding: EdgeInsets.only(left: isMobile ? 0 : 18, right: isMobile ? 0 : 12, top: 8, bottom: 8),
      child: Column(
        crossAxisAlignment:
            isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            'EduLink',
            style: TextStyle(
              color: Color(0xFFBBAAFE),
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 32 : 40,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Smart Educational Platform for Schools',
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 14),
          Text(
            'Connect principals, teachers, and parents in a seamless educational ecosystem. Streamline school management, assessments, and communication.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 22),
          Align(
            alignment: isMobile ? Alignment.center : Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFBBAAFE),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 18 : 32,
                      vertical: 13,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  },
                  child: const Text('Sign In'),
                ),
                SizedBox(width: 16),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFFBBAAFE),
                    side: BorderSide(color: Color(0xFFBBAAFE)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 18 : 32,
                      vertical: 13,
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SignupPage()),
                    );
                  },
                  child: const Text('Sign Up'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightTop(bool isMobile) {
    return Padding(
      padding: EdgeInsets.only(right: isMobile ? 0 : 18, left: isMobile ? 0 : 12, top: 8, bottom: 8),
      child: Container(
        width: double.infinity,
        height: isMobile ? 160 : 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            colors: [Color(0xFFD1B6F5), Color(0xFF9E8ACF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.account_balance,
            size: isMobile ? 72 : 120,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
    required bool isMobile,
    required double cardPad,
  }) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(cardPad),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: isMobile ? 30 : 38, color: color),
            SizedBox(width: isMobile ? 14 : 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isMobile ? 16 : 18,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(
                      fontSize: isMobile ? 13 : 15,
                      color: Colors.black54,
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

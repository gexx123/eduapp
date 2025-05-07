import 'package:flutter/material.dart';

class OutOfMarksRow extends StatelessWidget {
  final List<String> subjects;
  final Map<String, TextEditingController> outOfControllers;
  final bool isMobile;

  const OutOfMarksRow({
    Key? key,
    required this.subjects,
    required this.outOfControllers,
    required this.isMobile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double fontSize = isMobile ? 13 : 15;
    final double fieldWidth = isMobile ? 60 : 70;
    final double fieldHeight = isMobile ? 32 : 36;
    final double spacing = isMobile ? 10 : 16;
    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 2 : 8, right: isMobile ? 8 : 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Marks Out Of', style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize, color: Color(0xFF5B8DEE))),
          SizedBox(width: spacing),
          ...subjects.map((subject) => Padding(
            padding: EdgeInsets.only(right: spacing),
            child: SizedBox(
              width: fieldWidth,
              height: fieldHeight,
              child: TextField(
                controller: outOfControllers[subject],
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: fontSize),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: 'Max',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(isMobile ? 6 : 8)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 6, vertical: isMobile ? 6 : 10),
                  isDense: true,
                  filled: true,
                  fillColor: Color(0xFFF8F7FC),
                ),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

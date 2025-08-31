// 파일명: indicator_info_dialog.dart
import 'package:flutter/material.dart';
import '../data/indicator_info.dart';

class IndicatorInfoDialog extends StatelessWidget {
  final String group;
  final double screenWidth;
  final double screenHeight;

  const IndicatorInfoDialog({
    super.key,
    required this.group,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  Widget build(BuildContext context) {
    final info = IndicatorInfo.info[group] ?? {
      'description': '지표 설명이 없습니다.',
      'criteria': '평가 기준이 없습니다.',
    };

    return AlertDialog(
      backgroundColor: Colors.grey[850],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        '$group 정보',
        style: TextStyle(
          fontSize: screenWidth * 0.05,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '설명:',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              info['description']!,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
            SizedBox(height: screenHeight * 0.02),
            Text(
              '평가 기준:',
              style: TextStyle(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: screenHeight * 0.01),
            Text(
              info['criteria']!,
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '닫기',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: Colors.blueAccent,
            ),
          ),
        ),
      ],
    );
  }
}
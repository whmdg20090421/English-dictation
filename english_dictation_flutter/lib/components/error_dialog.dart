import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ErrorDialog extends StatelessWidget {
  final String errorMessage;
  final String stackTrace;

  const ErrorDialog({
    super.key,
    required this.errorMessage,
    required this.stackTrace,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2C313C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.white70, size: 40),
          const SizedBox(height: 8),
          const Text(
            '应用发生错误',
            style: TextStyle(color: Colors.white, fontSize: 20),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 300,
        decoration: BoxDecoration(
          color: const Color(0xFFC6342E), // Red background as in the image
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(12),
        child: SingleChildScrollView(
          child: Text(
            '未知错误\n\n$errorMessage\n$stackTrace',
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF384D76), // Blueish button
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('取消', style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: '未知错误\n\n$errorMessage\n$stackTrace'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('已复制到剪贴板'), backgroundColor: Colors.green),
            );
          },
          style: TextButton.styleFrom(
            backgroundColor: Colors.teal, // Greenish copy button
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: const Text('复制', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

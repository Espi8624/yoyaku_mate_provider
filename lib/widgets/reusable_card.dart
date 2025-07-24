import 'package:flutter/material.dart';

class ReusableCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Color? backgroundColor;

  const ReusableCard({
    super.key,
    required this.title,
    required this.child,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w800,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}
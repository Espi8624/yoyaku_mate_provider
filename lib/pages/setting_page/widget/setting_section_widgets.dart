import 'package:flutter/material.dart';

Widget buildSectionTitle(String title) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFF263238),
      ),
    ),
  );
}

Widget buildSettingItem(String title, String subtitle, Widget? trailing, {VoidCallback? onTap}) {
  return ListTile(
    title: Text(
      title,
      style: const TextStyle(fontSize: 16, color: Color(0xFF263238)),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 13, color: Colors.grey),
    ),
    trailing: trailing,
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );
}

Widget sectionBox({required Widget child}) {
  return Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 6,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    child: child,
  );
}

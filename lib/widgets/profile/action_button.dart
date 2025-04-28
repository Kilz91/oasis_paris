import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback onPressed;
  final IconData? icon;

  const ActionButton({
    Key? key,
    required this.text,
    required this.color,
    required this.onPressed,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      child: icon != null
          ? ElevatedButton.icon(
              icon: Icon(icon, color: Colors.white),
              label: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
    );
  }
}
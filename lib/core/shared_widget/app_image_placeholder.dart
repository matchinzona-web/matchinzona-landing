import 'package:flutter/material.dart';

class AppImagePlaceholder extends StatelessWidget {
  final double iconSize;
  final String testo;

  const AppImagePlaceholder({
    super.key,
    this.iconSize = 50,
    this.testo = 'Nessuna foto',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF252830), Color(0xFF1E2026)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_outlined, color: Colors.white24, size: iconSize),
            const SizedBox(height: 8),
            Text(
              testo,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

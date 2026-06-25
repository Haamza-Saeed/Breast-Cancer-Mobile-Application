import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';


class ConfidenceBar extends StatelessWidget {
  final String title;
  final double value; // 0..1
  final Color barColor;
  final Color accent;

  const ConfidenceBar({
    super.key,
    required this.title,
    required this.value,
    required this.barColor,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    final pct = (v * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: accent,
                  ),
                ),
              ),
              Text(
                "$pct%",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 12,
              value: v,
              backgroundColor: Colors.black12,
              valueColor: AlwaysStoppedAnimation(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

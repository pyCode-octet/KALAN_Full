import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class FlashcardView extends StatelessWidget {
  final String text;
  final bool isAnswer;
  final String? hint;

  const FlashcardView({
    super.key,
    required this.text,
    required this.isAnswer,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isAnswer ? const Color(0xFFEAF3DE) : const Color(0xFFF4F2EB),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isAnswer ? 'SOLUTION' : 'QUESTION',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isAnswer ? const Color(0xFF2D6A2D) : Colors.grey.shade600,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          
          // Content Text
          Text(
            text,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
              height: 1.4,
            ),
          ),
          
          if (isAnswer) ...[
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 0.5,
              color: Colors.black.withOpacity(0.08),
            ),
            const SizedBox(height: 24),
            // Example of styled math or code block if needed could go here
          ],
          
          if (hint != null && !isAnswer) ...[
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFAEEDA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Color(0xFF854F0B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hint!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF854F0B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

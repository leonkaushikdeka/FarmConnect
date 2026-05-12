import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class FarmerCard extends StatelessWidget {
  final Map<String, dynamic> farmer;
  final String farmerName;
  final VoidCallback onTap;

  const FarmerCard({
    super.key,
    required this.farmer,
    required this.farmerName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = farmer['farmName'] as String? ?? 'Farm';
    final location = farmer['address'] as String? ?? '';
    final rating = (farmer['rating'] as num?)?.toDouble() ?? 0;
    final reviewCount = (farmer['reviewCount'] as num?)?.toInt() ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              child: Text(
                name.split(' ').map((n) => n.isNotEmpty ? n[0] : '').take(2).join(),
                style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.lora(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.foreground,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    farmerName,
                    style: GoogleFonts.raleway(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    location.split(',').first,
                    style: GoogleFonts.raleway(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, size: 16, color: AppColors.rating),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w600,
                        color: AppColors.foreground,
                      ),
                    ),
                  ],
                ),
                Text(
                  '($reviewCount)',
                  style: GoogleFonts.raleway(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

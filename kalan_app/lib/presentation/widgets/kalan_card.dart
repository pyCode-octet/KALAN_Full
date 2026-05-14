import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/entities/deck.dart';

class KalanCard extends StatelessWidget {
  final Deck deck;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  const KalanCard({super.key, required this.deck, this.onTap, this.onDelete, this.onShare});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        title: Text(
          deck.title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.onBackground),
        ),
        subtitle: Row(
          children: [
            if (deck.subject != null)
              Text(deck.subject!, style: const TextStyle(fontSize: 14, color: AppColors.primary)),
            if (deck.isPublic) ...[
              const SizedBox(width: 8),
              const Icon(Icons.download_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 4),
              Text('${deck.downloadCount}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (deck.isPublic) const Icon(Icons.public, color: AppColors.secondary, size: 20),
            if (onShare != null)
              IconButton(
                icon: const Icon(Icons.share_rounded, color: AppColors.secondary, size: 20),
                onPressed: onShare,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

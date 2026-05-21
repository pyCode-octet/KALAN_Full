import 'package:flutter/material.dart';

class KalanGameIcon extends StatelessWidget {
  final String assetName;
  final double size;
  final bool hasShadow;

  const KalanGameIcon(
    this.assetName, {
    super.key,
    this.size = 28,
    this.hasShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        boxShadow: hasShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: Image.asset(
        'assets/icons/game/3d/$assetName',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            Icon(Icons.broken_image, size: size, color: Colors.grey),
      ),
    );
  }
}

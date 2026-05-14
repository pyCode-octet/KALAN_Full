enum TextScale { normal, grand, tresGrand }

extension TextScaleExtension on TextScale {
  double get factor {
    switch (this) {
      case TextScale.normal: return 1.0;
      case TextScale.grand: return 1.3;
      case TextScale.tresGrand: return 1.6;
    }
  }
}

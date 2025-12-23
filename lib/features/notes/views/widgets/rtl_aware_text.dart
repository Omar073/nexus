import 'package:flutter/widgets.dart';

class RtlAwareText extends StatelessWidget {
  const RtlAwareText(
    this.text, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;

  static bool _looksArabic(String s) {
    for (final code in s.runes) {
      // Arabic + Arabic supplement + Arabic extended ranges.
      final isArabic = (code >= 0x0600 && code <= 0x06FF) ||
          (code >= 0x0750 && code <= 0x077F) ||
          (code >= 0x08A0 && code <= 0x08FF) ||
          (code >= 0xFB50 && code <= 0xFDFF) ||
          (code >= 0xFE70 && code <= 0xFEFF);
      if (isArabic) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final rtl = _looksArabic(text);
    return Directionality(
      textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
      child: Text(
        text,
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: rtl ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}



import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: TEXTO FORMATEADO CON TRADUCCIÓN AUTOMÁTICA
// ═══════════════════════════════════════════════════════════════════════════════
class AutoFormattedText extends StatefulWidget {
  final String content;

  const AutoFormattedText({super.key, required this.content});

  @override
  State<AutoFormattedText> createState() => _AutoFormattedTextState();
}

class _AutoFormattedTextState extends State<AutoFormattedText> {
  final GoogleTranslator _translator = GoogleTranslator();
  String? _translatedContent;
  bool _isLoading = false;
  String? _lastLanguage;

  static final Map<String, String> _cache = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndTranslate();
  }

  String _getCacheKey(String lang) => '${widget.content.hashCode}_$lang';

  Future<void> _checkAndTranslate() async {
    final provider = context.read<LanguageProvider>();
    final currentLang = provider.currentLanguage;

    if (_lastLanguage == currentLang && _translatedContent != null) return;
    _lastLanguage = currentLang;

    if (provider.isSpanish) {
      if (mounted) {
        setState(() {
          _translatedContent = null;
          _isLoading = false;
        });
      }
      return;
    }

    final cacheKey = _getCacheKey(currentLang);

    if (_cache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() {
          _translatedContent = _cache[cacheKey];
          _isLoading = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _isLoading = true);

    try {
      final plainText = widget.content.replaceAll(RegExp(r'\*\*'), '');

      final translation = await _translator.translate(
        plainText,
        from: 'es',
        to: currentLang,
      );

      _cache[cacheKey] = translation.text;

      if (mounted) {
        setState(() {
          _translatedContent = translation.text;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error traduciendo contenido: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();

    if (_lastLanguage != provider.currentLanguage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndTranslate());
    }

    final textToShow = provider.isSpanish
        ? widget.content
        : (_translatedContent ?? widget.content);

    if (_isLoading && _translatedContent == null) {
      return Opacity(
        opacity: 0.5,
        child: _buildFormattedRichText(widget.content),
      );
    }

    return _buildFormattedRichText(textToShow);
  }

  Widget _buildFormattedRichText(String text) {
    final List<InlineSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldPattern.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: AppText.body.copyWith(
          color: AppColors.textDark.withOpacity(0.75),
          height: 1.6,
          fontSize: 14,
        ),
        children: spans,
      ),
    );
  }
}

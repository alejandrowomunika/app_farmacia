import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
import '../providers/language_provider.dart';

/// Widget que traduce texto automáticamente según el idioma global
class AutoText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const AutoText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  State<AutoText> createState() => _AutoTextState();
}

class _AutoTextState extends State<AutoText> {
  final GoogleTranslator _translator = GoogleTranslator();

  String? _translatedText;
  bool _isLoading = false;
  String? _lastLanguage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndTranslate();
  }

  @override
  void didUpdateWidget(AutoText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _checkAndTranslate();
    }
  }

  String _getCacheKey(String language) => '${widget.text}_$language';

  void _checkAndTranslate() {
    final provider = context.read<LanguageProvider>();
    final currentLang = provider.currentLanguage;

    // Si el idioma cambió o es la primera vez
    if (_lastLanguage != currentLang) {
      _lastLanguage = currentLang;
      _translateIfNeeded(currentLang, provider.isSpanish);
    }
  }

  Future<void> _translateIfNeeded(String targetLanguage, bool isSpanish) async {
    // Si es español (idioma original), no traducir
    if (isSpanish) {
      if (mounted) {
        setState(() {
          _translatedText = null;
          _isLoading = false;
        });
      }
      return;
    }

    final cacheKey = _getCacheKey(targetLanguage);

    // Verificar cache
    if (TranslationCache.contains(cacheKey)) {
      if (mounted) {
        setState(() {
          _translatedText = TranslationCache.get(cacheKey);
          _isLoading = false;
        });
      }
      return;
    }

    // Iniciar traducción
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final translation = await _translator.translate(
        widget.text,
        from: 'es',
        to: targetLanguage,
      );

      // Guardar en cache
      TranslationCache.set(cacheKey, translation.text);

      if (mounted) {
        setState(() {
          _translatedText = translation.text;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error traduciendo "${widget.text}": $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios del provider
    final provider = context.watch<LanguageProvider>();

    // Si cambió el idioma desde la última vez
    if (_lastLanguage != provider.currentLanguage) {
      // Programar traducción para el siguiente frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _checkAndTranslate();
      });
    }

    // Si es español, mostrar original
    if (provider.isSpanish) {
      return Text(
        widget.text,
        style: widget.style,
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    // Si está cargando
    if (_isLoading && _translatedText == null) {
      return Text(
        widget.text,
        style: widget.style?.copyWith(
          color: (widget.style?.color ?? Colors.black).withOpacity(0.4),
        ),
        textAlign: widget.textAlign,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    // Mostrar traducción o texto original si falló
    return Text(
      _translatedText ?? widget.text,
      style: widget.style,
      textAlign: widget.textAlign,
      maxLines: widget.maxLines,
      overflow: widget.overflow,
    );
  }
}

/// Extensión para uso más fácil
extension TranslatableString on String {
  Widget tr({
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return AutoText(
      this,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
import '../providers/language_provider.dart';
import '../theme/app_theme.dart';

class TranslatedTextField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextStyle? style;
  final TextInputAction? textInputAction;
  final Widget? suffixIcon;
  final InputDecoration? decoration;

  const TranslatedTextField({
    super.key,
    this.controller,
    this.focusNode,
    required this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.style,
    this.textInputAction,
    this.suffixIcon,
    this.decoration,
  });

  @override
  State<TranslatedTextField> createState() => _TranslatedTextFieldState();
}

class _TranslatedTextFieldState extends State<TranslatedTextField> {
  final GoogleTranslator _translator = GoogleTranslator();
  String _translatedHint = '';
  String? _lastLanguage;

  // Cache estático para hints
  static final Map<String, String> _hintCache = {};

  @override
  void initState() {
    super.initState();
    _translatedHint = widget.hintText;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _translateHint();
  }

  String _getCacheKey(String lang) => '${widget.hintText}_$lang';

  Future<void> _translateHint() async {
    final provider = context.read<LanguageProvider>();
    final currentLang = provider.currentLanguage;

    if (_lastLanguage == currentLang) return;
    _lastLanguage = currentLang;

    // Si es español, usar original
    if (provider.isSpanish) {
      if (mounted) {
        setState(() => _translatedHint = widget.hintText);
      }
      return;
    }

    final cacheKey = _getCacheKey(currentLang);

    // Verificar cache
    if (_hintCache.containsKey(cacheKey)) {
      if (mounted) {
        setState(() => _translatedHint = _hintCache[cacheKey]!);
      }
      return;
    }

    // Traducir
    try {
      final translation = await _translator.translate(
        widget.hintText,
        from: 'es',
        to: currentLang,
      );

      _hintCache[cacheKey] = translation.text;

      if (mounted) {
        setState(() => _translatedHint = translation.text);
      }
    } catch (e) {
      debugPrint('Error traduciendo hint: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LanguageProvider>();

    // Si cambió el idioma
    if (_lastLanguage != provider.currentLanguage) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _translateHint());
    }

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: widget.style ?? AppText.body.copyWith(fontSize: 15),
      textInputAction: widget.textInputAction,
      decoration:
          widget.decoration?.copyWith(hintText: _translatedHint) ??
          InputDecoration(
            hintText: _translatedHint,
            hintStyle: AppText.body.copyWith(
              color: AppColors.textDark.withOpacity(0.4),
              fontSize: 15,
            ),
            suffixIcon: widget.suffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: AppColors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
    );
  }
}

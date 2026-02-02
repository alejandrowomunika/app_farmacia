import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/language_provider.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppFooter({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>().currentLanguage;

    // traducciones rápidas (puedes centralizarlas luego)
    final labels = <String, String>{
      'es': 'Inicio|Tienda|Chat|Carrito',
      'en': 'Home|Store|Chat|Cart',
      'fr': 'Accueil|Boutique|Chat|Panier',
      'de': 'Start|Shop|Chat|Warenkorb',
      'it': 'Home|Negozio|Chat|Carrello',
      'pt': 'Início|Loja|Chat|Carrinho',
    };

    final items = (labels[lang] ?? labels['es']!).split('|');

    return BottomNavigationBar(
      currentIndex: currentIndex.clamp(0, 3),
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.white,
      selectedItemColor: AppColors.purple600,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: items[0]),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_bag),
          label: items[1],
        ),
        BottomNavigationBarItem(icon: const Icon(Icons.home), label: items[0]),
        BottomNavigationBarItem(
          icon: const Icon(Icons.chat_bubble),
          label: items[2],
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.shopping_cart),
          label: items[3],
        ),
      ],
    );
  }
}

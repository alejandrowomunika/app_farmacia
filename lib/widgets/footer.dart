import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppFooter extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onScanTap;

  const AppFooter({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onScanTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // Contenedor externo transparente
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Card blanca flotante con sombra mejorada
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              // ═══════════════════════════════════════════════
              // SOMBRAS PARA LA CARD
              // ═══════════════════════════════════════════════
              boxShadow: [
                // Sombra principal
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  spreadRadius: 0,
                  offset: const Offset(0, 5),
                ),
                // Sombra difusa de fondo
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 40,
                  spreadRadius: -5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_rounded, Icons.home_outlined, 0),
                _buildNavItem(Icons.store_rounded, Icons.store_outlined, 1),
                const SizedBox(width: 60),
                _buildNavItem(Icons.chat_rounded, Icons.chat, 2),
                _buildNavItem(
                  Icons.shopping_cart_rounded,
                  Icons.shopping_cart_outlined,
                  3,
                ),
              ],
            ),
          ),

          // Botón central del escáner
          Positioned(
            child: GestureDetector(
              onTap: onScanTap,
              child: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.purple600,
                ),
                child: const Icon(
                  Icons.qr_code_scanner_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData activeIcon, IconData inactiveIcon, int index) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 55,
        height: 60,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned(
              top: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOut,
                width: isSelected ? 24 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.purple600,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            AnimatedScale(
              scale: isSelected ? 1.1 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                color: isSelected ? AppColors.purple600 : Colors.grey.shade400,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

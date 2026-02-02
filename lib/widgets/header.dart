import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'menu_drawer.dart';
import 'search_drawer.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ═══════════════════════════════════════════════
          // BOTÓN MENÚ HAMBURGUESA (IZQUIERDA)
          // ═══════════════════════════════════════════════
          _HeaderIconButton(
            icon: Icons.menu_rounded,
            onTap: () => _openMenuDrawer(context),
          ),

          // ═══════════════════════════════════════════════
          // LOGO CENTRAL
          // ═══════════════════════════════════════════════
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/'),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 32, maxWidth: 160),
              child: Image.asset("assets/logcompleto.png", fit: BoxFit.contain),
            ),
          ),

          // ═══════════════════════════════════════════════
          // BOTÓN LUPA BUSCADOR (DERECHA)
          // ═══════════════════════════════════════════════
          _HeaderIconButton(
            icon: Icons.search_rounded,
            onTap: () => _openSearchDrawer(context),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ABRIR MENÚ LATERAL IZQUIERDO
  // ═══════════════════════════════════════════════════════════
  void _openMenuDrawer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const MenuDrawer();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(-1, 0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ABRIR BUSCADOR LATERAL DERECHO
  // ═══════════════════════════════════════════════════════════
  void _openSearchDrawer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) {
          return const SearchDrawer();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
                .animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: BOTÓN DE ICONO DEL HEADER
// ═══════════════════════════════════════════════════════════
class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: AppColors.purple600, size: 22),
      ),
    );
  }
}

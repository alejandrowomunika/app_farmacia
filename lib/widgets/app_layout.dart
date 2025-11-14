import 'package:flutter/material.dart';
import 'header.dart';
import 'footer.dart';

class AppLayout extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final Function(int) onFooterTap;

  const AppLayout({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onFooterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // HEADER GLOBAL
          const AppHeader(),

          // CONTENIDO VARIABLE (PÁGINAS)
          Expanded(child: child),

          // FOOTER GLOBAL
          AppFooter(
            currentIndex: currentIndex,
            onTap: onFooterTap,
          ),
        ],
      ),
    );
  }
}

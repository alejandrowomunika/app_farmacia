import 'package:flutter/material.dart';
import '../widgets/app_layout.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  int selectedIndex = 3; // Perfil en footer

  void onFooterTap(int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/tienda');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/chat');
    } else if (index == 3) {
      // ya estás aquí
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: selectedIndex,
      onFooterTap: onFooterTap,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
          ],
        ),
      ),
    );
  }
}

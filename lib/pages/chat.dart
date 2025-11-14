import 'package:flutter/material.dart';
import '../widgets/app_layout.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  int selectedIndex = 2; // Productos en footer

  void onFooterTap(int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/tienda');
    } else if (index == 2) {
      // ya estás aquí 
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/user');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: selectedIndex,
      onFooterTap: onFooterTap,
      child: const Center(
        child: Text(
          "CHAT",
          style: TextStyle(fontSize: 23),
        ),
      ),
    );
  }
}

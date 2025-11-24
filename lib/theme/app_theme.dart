import 'package:flutter/material.dart';

/// ✅ PALETA DE COLORES COMPLETA (PURPLE + GREEN)
class AppColors {
  // ------------------------
  // ✅ PURPLE
  // ------------------------
  static const Color purple50  = Color(0xfff6e6f2);
  static const Color purple100 = Color(0xffe4b1d6);
  static const Color purple200 = Color(0xffd78bc2);
  static const Color purple300 = Color(0xffc455a6);
  static const Color purple400 = Color(0xffb03995);
  static const Color purple500 = Color(0xffa7027a);
  static const Color purple600 = Color(0xff98026f);
  static const Color purple700 = Color(0xff770157);
  static const Color purple800 = Color(0xff5c0143);
  static const Color purple900 = Color(0xff460133);

  // ------------------------
  // ✅ GREEN
  // ------------------------
  static const Color green50  = Color(0xffeff8e7);
  static const Color green100 = Color(0xffcdeab4);
  static const Color green200 = Color(0xffb5e08f);
  static const Color green300 = Color(0xff93d25c);
  static const Color green400 = Color(0xff7ec93d);
  static const Color green500 = Color(0xff5ebc0c);
  static const Color green600 = Color(0xff56ab0b);
  static const Color green700 = Color(0xff438509);
  static const Color green800 = Color(0xff346707);
  static const Color green900 = Color(0xff274f05);

  // ------------------------
  // ✅ Colores GENERALES de la app
  // ------------------------
  static const Color background = Color(0xfff5f5f5);
  static const Color textDark = Color(0xff1a1a1a);
  static const Color white = Colors.white;

  // ✅ Elegimos un "primary" basado en la paleta
  static const Color primary = green500;
  static const Color secondary = purple500;
  
  // ------------------------
  // ✅ Nuevo: GRADIENTE
  // ------------------------
  // Usaremos un degradado que va del purple500 (secundario) al purple100
  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      purple500, // Color inicial (más oscuro, arriba)
      purple300, 
      purple100, // Color final (más claro, abajo)
    ],
    stops: [0.0, 0.4, 1.0],
  );
}

/// ✅ TIPOGRAFÍA Y ESTILOS
class AppText {
  static const TextStyle title = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: AppColors.textDark,
    fontFamily: 'Mulish',
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textDark,
    fontFamily: 'Mulish',
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    color: AppColors.textDark,
    fontFamily: 'Mulish',
  );

  static const TextStyle small = TextStyle(
    fontSize: 12,
    color: AppColors.textDark,
    fontFamily: 'Mulish',
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    fontFamily: 'Mulish',
  );

  
}

/// ✅ SOMBRAS Y RADIOS
class AppStyles {
  static const BorderRadius radius = BorderRadius.all(Radius.circular(12));

  static BoxShadow shadow = BoxShadow(
    color: Colors.black12,
    blurRadius: 6,
    offset: Offset(0, 3),
  );
}

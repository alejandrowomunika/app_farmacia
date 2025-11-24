import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final int id;
  final String name;

  final double priceTaxExcl;   // precio sin IVA
  final double priceTaxIncl;   // precio con IVA
  final double taxRate;        // porcentaje del IVA aplicado

  int quantity;
  final String image;

  CartItem({
    required this.id,
    required this.name,
    required this.priceTaxExcl,
    required this.priceTaxIncl,
    required this.taxRate,
    required this.quantity,
    required this.image,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'priceTaxExcl': priceTaxExcl,
        'priceTaxIncl': priceTaxIncl,
        'taxRate': taxRate,
        'quantity': quantity,
        'image': image,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'],
        name: json['name'],
        priceTaxExcl: json['priceTaxExcl'],
        priceTaxIncl: json['priceTaxIncl'],
        taxRate: json['taxRate'],
        quantity: json['quantity'],
        image: json['image'],
      );
}

class Cart {
  static List<CartItem> items = [];
  static const _cartKey = "CART_DATA";
  static const _timeKey = "CART_TIMESTAMP";
  static const int sessionMinutes = 1;

  /// ======================================================
  /// GUARDAR CARRITO + TIMESTAMP
  /// ======================================================
  static Future<void> saveCart() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((e) => e.toJson()).toList();

    prefs.setString(_cartKey, jsonEncode(jsonList));
    prefs.setInt(_timeKey, DateTime.now().millisecondsSinceEpoch);
  }

  /// ======================================================
  /// CARGAR CARRITO (si NO expiró)
  /// ======================================================
  static Future<void> Function(List<CartItem>)? onSessionExpired;

  static Future<void> loadCart() async {
    final prefs = await SharedPreferences.getInstance();

    final timestamp = prefs.getInt(_timeKey);
    if (timestamp == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final diffMinutes = (now - timestamp) / (1000 * 60);

    if (diffMinutes > sessionMinutes) {
      // Sesión expirada → devolver stock
      if (onSessionExpired != null) {
        await onSessionExpired!(items);
      }

      prefs.remove(_cartKey);
      prefs.remove(_timeKey);
      items.clear();
      return;
    }

    final dataString = prefs.getString(_cartKey);
    if (dataString != null) {
      List decoded = jsonDecode(dataString);
      items = decoded.map((e) => CartItem.fromJson(e)).toList();
    }
  }

  /// ======================================================
  /// AÑADIR PRODUCTO
  /// ======================================================
  static void addItem(CartItem item) async {
    final index = items.indexWhere((e) => e.id == item.id);

    if (index >= 0) {
      items[index].quantity += item.quantity;
    } else {
      items.add(item);
    }

    saveCart();
  }

  /// ======================================================
  /// ELIMINAR PRODUCTO
  /// ======================================================
  static void removeItem(int id) async {
    items.removeWhere((e) => e.id == id);

    if (items.isEmpty) {
      final prefs = await SharedPreferences.getInstance();

      // devolver stock ANTES de limpiar sesión
      if (onSessionExpired != null) {
        await onSessionExpired!(items);
      }

      prefs.remove(_cartKey);
      prefs.remove(_timeKey);
    } else {
      saveCart();
    }
  }

  /// ======================================================
  /// LIMPIAR CARRITO + SESIÓN
  /// ======================================================
  static void clear() async {
    items.clear();
    final prefs = await SharedPreferences.getInstance();
    prefs.remove(_cartKey);
    prefs.remove(_timeKey);
  }

  /// ======================================================
  /// TOTAL A PAGAR (con IVA)
  /// ======================================================
  static double totalPrice() {
    return items.fold(0, (sum, e) => sum + e.priceTaxIncl * e.quantity);
  }

  /// ======================================================
  /// RESTAURAR STOCK AL EXPIRAR
  /// ======================================================
  static Future<void> restoreStockOfAllItems(
    Future<void> Function(CartItem item, int amount) sumarStockFn,
  ) async {
    for (final item in items) {
      await sumarStockFn(item, item.quantity);
    }
  }
}

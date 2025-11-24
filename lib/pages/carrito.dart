import 'package:app_farmacia/widgets/footer.dart';
import 'package:flutter/material.dart';
import '../data/cart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  int selectedIndex = 3;
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
  void initState() {
    super.initState();
    // Si la sesión expira → devolver stock automáticamente
    Cart.onSessionExpired = (items) async {
      for (final item in items) {
        await _sumarStockOfItem(item, item.quantity);
      }
    };

    Cart.loadCart().then((_) {
      setState(() {});
    });
  }

  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";
    Map<String, dynamic>? stockData;
  // 1. Cargar stock de un PRODUCTO del carrito (por su ID)
  Future<Map<String, dynamic>?> _loadStockOfItem(int productId) async {
    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables"
      "?ws_key=$apiKey&output_format=JSON&display=full&filter[id_product]=$productId"
    );

    try {
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["stock_availables"] != null &&
            data["stock_availables"].isNotEmpty) {
          return data["stock_availables"][0];
        }
      }
    } catch (e) {
      print("Error obteniendo stock: $e");
    }

    return null;
  }

  // 2. Sumar stock al eliminar producto del carrito
  Future<void> _sumarStockOfItem(CartItem item, int amount) async {
    final stock = await _loadStockOfItem(item.id);

    if (stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo obtener stock del producto.")),
      );
      return;
    }

    // Datos obligatorios
    final stockId = stock["id"].toString();
    final idProduct = stock["id_product"].toString();
    final idProductAttribute = stock["id_product_attribute"].toString();
    final idShop = stock["id_shop"].toString();
    final idShopGroup = stock["id_shop_group"].toString();
    final dependsOnStock = stock["depends_on_stock"].toString();
    final outOfStock = stock["out_of_stock"].toString();
    final location = stock["location"]?.toString() ?? "";

    final currentStock = int.tryParse(stock["quantity"].toString()) ?? 0;
    final newQuantity = currentStock + amount;

    print("Sumando $amount unidades → Stock final = $newQuantity");

    // XML para actualizar Prestashop
    final xmlBody = '''
<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <stock_available>
    <id><![CDATA[$stockId]]></id>
    <id_product><![CDATA[$idProduct]]></id_product>
    <id_product_attribute><![CDATA[$idProductAttribute]]></id_product_attribute>
    <id_shop><![CDATA[$idShop]]></id_shop>
    <id_shop_group><![CDATA[$idShopGroup]]></id_shop_group>
    <quantity><![CDATA[$newQuantity]]></quantity>
    <depends_on_stock><![CDATA[$dependsOnStock]]></depends_on_stock>
    <out_of_stock><![CDATA[$outOfStock]]></out_of_stock>
    <location><![CDATA[$location]]></location>
  </stock_available>
</prestashop>
''';

    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables/$stockId?ws_key=$apiKey"
    );

    final res = await http.put(
      url,
      headers: {"Content-Type": "application/xml"},
      body: xmlBody,
    );

    if (res.statusCode == 200) {
      print("Stock actualizado correctamente");
    } else {
      print("Error actualizando stock: ${res.body}");
    }
  }

// 2. Restar stock al agregar producto del carrito
  Future<void> _restarStockOfItem(CartItem item, int amount) async {
    final stock = await _loadStockOfItem(item.id);

    if (stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No se pudo obtener stock del producto.")),
      );
      return;
    }

    // Datos obligatorios
    final stockId = stock["id"].toString();
    final idProduct = stock["id_product"].toString();
    final idProductAttribute = stock["id_product_attribute"].toString();
    final idShop = stock["id_shop"].toString();
    final idShopGroup = stock["id_shop_group"].toString();
    final dependsOnStock = stock["depends_on_stock"].toString();
    final outOfStock = stock["out_of_stock"].toString();
    final location = stock["location"]?.toString() ?? "";

    final currentStock = int.tryParse(stock["quantity"].toString()) ?? 0;
    final newQuantity = currentStock - amount;

    print("Restando $amount unidades → Stock final = $newQuantity");

    // XML para actualizar Prestashop
    final xmlBody = '''
<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <stock_available>
    <id><![CDATA[$stockId]]></id>
    <id_product><![CDATA[$idProduct]]></id_product>
    <id_product_attribute><![CDATA[$idProductAttribute]]></id_product_attribute>
    <id_shop><![CDATA[$idShop]]></id_shop>
    <id_shop_group><![CDATA[$idShopGroup]]></id_shop_group>
    <quantity><![CDATA[$newQuantity]]></quantity>
    <depends_on_stock><![CDATA[$dependsOnStock]]></depends_on_stock>
    <out_of_stock><![CDATA[$outOfStock]]></out_of_stock>
    <location><![CDATA[$location]]></location>
  </stock_available>
</prestashop>
''';

    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables/$stockId?ws_key=$apiKey"
    );

    final res = await http.put(
      url,
      headers: {"Content-Type": "application/xml"},
      body: xmlBody,
    );

    if (res.statusCode == 200) {
      print("Stock actualizado correctamente");
    } else {
      print("Error actualizando stock: ${res.body}");
    }

    
  }

  
  
  // ======================================================
  // 3. UI DEL CARRITO
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Carrito")),
      body: Cart.items.isEmpty
          ? Center(child: Text("Tu carrito está vacío"))
          : ListView.builder(
              itemCount: Cart.items.length,
              itemBuilder: (context, index) {
                final item = Cart.items[index];

                return Card(
                  child: ListTile(
                    leading: Image.network(item.image, width: 60),
                    title: Text(item.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${item.quantity} x ${item.priceTaxIncl.toStringAsFixed(2)} € = ${(item.quantity * item.priceTaxIncl).toStringAsFixed(2)} €",
                        ),

                        const SizedBox(height: 6),

                        // Botones -   cantidad   +
                        Row(
                          children: [
                            // Botón restar
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                              onPressed: () async {
                                if (item.quantity > 1) {
                                  // 1) Sumar stock en Prestashop (devolver 1 unidad)
                                  await _sumarStockOfItem(item, 1);

                                  // 2) Restar cantidad en el carrito
                                  setState(() {
                                    item.quantity -= 1;
                                  });


                                } else {
                                  // Si llega a 0 → eliminar item, devolver todas las unidades
                                  await _sumarStockOfItem(item, item.quantity);

                                  setState(() {
                                    Cart.removeItem(item.id);
                                  });
                                }
                                Cart.saveCart(); 

                              },
                            ),

                            // Cantidad visual
                            Text(item.quantity.toString(),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                            // Botón sumar
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              onPressed: () async {
                                // 1) Restar stock en Prestashop (1 unidad)
                                await _restarStockOfItem(item, 1);

                                // 2) Sumar cantidad en carrito
                                setState(() {
                                  item.quantity += 1;
                                });
                                Cart.saveCart(); 
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );

              },
            ),
      // footer en bottomNavigationBar para que siempre quede accesible
      bottomNavigationBar: AppFooter(
        currentIndex: selectedIndex,
        onTap: onFooterTap,
      ),
    );
  }
  
}

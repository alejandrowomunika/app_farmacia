import 'package:app_farmacia/widgets/footer.dart';
import 'package:flutter/material.dart';
import '../data/cart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  int selectedIndex = 3;
  bool _isProcessing = false;

  // API Keys
  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";
  final String appSecretKey = "FarmaciaGuerrero_App_25_SecretKey_X7k9m2";

  @override
  void initState() {
    super.initState();

    Cart.onSessionExpired = (items) async {
      for (final item in items) {
        await _sumarStockOfItem(item, item.quantity);
      }
    };

    Cart.loadCart().then((_) => setState(() {}));
  }

  void onFooterTap(int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/tienda');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/chat');
    }
  }

  // ======================================================
  // STOCK MANAGEMENT
  // ======================================================
  Future<Map<String, dynamic>?> _loadStockOfItem(int productId) async {
    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables"
      "?ws_key=$apiKey&output_format=JSON&display=full&filter[id_product]=$productId",
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
      print("Error cargando stock: $e");
    }
    return null;
  }

  Future<void> _sumarStockOfItem(CartItem item, int amount) async {
    final stock = await _loadStockOfItem(item.id);
    if (stock == null) return;

    final newQuantity =
        (int.tryParse(stock["quantity"].toString()) ?? 0) + amount;

    final xmlBody = '''
<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <stock_available>
    <id><![CDATA[${stock["id"]}]]></id>
    <id_product><![CDATA[${stock["id_product"]}]]></id_product>
    <id_product_attribute><![CDATA[${stock["id_product_attribute"]}]]></id_product_attribute>
    <id_shop><![CDATA[${stock["id_shop"]}]]></id_shop>
    <id_shop_group><![CDATA[${stock["id_shop_group"]}]]></id_shop_group>
    <quantity><![CDATA[$newQuantity]]></quantity>
    <depends_on_stock><![CDATA[${stock["depends_on_stock"]}]]></depends_on_stock>
    <out_of_stock><![CDATA[${stock["out_of_stock"]}]]></out_of_stock>
    <location><![CDATA[${stock["location"] ?? ""}]]></location>
  </stock_available>
</prestashop>
''';

    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables/${stock["id"]}?ws_key=$apiKey",
    );

    await http.put(
      url,
      headers: {"Content-Type": "application/xml"},
      body: xmlBody,
    );
  }

  Future<void> _restarStockOfItem(CartItem item, int amount) async {
    final stock = await _loadStockOfItem(item.id);
    if (stock == null) return;

    final newQuantity =
        (int.tryParse(stock["quantity"].toString()) ?? 0) - amount;

    final xmlBody = '''
<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <stock_available>
    <id><![CDATA[${stock["id"]}]]></id>
    <id_product><![CDATA[${stock["id_product"]}]]></id_product>
    <id_product_attribute><![CDATA[${stock["id_product_attribute"]}]]></id_product_attribute>
    <id_shop><![CDATA[${stock["id_shop"]}]]></id_shop>
    <id_shop_group><![CDATA[${stock["id_shop_group"]}]]></id_shop_group>
    <quantity><![CDATA[$newQuantity]]></quantity>
    <depends_on_stock><![CDATA[${stock["depends_on_stock"]}]]></depends_on_stock>
    <out_of_stock><![CDATA[${stock["out_of_stock"]}]]></out_of_stock>
    <location><![CDATA[${stock["location"] ?? ""}]]></location>
  </stock_available>
</prestashop>
''';

    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables/${stock["id"]}?ws_key=$apiKey",
    );

    await http.put(
      url,
      headers: {"Content-Type": "application/xml"},
      body: xmlBody,
    );
  }

  // ======================================================
  // SINCRONIZAR CARRITO CON PRESTASHOP (API personalizada)
  // ======================================================
  Future<Map<String, dynamic>?> _syncCartWithPrestashop() async {
    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api_cart_sync.php",
    );

    final products = Cart.items
        .map((item) => {
              'id_product': item.id,
              'id_product_attribute': 0,
              'quantity': item.quantity,
            })
        .toList();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': appSecretKey,
        },
        body: jsonEncode({'products': products}),
      );

      print("Response status: ${response.statusCode}");
      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
    } catch (e) {
      print("Error sincronizando carrito: $e");
    }
    return null;
  }

  // ======================================================
  // UI DEL CARRITO
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carrito")),
      body: Column(
        children: [
          Expanded(
            child: Cart.items.isEmpty
                ? const Center(child: Text("Tu carrito está vacío"))
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
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.orange,
                                    ),
                                    onPressed: () async {
                                      if (item.quantity > 1) {
                                        await _sumarStockOfItem(item, 1);
                                        setState(() => item.quantity--);
                                      } else {
                                        await _sumarStockOfItem(
                                            item, item.quantity);
                                        setState(
                                            () => Cart.removeItem(item.id));
                                      }
                                      Cart.saveCart();
                                    },
                                  ),
                                  Text(
                                    item.quantity.toString(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.add_circle_outline,
                                      color: Colors.green,
                                    ),
                                    onPressed: () async {
                                      await _restarStockOfItem(item, 1);
                                      setState(() => item.quantity++);
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
          ),

          // BOTÓN FINALIZAR PEDIDO
          if (Cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 22,
                  ),
                  backgroundColor: Colors.green,
                ),
                onPressed: _isProcessing
                    ? null
                    : () async {
                        setState(() => _isProcessing = true);

                        try {
                          // Llamar a la API personalizada
                          final result = await _syncCartWithPrestashop();

                          if (result != null && result['success'] == true) {
                            final idCart = result['id_cart'];
                            final secureKey = result['secure_key'];

                            // Construir URL con id_cart y secure_key
                            final url =
                                "https://www.farmaciaguerrerozieza.com/app-carrito?id_cart=$idCart&key=$secureKey";

                            print("Abriendo URL: $url");

                            // Abrir en navegador (igual que el código original)
                            launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          } else {
                            // Mostrar error
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Error: ${result?['error'] ?? 'No se pudo crear el carrito'}",
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        } catch (e) {
                          print("Error: $e");
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Error: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        } finally {
                          setState(() => _isProcessing = false);
                        }
                      },
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "Finalizar Pedido",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: selectedIndex,
        onTap: onFooterTap,
      ),
    );
  }
}
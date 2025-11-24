import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../data/cart.dart';

class ProductPage extends StatefulWidget {
  final int id;

  const ProductPage({super.key, required this.id});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  Map<String, dynamic>? product;
  Map<String, dynamic>? stockData;

  bool _loading = true;
  String _errorMessage = '';
  int selectedIndex = 0;

  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    await _getProduct();
    await _getStock();
    setState(() {});
  }

  Future<void> _getProduct() async {
    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/products/${widget.id}?ws_key=$apiKey&output_format=JSON",
    );

    try {
      final res = await http.get(url);

      if (!mounted) return;

      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        product = decoded["product"];
      } else {
        _errorMessage = "Error del servidor (${res.statusCode})";
      }
    } catch (e) {
      _errorMessage = "Error de conexión: $e";
    }
  }

  Future<void> _getStock() async {
    final url = Uri.parse(
        "https://www.farmaciaguerrerozieza.com/api/stock_availables?ws_key=$apiKey&output_format=JSON&display=full&filter[id_product]=${widget.id}");

    try {
      final res = await http.get(url);
      if (!mounted) return;

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);

        if (data["stock_availables"] != null &&
            data["stock_availables"].isNotEmpty) {
          stockData = data["stock_availables"][0];
        }
      }
    } catch (e) {
      print("Error stock: $e");
    }

    setState(() => _loading = false);
  }

  // -------------------------------
  // Obtener imagen
  // -------------------------------
  String _getImageUrl() {
    if (product == null) return "";

    final String idImage = (product!["id_default_image"] ?? "").toString();
    if (idImage.isEmpty) return "";

    return "https://www.farmaciaguerrerozieza.com/api/images/products/${product!["id"]}/$idImage?ws_key=$apiKey";
  }

  // -------------------------------
  // RESTAR STOCK (sin cambios)
  // -------------------------------
  Future<void> _restarStock() async {
    if (stockData == null || product == null) return;

    final stockId = stockData!["id"]?.toString();
    if (stockId == null) return;

    final idProduct = stockData!["id_product"]?.toString() ?? product!["id"].toString();
    final idProductAttribute = stockData!["id_product_attribute"]?.toString() ?? "0";
    final idShop = stockData!["id_shop"]?.toString() ?? "1";
    final idShopGroup = stockData!["id_shop_group"]?.toString() ?? "0";
    final dependsOnStock = stockData!["depends_on_stock"]?.toString() ?? "0";
    final outOfStock = stockData!["out_of_stock"]?.toString() ?? "2";
    final location = stockData!["location"]?.toString() ?? "";

    int quantity = int.tryParse(stockData!["quantity"]?.toString() ?? "0") ?? 0;

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No queda stock.")),
      );
      return;
    }

    final newQuantity = quantity - 1;

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
      "https://www.farmaciaguerrerozieza.com/api/stock_availables/$stockId?ws_key=$apiKey",
    );

    try {
      final res = await http.put(url,
          headers: {
            "Content-Type": "application/xml",
            "Accept": "application/xml",
          },
          body: xmlBody);

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          stockData!["quantity"] = newQuantity.toString();
        });
      }
    } catch (e) {
      print("PUT stock error: $e");
    }
  }

  // -------------------------------
  // UI PRODUCTO
  // -------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : product == null
                      ? const Center(child: Text("No se encontró el producto"))
                      : _buildProductContent(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: selectedIndex,
        onTap: onFooterTap,
      ),
    );
  }

  void onFooterTap(int index) {
    setState(() => selectedIndex = index);

    if (index == 0) Navigator.pushReplacementNamed(context, '/');
    if (index == 1) Navigator.pushReplacementNamed(context, '/tienda');
    if (index == 2) Navigator.pushReplacementNamed(context, '/chat');
    if (index == 3) Navigator.pushReplacementNamed(context, '/carrito');
  }

  // -------------------------------
  // LÓGICA IVA
  // -------------------------------
  double _getTaxRateFromGroup() {
    final taxGroupId = product?["id_tax_rules_group"]?.toString() ?? "0";

    switch (taxGroupId) {
      case "1":
        return 4;
      case "2":
        return 10;
      case "3":
        return 21;
      default:
        return 0;
    }
  }

  // -------------------------------
  // UI
  // -------------------------------
  Widget _buildProductContent() {
    final id = product!["id"];
    final name = product!["name"];
    final priceTaxExcl = double.tryParse(product?["price"] ?? "0") ?? 0;

    final taxRate = _getTaxRateFromGroup();
    final priceTaxIncl = priceTaxExcl * (1 + taxRate / 100);

    final stock = stockData?["quantity"] ?? "0";
    final imageUrl = _getImageUrl();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl.isEmpty
                  ? Container(color: Colors.grey.shade200)
                  : Image.network(imageUrl, fit: BoxFit.cover),
            ),
          ),

          const SizedBox(height: 16),

          Text(id.toString(),
              style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(name,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),

          const SizedBox(height: 8),

          Text(
            "${priceTaxIncl.toStringAsFixed(2)} €",
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green),
          ),

          Text("IVA aplicado: $taxRate%"),

          const SizedBox(height: 8),

          Text("Stock: $stock",
              style: const TextStyle(fontSize: 18, color: Colors.blue)),

          const SizedBox(height: 20),

          ElevatedButton(
            onPressed: () async {
              await _restarStock();

              Cart.addItem(
                CartItem(
                  id: id,
                  name: name,
                  priceTaxExcl: priceTaxExcl,
                  priceTaxIncl: priceTaxIncl,
                  taxRate: taxRate,
                  quantity: 1,
                  image: imageUrl,
                ),
              );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Producto añadido al carrito")),
              );
            },
            child: const Text("Añadir al carrito"),
          ),
        ],
      ),
    );
  }
}

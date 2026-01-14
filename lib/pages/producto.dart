import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../data/cart.dart';
import '../theme/app_theme.dart';

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

  // Control para expandir/contraer descripción
  bool _isDescriptionExpanded = false;

  // ═══════════════════════════════════════════════════════════
  // CONTROL ANTI-SPAM PARA AÑADIR AL CARRITO
  // ═══════════════════════════════════════════════════════════
  bool _isAddingToCart = false;

  // ═══════════════════════════════════════════════════════════
  // PRODUCTOS RELACIONADOS
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> relatedProducts = [];
  bool _loadingRelated = true;

  final String baseUrl = "https://www.farmaciaguerrerozieza.com";
  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    await _getProduct();
    await _getStock();

    if (product != null) {
      await _loadRelatedProducts();
    }

    setState(() {});
  }

  Future<void> _getProduct() async {
    final url = Uri.parse(
      "$baseUrl/api/products/${widget.id}?ws_key=$apiKey&output_format=JSON",
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
      "$baseUrl/api/stock_availables?ws_key=$apiKey&output_format=JSON&display=full&filter[id_product]=${widget.id}",
    );

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
      debugPrint("Error stock: $e");
    }

    setState(() => _loading = false);
  }

  // ═══════════════════════════════════════════════════════════
  // OBTENER Y LIMPIAR DESCRIPCIÓN
  // ═══════════════════════════════════════════════════════════
  String _getDescription() {
    if (product == null) return "";

    // Intentar obtener descripción corta primero, luego la completa
    String description = "";

    // PrestaShop puede devolver la descripción en diferentes formatos
    final descShort = product!["description_short"];
    final descFull = product!["description"];

    if (descShort != null && descShort.toString().isNotEmpty) {
      description = descShort.toString();
    } else if (descFull != null && descFull.toString().isNotEmpty) {
      description = descFull.toString();
    }

    // Limpiar HTML
    return _stripHtml(description);
  }

  String _getFullDescription() {
    if (product == null) return "";

    final descFull = product!["description"];

    if (descFull != null && descFull.toString().isNotEmpty) {
      return _stripHtml(descFull.toString());
    }

    return _getDescription();
  }

  /// Elimina etiquetas HTML del texto
  String _stripHtml(String htmlText) {
    if (htmlText.isEmpty) return "";

    // Reemplazar <br>, <br/>, <br /> por saltos de línea
    String text = htmlText
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n');

    // Eliminar todas las demás etiquetas HTML
    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

    // Decodificar entidades HTML comunes
    text = text
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&euro;', '€')
        .replaceAll('&copy;', '©')
        .replaceAll('&reg;', '®');

    // Limpiar espacios múltiples y saltos de línea excesivos
    text = text
        .replaceAll(RegExp(r' +'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return text;
  }

  // ═══════════════════════════════════════════════════════════
  // CARGAR PRODUCTOS RELACIONADOS (MISMA CATEGORÍA)
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadRelatedProducts() async {
    if (product == null) return;

    final categoryId = product!["id_category_default"]?.toString() ?? "";

    if (categoryId.isEmpty) {
      setState(() => _loadingRelated = false);
      return;
    }

    try {
      final url = Uri.parse(
        "$baseUrl/api/products?ws_key=$apiKey&display=full&output_format=JSON&filter[id_category_default]=$categoryId",
      );

      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List rawProducts = decoded["products"] ?? [];

        List<Map<String, dynamic>> tempList = [];

        for (var p in rawProducts) {
          final int productId = int.tryParse(p["id"].toString()) ?? 0;

          if (productId == widget.id) continue;

          String name = p["name"] ?? "Sin nombre";

          double price = 0.0;
          if (p["price"] is String) {
            price = double.tryParse(p["price"]) ?? 0.0;
          } else if (p["price"] is num) {
            price = p["price"].toDouble();
          }

          int imgId = 0;
          if (p["associations"]?["images"] is List &&
              p["associations"]["images"].isNotEmpty) {
            imgId =
                int.tryParse(p["associations"]["images"][0]["id"].toString()) ??
                0;
          }

          String imageUrl = imgId > 0 ? _buildPrestashopImageUrl(imgId) : "";

          tempList.add({
            "id": productId,
            "name": name,
            "price": price,
            "image": imageUrl,
          });
        }

        tempList.shuffle(Random());

        if (tempList.length > 10) {
          tempList = tempList.sublist(0, 10);
        }

        setState(() {
          relatedProducts = tempList;
          _loadingRelated = false;
        });
      } else {
        setState(() => _loadingRelated = false);
      }
    } catch (e) {
      debugPrint("Error cargando productos relacionados: $e");
      setState(() => _loadingRelated = false);
    }
  }

  String _buildPrestashopImageUrl(int imgId) {
    final digits = imgId.toString().split('');
    final path = digits.join('/');
    return "$baseUrl/img/p/$path/$imgId-home_default.jpg";
  }

  bool _isProductAvailable() {
    if (stockData == null) return false;
    final quantity =
        int.tryParse(stockData!["quantity"]?.toString() ?? "0") ?? 0;
    return quantity > 0;
  }

  int _getStockQuantity() {
    if (stockData == null) return 0;
    return int.tryParse(stockData!["quantity"]?.toString() ?? "0") ?? 0;
  }

  String _getImageUrl() {
    if (product == null) return "";

    final String idImage = (product!["id_default_image"] ?? "").toString();
    if (idImage.isEmpty) return "";

    return "$baseUrl/api/images/products/${product!["id"]}/$idImage?ws_key=$apiKey";
  }

  Future<void> _restarStock() async {
    if (stockData == null || product == null) return;

    final stockId = stockData!["id"]?.toString();
    if (stockId == null) return;

    final idProduct =
        stockData!["id_product"]?.toString() ?? product!["id"].toString();
    final idProductAttribute =
        stockData!["id_product_attribute"]?.toString() ?? "0";
    final idShop = stockData!["id_shop"]?.toString() ?? "1";
    final idShopGroup = stockData!["id_shop_group"]?.toString() ?? "0";
    final dependsOnStock = stockData!["depends_on_stock"]?.toString() ?? "0";
    final outOfStock = stockData!["out_of_stock"]?.toString() ?? "2";
    final location = stockData!["location"]?.toString() ?? "";

    int quantity = _getStockQuantity();

    if (quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "No queda stock.",
            style: AppText.body.copyWith(color: AppColors.white),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    final newQuantity = quantity - 1;

    final xmlBody =
        '''
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
      "$baseUrl/api/stock_availables/$stockId?ws_key=$apiKey",
    );

    try {
      final res = await http.put(
        url,
        headers: {
          "Content-Type": "application/xml",
          "Accept": "application/xml",
        },
        body: xmlBody,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        setState(() {
          stockData!["quantity"] = newQuantity.toString();
        });
      }
    } catch (e) {
      debugPrint("PUT stock error: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════
// AÑADIR AL CARRITO CON DELAY ANTI-SPAM
// ═══════════════════════════════════════════════════════════
Future<void> _addToCart({
  required dynamic id,
  required String name,
  required double priceTaxExcl,
  required double priceTaxIncl,
  required double taxRate,
  required String imageUrl,
}) async {
  // Evitar múltiples pulsaciones
  if (_isAddingToCart) return;

  setState(() => _isAddingToCart = true);

  try {
    // Actualizar stock
    await _restarStock();

    // Añadir al carrito local
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

    // Mostrar mensaje de confirmación con botones
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ═══════════════════════════════════════════
              // FILA SUPERIOR: Mensaje + Botón cerrar
              // ═══════════════════════════════════════════
              Row(
                children: [
                  
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "¡Añadido al carrito!",
                          style: AppText.body.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          name.length > 50 
                              ? "${name.substring(0, 30)}..." 
                              : name,
                          style: AppText.small.copyWith(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  
                ],
              ),

              const SizedBox(height: 14),

              // ═══════════════════════════════════════════
              // FILA INFERIOR: Botones de acción
              // ═══════════════════════════════════════════
              Row(
                children: [
                  // BOTÓN: Seguir comprando
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              color: AppColors.white,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Seguir comprando",
                              style: AppText.small.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // BOTÓN: Ir al carrito
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        Navigator.pushNamed(context, '/carrito');
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.shopping_cart_rounded,
                              color: AppColors.green600,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Ir al carrito",
                              style: AppText.small.copyWith(
                                color: AppColors.green600,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          backgroundColor: AppColors.green600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          elevation: 10,
          duration: const Duration(seconds: 5),
        ),
      );
    }

    // ═══════════════════════════════════════════════════════
    // DELAY: Esperar antes de permitir otra pulsación
    // ═══════════════════════════════════════════════════════
    await Future.delayed(const Duration(seconds: 2));

  } catch (e) {
    debugPrint("Error añadiendo al carrito: $e");

    // Mostrar error si algo falla
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: AppColors.white),
              const SizedBox(width: 10),
              Text(
                "Error al añadir al carrito",
                style: AppText.body.copyWith(color: AppColors.white),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } finally {
    // Rehabilitar el botón
    if (mounted) {
      setState(() => _isAddingToCart = false);
    }
  }
}

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

  // ═══════════════════════════════════════════════════════════
  // COMPARTIR PRODUCTO
  // ═══════════════════════════════════════════════════════════
  void _shareProduct() {
    final name = product?["name"] ?? "Producto";
    final url = "$baseUrl/producto/${widget.id}";
    final shareText = "¡Echa un vistazo a este producto!\n\n$name\n\n$url";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Text("Compartir producto", style: AppText.subtitle),

            const SizedBox(height: 20),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purple100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.link, color: AppColors.purple600),
              ),
              title: Text(
                "Copiar enlace",
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                "Copia el enlace al portapapeles",
                style: AppText.small,
              ),
              onTap: () {
                Clipboard.setData(ClipboardData(text: url));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check, color: AppColors.white),
                        const SizedBox(width: 12),
                        Text(
                          "Enlace copiado",
                          style: AppText.body.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.green600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            ),

            const SizedBox(height: 8),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.message, color: AppColors.green600),
              ),
              title: Text(
                "Copiar mensaje completo",
                style: AppText.body.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text("Incluye nombre y enlace", style: AppText.small),
              onTap: () {
                Clipboard.setData(ClipboardData(text: shareText));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check, color: AppColors.white),
                        const SizedBox(width: 12),
                        Text(
                          "Mensaje copiado",
                          style: AppText.body.copyWith(color: AppColors.white),
                        ),
                      ],
                    ),
                    backgroundColor: AppColors.green600,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.green500,
                      ),
                    )
                  : product == null
                  ? Center(
                      child: Text(
                        _errorMessage.isNotEmpty
                            ? _errorMessage
                            : "No se encontró el producto",
                        style: AppText.body,
                      ),
                    )
                  : _buildProductLayout(),
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
    // Ocultar cualquier SnackBar activo antes de navegar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() => selectedIndex = index);

    if (index == 0) Navigator.pushReplacementNamed(context, '/');
    if (index == 1) Navigator.pushReplacementNamed(context, '/tienda');
    if (index == 2) Navigator.pushReplacementNamed(context, '/chat');
    if (index == 3) Navigator.pushReplacementNamed(context, '/carrito');
  }

  Widget _buildProductLayout() {
    final imageUrl = _getImageUrl();
    final imageHeight = MediaQuery.of(context).size.width * 0.85;
    final bool isAvailable = _isProductAvailable();

    return Stack(
      children: [
        // IMAGEN FIJA
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: imageHeight,
          child: Stack(
            children: [
              Container(
                color: AppColors.background,
                child: imageUrl.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                      )
                    : Image.network(
                        imageUrl,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: imageHeight,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.broken_image,
                              size: 80,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
              ),

              // BADGE "AGOTADO"
              if (!isAvailable)
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade600,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          "AGOTADO",
                          style: AppText.small.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),

        // BOTÓN COMPARTIR
        Positioned(
          top: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share_outlined),
              color: AppColors.purple500,
              iconSize: 24,
              onPressed: _shareProduct,
              tooltip: 'Compartir producto',
            ),
          ),
        ),

        // CONTENIDO SCROLLEABLE
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: imageHeight - 30),
              Container(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildProductInfo(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductInfo() {
    final id = product!["id"];
    final name = product!["name"] ?? "Sin nombre";
    final description = _getDescription();
    final fullDescription = _getFullDescription();
    final priceTaxExcl = double.tryParse(product?["price"] ?? "0") ?? 0;
    final taxRate = _getTaxRateFromGroup();
    final priceTaxIncl = priceTaxExcl * (1 + taxRate / 100);
    final imageUrl = _getImageUrl();
    final bool isAvailable = _isProductAvailable();

    // Determinar si la descripción es larga (más de 150 caracteres)
    final bool hasLongDescription = fullDescription.length > 150;
    final String displayDescription = _isDescriptionExpanded
        ? fullDescription
        : (hasLongDescription
              ? "${fullDescription.substring(0, 150)}..."
              : fullDescription);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de arrastre
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // NOMBRE DEL PRODUCTO
          Text(name, style: AppText.title.copyWith(fontSize: 18, height: 1.3)),

          const SizedBox(height: 15),

          // PRECIO + IVA INCLUIDO
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "${priceTaxIncl.toStringAsFixed(2)} €",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mulish',
                  color: isAvailable
                      ? AppColors.green600
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "IVA incluido",
                style: AppText.small.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),

          // MENSAJE "PRODUCTO NO DISPONIBLE"
          if (!isAvailable)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),

              child: Row(
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    color: Colors.red.shade700,
                    size: 22,
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Producto no disponible",
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Actualmente sin stock. Vuelve a intentarlo más tarde.",
                          style: AppText.small.copyWith(
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),

          // ═══════════════════════════════════════════════
          // DESCRIPCIÓN DEL PRODUCTO
          // ═══════════════════════════════════════════════
          if (description.isNotEmpty) ...[
            _buildDescriptionSection(
              displayDescription: displayDescription,
              hasLongDescription: hasLongDescription,
            ),
          ],
          const SizedBox(height: 20),

          // BOTÓN AÑADIR AL CARRITO
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable && !_isAddingToCart
                    ? AppColors.green600
                    : Colors.grey.shade400,
                foregroundColor: AppColors.white,
                elevation: isAvailable && !_isAddingToCart ? 2 : 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isAddingToCart
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Icon(
                      isAvailable
                          ? Icons.shopping_cart_outlined
                          : Icons.block_outlined,
                      size: 22,
                    ),
              label: Text(
                _isAddingToCart
                    ? "Añadiendo..."
                    : (isAvailable ? "Añadir al carrito" : "No disponible"),
                style: AppText.button.copyWith(fontSize: 17),
              ),
              onPressed: (isAvailable && !_isAddingToCart)
                  ? () => _addToCart(
                      id: id,
                      name: name,
                      priceTaxExcl: priceTaxExcl,
                      priceTaxIncl: priceTaxIncl,
                      taxRate: taxRate,
                      imageUrl: imageUrl,
                    )
                  : null,
            ),
          ),

          const SizedBox(height: 28),

          // TABLA INFORMACIÓN
          _buildInfoTable(),

          const SizedBox(height: 30),

          // SECCIÓN "MÁS PRODUCTOS"
          _buildRelatedProducts(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: SECCIÓN DE DESCRIPCIÓN
  // ═══════════════════════════════════════════════════════════
  Widget _buildDescriptionSection({
    required String displayDescription,
    required bool hasLongDescription,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con icono
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.green600,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                "Descripción",
                style: AppText.subtitle.copyWith(fontSize: 15),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Texto de descripción
          AnimatedCrossFade(
            firstChild: Text(
              displayDescription,
              style: AppText.body.copyWith(
                fontSize: 14,
                color: AppColors.textDark.withOpacity(0.75),
                height: 1.5,
              ),
            ),
            secondChild: Text(
              _getFullDescription(),
              style: AppText.body.copyWith(
                fontSize: 14,
                color: AppColors.textDark.withOpacity(0.75),
                height: 1.5,
              ),
            ),
            crossFadeState: _isDescriptionExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
          ),

          // Botón expandir/contraer
          if (hasLongDescription) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isDescriptionExpanded ? "Ver menos" : "Ver más",
                    style: AppText.small.copyWith(
                      color: AppColors.green600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _isDescriptionExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.green600,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: MÁS PRODUCTOS (CARRUSEL)
  // ═══════════════════════════════════════════════════════════
  Widget _buildRelatedProducts() {
    if (_loadingRelated) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.green500),
        ),
      );
    }

    if (relatedProducts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "MÁS PRODUCTOS",
          style: AppText.subtitle.copyWith(letterSpacing: 0.5),
        ),

        const SizedBox(height: 4),

        Text(
          "Productos de la misma categoría",
          style: AppText.small.copyWith(color: Colors.grey.shade600),
        ),

        const SizedBox(height: 16),

        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: relatedProducts.length,
            itemBuilder: (context, index) {
              final relatedProduct = relatedProducts[index];
              return _buildRelatedProductCard(relatedProduct);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedProductCard(Map<String, dynamic> productData) {
    final int productId = productData["id"] ?? 0;
    final String name = productData["name"] ?? "Sin nombre";
    final String imageUrl = productData["image"] ?? "";

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductPage(id: productId)),
        );
      },
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 140,
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 140,
                      color: AppColors.background,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTable() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.local_shipping_outlined,
            title: "Envío rápido y seguro",
            subtitle: "Recibe tu pedido en 24-48h laborables",
            isFirst: true,
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            title: "Compra 100% segura",
            subtitle: "Tus datos protegidos con encriptación SSL",
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildInfoRow(
            icon: Icons.autorenew_outlined,
            title: "Devolución fácil",
            subtitle: "14 días para devoluciones sin complicaciones",
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String subtitle,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: isFirst ? const Radius.circular(16) : Radius.zero,
          topRight: isFirst ? const Radius.circular(16) : Radius.zero,
          bottomLeft: isLast ? const Radius.circular(16) : Radius.zero,
          bottomRight: isLast ? const Radius.circular(16) : Radius.zero,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.green600, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppText.small.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

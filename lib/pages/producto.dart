import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../data/cart.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_text.dart';
import '../pages/scanner_page.dart';

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

  bool _isDescriptionExpanded = false;

  List<String> _productImages = [];
  int _currentImageIndex = 0;
  final PageController _imagePageController = PageController();

  bool _isAddingToCart = false;

  List<Map<String, dynamic>> relatedProducts = [];
  bool _loadingRelated = true;

  final String baseUrl = "https://www.farmaciaguerrerozieza.com";
  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    await _getProduct();
    await _getStock();
    _loadProductImages();

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

  void _loadProductImages() {
    if (product == null) return;

    List<String> images = [];

    final String idDefaultImage = (product!["id_default_image"] ?? "")
        .toString();
    if (idDefaultImage.isNotEmpty) {
      images.add(_buildImageUrl(idDefaultImage));
    }

    if (product!["associations"] != null &&
        product!["associations"]["images"] != null) {
      final List<dynamic> imageAssociations =
          product!["associations"]["images"];

      for (var img in imageAssociations) {
        final String imgId = (img["id"] ?? "").toString();
        if (imgId.isNotEmpty && imgId != idDefaultImage) {
          images.add(_buildImageUrl(imgId));
        }
      }
    }

    setState(() {
      _productImages = images;
    });
  }

  String _buildImageUrl(String imageId) {
    final digits = imageId.split('');
    final path = digits.join('/');
    return "$baseUrl/img/p/$path/$imageId-large_default.jpg";
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

  void _openImageFullScreen(int initialIndex) {
    if (_productImages.isEmpty) return;

    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: FullScreenImageGallery(
              images: _productImages,
              initialIndex: initialIndex,
              productName: product?["name"] ?? "Producto",
            ),
          );
        },
      ),
    );
  }

  String _getDescription() {
    if (product == null) return "";

    String description = "";

    final descShort = product!["description_short"];
    final descFull = product!["description"];

    if (descShort != null && descShort.toString().isNotEmpty) {
      description = descShort.toString();
    } else if (descFull != null && descFull.toString().isNotEmpty) {
      description = descFull.toString();
    }

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

  String _stripHtml(String htmlText) {
    if (htmlText.isEmpty) return "";

    String text = htmlText
        .replaceAll(RegExp(r'<br\s*/?>'), '\n')
        .replaceAll(RegExp(r'<p[^>]*>'), '\n')
        .replaceAll(RegExp(r'</p>'), '\n');

    text = text.replaceAll(RegExp(r'<[^>]*>'), '');

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

    text = text
        .replaceAll(RegExp(r' +'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    return text;
  }

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
          content: AutoText(
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

  Future<void> _addToCart({
    required dynamic id,
    required String name,
    required double priceTaxExcl,
    required double priceTaxIncl,
    required double taxRate,
    required String imageUrl,
  }) async {
    if (_isAddingToCart) return;

    setState(() => _isAddingToCart = true);

    try {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AutoText(
                            "¡Añadido al carrito!",
                            style: AppText.body.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          AutoText(
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
                Row(
                  children: [
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
                              const Icon(
                                Icons.shopping_bag_outlined,
                                color: AppColors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              AutoText(
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
                              AutoText(
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

      await Future.delayed(const Duration(seconds: 2));
    } catch (e) {
      debugPrint("Error añadiendo al carrito: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.white),
                const SizedBox(width: 10),
                AutoText(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      extendBody: true,
      body: SafeArea(
        bottom: false,
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
        onScanTap: _openScanner,
      ),
    );
  }

  void onFooterTap(int index) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    setState(() => selectedIndex = index);

    if (index == 0) Navigator.pushReplacementNamed(context, '/');
    if (index == 1) Navigator.pushReplacementNamed(context, '/tienda');
    if (index == 2) Navigator.pushReplacementNamed(context, '/chat');
    if (index == 3) Navigator.pushReplacementNamed(context, '/carrito');
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // LAYOUT PRINCIPAL - IMAGEN SEPARADA DEL SCROLL
  // ═══════════════════════════════════════════════════════════
  // ═══════════════════════════════════════════════════════════
  // LAYOUT PRINCIPAL - MODIFICADO CON DRAGGABLE SHEET
  // ═══════════════════════════════════════════════════════════
  Widget _buildProductLayout() {
    // Calculamos el tamaño basado en la pantalla para configurar el sheet
    return LayoutBuilder(
      builder: (context, constraints) {
        final double screenHeight = constraints.maxHeight;
        final double screenWidth = MediaQuery.of(context).size.width;

        // Altura de la imagen (manteniendo tu ratio 0.75)
        final double imageHeight = screenWidth * 0.75;

        // Calculamos qué porcentaje de la pantalla ocupa la imagen
        // para saber dónde debe empezar la hoja de información.
        // Restamos unos 24px para que la hoja "muerda" un poco la imagen (efecto redondeado)
        double initialSheetPct =
            (screenHeight - imageHeight + 24) / screenHeight;

        // Limites de seguridad para evitar errores si la pantalla es muy rara
        if (initialSheetPct < 0.2) initialSheetPct = 0.2;
        if (initialSheetPct > 0.9) initialSheetPct = 0.9;

        final bool isAvailable = _isProductAvailable();

        return Stack(
          children: [
            // ---------------------------------------------------------
            // CAPA 1: IMÁGENES (Fondo interactivo)
            // ---------------------------------------------------------
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: imageHeight,
              child: Stack(
                children: [
                  // PAGEVIEW DE IMÁGENES
                  _productImages.isEmpty
                      ? Container(
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey,
                            ),
                          ),
                        )
                      : PageView.builder(
                          controller: _imagePageController,
                          itemCount: _productImages.length,
                          onPageChanged: (index) {
                            setState(() => _currentImageIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _openImageFullScreen(index),
                              child: Container(
                                color: AppColors.background,
                                child: Image.network(
                                  _productImages[index],
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            color: AppColors.green500,
                                            strokeWidth: 2,
                                          ),
                                        );
                                      },
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
                            );
                          },
                        ),

                  // Indicador de página (dots)
                  if (_productImages.length > 1)
                    Positioned(
                      bottom:
                          30, // Un poco más arriba para que no lo tape el borde redondeado
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          _productImages.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentImageIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentImageIndex == index
                                  ? AppColors.green600
                                  : Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),

                  // Contador de imágenes
                  if (_productImages.length > 1)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_library_outlined,
                              color: AppColors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${_currentImageIndex + 1}/${_productImages.length}",
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // BOTÓN AMPLIAR
                  if (_productImages.isNotEmpty)
                    Positioned(
                      bottom: 30, // Elevado para evitar solapamiento inicial
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _openImageFullScreen(_currentImageIndex),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.green600,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.zoom_in_rounded,
                            color: AppColors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ),

                  // BADGE "AGOTADO"
                  if (!isAvailable)
                    Positioned(
                      top: 12,
                      right: 60,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          "AGOTADO",
                          style: TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ---------------------------------------------------------
            // CAPA 2: HOJA DESLIZANTE (Información)
            // ---------------------------------------------------------
            DraggableScrollableSheet(
              initialChildSize: initialSheetPct,
              minChildSize: initialSheetPct,
              maxChildSize: 1.0,
              builder: (BuildContext context, ScrollController scrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  // Importante: Pasamos el scrollController para que el Drag funcione
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const ClampingScrollPhysics(), // Scroll más firme
                    child: _buildProductInfo(),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTENIDO SCROLLEABLE (Sin cambios lógicos, solo visuales)
  // ═══════════════════════════════════════════════════════════
  Widget _buildProductInfo() {
    // ... Tus variables actuales ...
    final id = product!["id"];
    final name = product!["name"] ?? "Sin nombre";
    final description = _getDescription();
    final fullDescription = _getFullDescription();
    final priceTaxExcl = double.tryParse(product?["price"] ?? "0") ?? 0;
    final taxRate = _getTaxRateFromGroup();
    final priceTaxIncl = priceTaxExcl * (1 + taxRate / 100);
    final imageUrl = _productImages.isNotEmpty ? _productImages[0] : "";
    final bool isAvailable = _isProductAvailable();

    final bool hasLongDescription = fullDescription.length > 150;
    final String displayDescription = _isDescriptionExpanded
        ? fullDescription
        : (hasLongDescription
              ? "${fullDescription.substring(0, 150)}..."
              : fullDescription);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Indicador de arrastre
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20, top: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // NOMBRE DEL PRODUCTO
          AutoText(
            name,
            style: AppText.title.copyWith(fontSize: 18, height: 1.3),
          ),

          // ... EL RESTO DEL CÓDIGO DE ESTA FUNCIÓN SE MANTIENE IGUAL ...
          const SizedBox(height: 12),
          // (Copia aquí el resto del contenido de tu función original _buildProductInfo
          //  desde donde muestra el precio hasta el final)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              AutoText(
                "${priceTaxIncl.toStringAsFixed(2)} €",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Mulish',
                  color: isAvailable
                      ? AppColors.green600
                      : Colors.grey.shade500,
                ),
              ),
              const SizedBox(width: 10),
              AutoText(
                "IVA incluido",
                style: AppText.small.copyWith(color: Colors.grey.shade600),
              ),
            ],
          ),

          // MENSAJE "PRODUCTO NO DISPONIBLE"
          if (!isAvailable) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.remove_shopping_cart_outlined,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AutoText(
                      "Producto no disponible actualmente",
                      style: AppText.small.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // BOTÓN AÑADIR AL CARRITO
          SizedBox(
            width: double.infinity,
            height: 52,
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
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      isAvailable
                          ? Icons.shopping_cart_outlined
                          : Icons.block_outlined,
                      size: 20,
                    ),
              label: AutoText(
                _isAddingToCart
                    ? "Añadiendo..."
                    : (isAvailable ? "Añadir al carrito" : "No disponible"),
                style: AppText.button.copyWith(fontSize: 16),
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

          const SizedBox(height: 24),

          // DESCRIPCIÓN
          if (description.isNotEmpty) ...[
            _buildDescriptionSection(
              displayDescription: displayDescription,
              hasLongDescription: hasLongDescription,
            ),
            const SizedBox(height: 20),
          ],

          // TABLA INFO
          _buildInfoTable(),

          const SizedBox(height: 24),

          // MÁS PRODUCTOS
          _buildRelatedProducts(),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection({
    required String displayDescription,
    required bool hasLongDescription,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.description_outlined,
                  color: AppColors.green600,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              AutoText(
                "Descripción",
                style: AppText.subtitle.copyWith(fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AutoText(
            _isDescriptionExpanded ? _getFullDescription() : displayDescription,
            style: AppText.body.copyWith(
              fontSize: 13,
              color: AppColors.textDark.withOpacity(0.75),
              height: 1.5,
            ),
          ),
          if (hasLongDescription) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = !_isDescriptionExpanded;
                });
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AutoText(
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
                    size: 18,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

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
        AutoText(
          "MÁS PRODUCTOS",
          style: AppText.subtitle.copyWith(fontSize: 14, letterSpacing: 0.5),
        ),
        const SizedBox(height: 4),
        AutoText(
          "Productos de la misma categoría",
          style: AppText.small.copyWith(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 200,
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
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
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
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              size: 36,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      height: 120,
                      color: AppColors.background,
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          size: 36,
                          color: Colors.grey,
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AutoText(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.small.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.local_shipping_outlined,
            title: "Envío rápido",
            subtitle: "24-48h laborables",
            isFirst: true,
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildInfoRow(
            icon: Icons.verified_user_outlined,
            title: "Compra segura",
            subtitle: "Datos protegidos",
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          _buildInfoRow(
            icon: Icons.autorenew_outlined,
            title: "Devolución fácil",
            subtitle: "14 días",
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.green600, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AutoText(
                title,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              AutoText(
                subtitle,
                style: AppText.small.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: GALERÍA DE IMÁGENES A PANTALLA COMPLETA
// ═══════════════════════════════════════════════════════════════════════════════
class FullScreenImageGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String productName;

  const FullScreenImageGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.productName,
  });

  @override
  State<FullScreenImageGallery> createState() => _FullScreenImageGalleryState();
}

class _FullScreenImageGalleryState extends State<FullScreenImageGallery> {
  late PageController _pageController;
  late int _currentIndex;
  late TransformationController _transformationController;
  bool _showUI = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _transformationController = TransformationController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _resetZoom() {
    _transformationController.value = Matrix4.identity();
  }

  void _toggleUI() {
    setState(() {
      _showUI = !_showUI;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleUI,
        child: Stack(
          children: [
            // GALERÍA CON ZOOM
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (index) {
                _resetZoom();
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  transformationController: index == _currentIndex
                      ? _transformationController
                      : null,
                  minScale: 1.0,
                  maxScale: 5.0,
                  panEnabled: true,
                  scaleEnabled: true,
                  child: Center(
                    child: Image.network(
                      widget.images[index],
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppColors.green500,
                          ),
                        );
                      },
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
                );
              },
            ),

            // HEADER
            if (_showUI)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.productName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            "${_currentIndex + 1}/${widget.images.length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // CONTROLES INFERIORES
            if (_showUI)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.7),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pinch_outlined,
                              color: Colors.white.withOpacity(0.7),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Pellizca para zoom",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        if (widget.images.length > 1) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.images.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                ),
                                width: _currentIndex == index ? 20 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _currentIndex == index
                                      ? AppColors.green500
                                      : Colors.white.withOpacity(0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),

            // BOTÓN RESETEAR ZOOM
            if (_showUI)
              Positioned(
                right: 16,
                bottom: MediaQuery.of(context).size.height * 0.4,
                child: GestureDetector(
                  onTap: _resetZoom,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.fit_screen_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

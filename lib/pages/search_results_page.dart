import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';
import 'producto.dart';
import '../pages/scanner_page.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;

  const SearchResultsPage({super.key, required this.query});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  String _searchText = '';
  bool _isLoading = true;
  bool _error = false;
  int selectedIndex = 1;

  // Control de paginación
  int _visibleCount = 10;
  static const int _loadMoreStep = 10;

  final String baseUrl = "https://www.farmaciaguerrerozieza.com";
  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";

  @override
  void initState() {
    super.initState();
    _searchText = widget.query;
    _searchController.text = widget.query;
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // CARGAR TODOS LOS PRODUCTOS Y SU STOCK
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = false;
    });

    try {
      // ════════════════════════════════════════════════════════
      // PASO 1: Cargar todos los stocks disponibles
      // ════════════════════════════════════════════════════════
      Map<int, int> stockMap = {};

      final stockUrl = Uri.parse(
        "$baseUrl/api/stock_availables?ws_key=$apiKey&output_format=JSON&display=[id_product,quantity]",
      );

      final stockResponse = await http.get(stockUrl);

      if (stockResponse.statusCode == 200) {
        final stockData = jsonDecode(stockResponse.body);
        final List stocks = stockData["stock_availables"] ?? [];

        for (var stock in stocks) {
          final productId =
              int.tryParse(stock["id_product"]?.toString() ?? "0") ?? 0;
          final quantity =
              int.tryParse(stock["quantity"]?.toString() ?? "0") ?? 0;

          // Guardamos el stock (suma si hay múltiples entradas por producto)
          if (stockMap.containsKey(productId)) {
            stockMap[productId] = stockMap[productId]! + quantity;
          } else {
            stockMap[productId] = quantity;
          }
        }
      }

      // ════════════════════════════════════════════════════════
      // PASO 2: Cargar todos los productos
      // ════════════════════════════════════════════════════════
      final url = Uri.parse(
        "$baseUrl/api/products?ws_key=$apiKey&output_format=JSON&display=[id,name,price,id_default_image,id_tax_rules_group]&filter[active]=1&limit=500",
      );

      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List products = decoded["products"] ?? [];

        List<Map<String, dynamic>> results = [];

        for (var product in products) {
          final int id = int.tryParse(product["id"].toString()) ?? 0;
          final String name = _extractName(product["name"]);

          double price = 0.0;
          if (product["price"] is String) {
            price = double.tryParse(product["price"]) ?? 0.0;
          } else if (product["price"] is num) {
            price = product["price"].toDouble();
          }

          // Calcular IVA
          final taxGroupId = product["id_tax_rules_group"]?.toString() ?? "0";
          double taxRate = 0;
          switch (taxGroupId) {
            case "1":
              taxRate = 4;
              break;
            case "2":
              taxRate = 10;
              break;
            case "3":
              taxRate = 21;
              break;
          }
          final double priceWithTax = price * (1 + taxRate / 100);

          final String imageId = product["id_default_image"]?.toString() ?? "";
          String imageUrl = _buildImageUrl(imageId);

          // ════════════════════════════════════════════════════════
          // OBTENER DISPONIBILIDAD DEL STOCK
          // ════════════════════════════════════════════════════════
          final int stockQuantity = stockMap[id] ?? 0;
          final bool isAvailable = stockQuantity > 0;

          results.add({
            "id": id,
            "name": name,
            "price": priceWithTax,
            "image": imageUrl,
            "isAvailable": isAvailable,
            "stockQuantity": stockQuantity,
          });
        }

        setState(() {
          _allProducts = results;
          _isLoading = false;
        });

        // Aplicar filtro inicial
        _applyFilter();
      } else {
        setState(() {
          _error = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error cargando productos: $e");
      setState(() {
        _error = true;
        _isLoading = false;
      });
    }
  }

  String _extractName(dynamic name) {
    if (name == null) return "Sin nombre";
    if (name is String) return name;
    if (name is Map) {
      if (name['language'] is List && (name['language'] as List).isNotEmpty) {
        return name['language'][0]['value']?.toString() ?? "Sin nombre";
      }
      if (name['language'] is Map) {
        return name['language']['value']?.toString() ?? "Sin nombre";
      }
    }
    return name.toString();
  }

  String _buildImageUrl(String imageId) {
    if (imageId.isEmpty) return "";
    final digits = imageId.split('');
    final path = digits.join('/');
    return "$baseUrl/img/p/$path/$imageId-home_default.jpg";
  }

  // ═══════════════════════════════════════════════════════════
  // FILTRAR PRODUCTOS LOCALMENTE
  // ═══════════════════════════════════════════════════════════
  void _applyFilter() {
    if (_searchText.isEmpty) {
      setState(() {
        _filteredProducts = [];
        _visibleCount = 10;
      });
      return;
    }

    final queryLower = _searchText.toLowerCase().trim();
    final filtered = _allProducts.where((p) {
      final name = (p["name"] ?? "").toString().toLowerCase();
      return name.contains(queryLower);
    }).toList();

    setState(() {
      _filteredProducts = filtered;
      _visibleCount = min(10, filtered.length);
    });
  }

  void _onSearchChanged(String query) {
    setState(() => _searchText = query);
    _applyFilter();
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _filteredProducts = [];
      _visibleCount = 10;
    });
  }

  void _resetToOriginalSearch() {
    _searchController.text = widget.query;
    setState(() => _searchText = widget.query);
    _applyFilter();
  }

  // ═══════════════════════════════════════════════════════════
  // NAVEGACIÓN FOOTER
  // ═══════════════════════════════════════════════════════════
  void onFooterTap(int index) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() => selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/tienda');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/carrito');
        break;
    }
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),

            // BARRA SUPERIOR
            _buildTopBar(),

            // INFO DE RESULTADOS
            if (!_isLoading && !_error && _searchText.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: _buildResultsInfo(),
              ),

            // CONTENIDO
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : _error
                  ? _buildErrorState()
                  : _filteredProducts.isEmpty
                  ? _buildEmptyState()
                  : _buildProductList(),
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

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BARRA SUPERIOR
  // ═══════════════════════════════════════════════════════════
  Widget _buildTopBar() {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: AppColors.green600,
                    size: 25,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Resultados de búsqueda",
                      style: AppText.subtitle.copyWith(fontSize: 16),
                    ),
                    if (!_isLoading)
                      Text(
                        "${_filteredProducts.length} producto${_filteredProducts.length != 1 ? 's' : ''} encontrado${_filteredProducts.length != 1 ? 's' : ''}",
                        style: AppText.small.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildSearchBar(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BARRA DE BÚSQUEDA
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _onSearchChanged,
        style: AppText.body.copyWith(fontSize: 15),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre...',
          hintStyle: AppText.body.copyWith(
            color: AppColors.textDark.withOpacity(0.4),
            fontSize: 15,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.green500,
          ),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.textDark.withOpacity(0.4),
                  ),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppColors.background,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: INFO DE RESULTADOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildResultsInfo() {
    final hasModifiedSearch = _searchText != widget.query;

    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: hasModifiedSearch ? AppColors.purple500 : AppColors.green500,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            hasModifiedSearch
                ? "${_filteredProducts.length} resultado${_filteredProducts.length != 1 ? 's' : ''} para \"$_searchText\""
                : "Mostrando ${min(_visibleCount, _filteredProducts.length)} de ${_filteredProducts.length}",
            style: AppText.small.copyWith(
              color: AppColors.textDark.withOpacity(0.6),
            ),
          ),
        ),
        if (hasModifiedSearch)
          GestureDetector(
            onTap: _resetToOriginalSearch,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.purple100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: AppColors.purple600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    "Restaurar",
                    style: AppText.small.copyWith(
                      color: AppColors.purple600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADOS: LOADING, ERROR, EMPTY
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: AppColors.green500,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            "Buscando productos...",
            style: AppText.body.copyWith(
              color: AppColors.textDark.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 20),
            Text("Error de conexión", style: AppText.subtitle),
            const SizedBox(height: 8),
            Text(
              "No pudimos cargar los productos",
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green500,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text("Reintentar"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.purple50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 48,
                color: AppColors.purple400,
              ),
            ),
            const SizedBox(height: 20),
            Text("Sin resultados", style: AppText.subtitle),
            const SizedBox(height: 8),
            Text(
              _searchText.isEmpty
                  ? "Escribe algo para buscar"
                  : "No encontramos productos que coincidan con\n\"$_searchText\"",
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple500,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text("Volver"),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: LISTA DE PRODUCTOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildProductList() {
    final visibleProducts = _filteredProducts.take(_visibleCount).toList();
    final hasMore = _visibleCount < _filteredProducts.length;

    return RefreshIndicator(
      onRefresh: _loadProducts,
      color: AppColors.green500,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final product = visibleProducts[index];
                return _ProductCard(
                  id: product["id"].toString(),
                  name: product["name"] ?? "",
                  price: product["price"].toString(),
                  image: product["image"] ?? "",
                  isAvailable: product["isAvailable"] ?? true,
                );
              }, childCount: visibleProducts.length),
            ),
          ),
          if (hasMore) SliverToBoxAdapter(child: _buildLoadMoreButton()),
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BOTÓN "VER MÁS"
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadMoreButton() {
    final remaining = _filteredProducts.length - _visibleCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.green200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              setState(() {
                _visibleCount = min(
                  _visibleCount + _loadMoreStep,
                  _filteredProducts.length,
                );
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.green600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Ver más productos",
                    style: AppText.body.copyWith(
                      color: AppColors.green600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.green100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "+$remaining",
                      style: AppText.small.copyWith(
                        color: AppColors.green600,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: TARJETA DE PRODUCTO CON BADGE DE AGOTADO
// ═══════════════════════════════════════════════════════════════════════════════
class _ProductCard extends StatefulWidget {
  final String id;
  final String name;
  final String price;
  final String image;
  final bool isAvailable;

  const _ProductCard({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    this.isAvailable = true,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double priceValue = double.tryParse(widget.price) ?? 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        final id = int.tryParse(widget.id);
        if (id != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ProductPage(id: id)),
          );
        }
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ═══════════════════════════════════════════════
              // IMAGEN CON BADGE DE AGOTADO
              // ═══════════════════════════════════════════════
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Stack(
                    children: [
                      // Imagen del producto
                      Container(
                        width: double.infinity,
                        color: AppColors.background,
                        child: widget.image.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.image,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.green500,
                                    strokeWidth: 2,
                                  ),
                                ),
                                errorWidget: (_, __, ___) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    size: 32,
                                    color: Colors.grey,
                                  ),
                                ),
                              )
                            : const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 32,
                                  color: Colors.grey,
                                ),
                              ),
                      ),

                      // ═══════════════════════════════════════════════
                      // BADGE "AGOTADO"
                      // ═══════════════════════════════════════════════
                      if (!widget.isAvailable)
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.shade600,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
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
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "AGOTADO",
                                  style: AppText.small.copyWith(
                                    color: AppColors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 9,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ═══════════════════════════════════════════════
              // INFORMACIÓN DEL PRODUCTO
              // ═══════════════════════════════════════════════
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          widget.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.small.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.2,
                            // Atenuar texto si está agotado
                            color: widget.isAvailable
                                ? AppColors.textDark
                                : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      if (priceValue > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${priceValue.toStringAsFixed(2)} €",
                              style: AppText.body.copyWith(
                                fontSize: 14,
                                // Color condicional según disponibilidad
                                color: widget.isAvailable
                                    ? AppColors.green600
                                    : Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                // Color de fondo condicional
                                color: widget.isAvailable
                                    ? AppColors.green50
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                // Color del icono condicional
                                color: widget.isAvailable
                                    ? AppColors.green600
                                    : Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

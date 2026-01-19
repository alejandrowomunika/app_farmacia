import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import '../theme/app_theme.dart';
import '../pages/producto.dart';
import '../pages/search_results_page.dart';
import '../pages/category.dart';
import '../pages/scanner_page.dart';

class SearchDrawer extends StatefulWidget {
  const SearchDrawer({super.key});

  @override
  State<SearchDrawer> createState() => _SearchDrawerState();
}

class _SearchDrawerState extends State<SearchDrawer> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  // ═══════════════════════════════════════════════════════════
  // PRODUCTOS
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  // ═══════════════════════════════════════════════════════════
  // ABRIR ESCÁNER
  // ═══════════════════════════════════════════════════════════
  void _openScanner() {
    Navigator.pop(context); // Cerrar drawer
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CATEGORÍAS
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> _allCategories = [];
  List<Map<String, dynamic>> _filteredCategories = [];

  String _searchText = '';
  bool _isLoading = false;
  bool _hasLoadedData = false;

  // ═══════════════════════════════════════════════════════════
  // MAPA DE STOCKS
  // ═══════════════════════════════════════════════════════════
  Map<int, int> _stockMap = {};

  // Control de paginación dentro del drawer
  int _visibleProductCount = 10;
  static const int _loadMoreStep = 5;

  final String baseUrl = "https://www.farmaciaguerrerozieza.com";
  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // CARGAR CATEGORÍAS
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadCategories() async {
    try {
      final url = Uri.parse(
        '$baseUrl/api/categories?ws_key=$apiKey&output_format=JSON&display=[id,name,id_parent]&filter[id_parent]=2&filter[active]=1',
      );

      final resp = await http.get(url).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final jsonData = jsonDecode(resp.body);

        List<dynamic>? items;

        if (jsonData is Map<String, dynamic>) {
          if (jsonData.containsKey('categories')) {
            final c = jsonData['categories'];
            if (c is Map && c.containsKey('category')) {
              items = c['category'] as List<dynamic>?;
            } else if (c is List) {
              items = c;
            }
          } else if (jsonData.containsKey('category')) {
            items = jsonData['category'] as List<dynamic>?;
          }
        }

        items ??= [];

        final List<Map<String, dynamic>> parsed = [];

        for (final it in items) {
          if (it is Map<String, dynamic>) {
            final id = (it['id'] ?? it['id_category'] ?? it['category_id'])
                ?.toString();
            var name = it['name'] ?? it['category_name'];

            // Manejar nombre multilenguaje
            if (name is Map && name['language'] is List) {
              name = name['language'][0]['value'] ?? 'Categoría';
            }

            if (id != null) {
              final jpg = '$baseUrl/img/c/$id.jpg';
              final png = '$baseUrl/img/c/$id.png';

              parsed.add({
                'id': id,
                'name': name is String ? name : name.toString(),
                'imageJpg': jpg,
                'imagePng': png,
              });
            }
          }
        }

        _allCategories = parsed;
        debugPrint('✅ Categorías cargadas: ${_allCategories.length}');
      }
    } catch (e) {
      debugPrint('❌ Error cargando categorías: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CARGAR STOCKS
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadStocks() async {
    try {
      final stockUrl = Uri.parse(
        "$baseUrl/api/stock_availables?ws_key=$apiKey&output_format=JSON&display=[id_product,quantity]",
      );

      final stockResponse = await http
          .get(stockUrl)
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (stockResponse.statusCode == 200) {
        final stockData = jsonDecode(stockResponse.body);
        final List stocks = stockData["stock_availables"] ?? [];

        Map<int, int> tempStockMap = {};

        for (var stock in stocks) {
          final productId =
              int.tryParse(stock["id_product"]?.toString() ?? "0") ?? 0;
          final quantity =
              int.tryParse(stock["quantity"]?.toString() ?? "0") ?? 0;

          if (tempStockMap.containsKey(productId)) {
            tempStockMap[productId] = tempStockMap[productId]! + quantity;
          } else {
            tempStockMap[productId] = quantity;
          }
        }

        _stockMap = tempStockMap;
        debugPrint('✅ Stocks cargados: ${_stockMap.length} productos');
      }
    } catch (e) {
      debugPrint('❌ Error cargando stocks: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CARGAR PRODUCTOS
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadProducts() async {
    try {
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
          String imageUrl = _buildImageUrl(id, imageId);

          final int stockQuantity = _stockMap[id] ?? 0;
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

        _allProducts = results;
        debugPrint('✅ Productos cargados: ${_allProducts.length}');
      }
    } catch (e) {
      debugPrint("❌ Error cargando productos: $e");
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CARGAR TODOS LOS DATOS
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadDataIfNeeded() async {
    if (_hasLoadedData) return;

    setState(() => _isLoading = true);

    try {
      // Cargar todo en paralelo
      await Future.wait([_loadCategories(), _loadStocks()]);

      // Cargar productos después de tener los stocks
      await _loadProducts();

      setState(() {
        _hasLoadedData = true;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error cargando datos: $e");
      setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // EXTRAER NOMBRE (MANEJA FORMATO MULTILENGUAJE)
  // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════
  // CONSTRUIR URL DE IMAGEN
  // ═══════════════════════════════════════════════════════════
  String _buildImageUrl(int productId, String imageId) {
    if (imageId.isEmpty) return "";

    final digits = imageId.split('');
    final path = digits.join('/');
    return "$baseUrl/img/p/$path/$imageId-home_default.jpg";
  }

  // ═══════════════════════════════════════════════════════════
  // FILTRAR PRODUCTOS Y CATEGORÍAS
  // ═══════════════════════════════════════════════════════════
  void _filterAll(String query) async {
    setState(() {
      _searchText = query;
      _visibleProductCount = 5;
    });

    if (!_hasLoadedData && query.length >= 2) {
      await _loadDataIfNeeded();
    }

    if (query.length < 2) {
      setState(() {
        _filteredProducts = [];
        _filteredCategories = [];
      });
      return;
    }

    final queryLower = query.toLowerCase().trim();

    // Filtrar categorías
    final filteredCats = _allCategories.where((c) {
      final name = (c["name"] ?? "").toString().toLowerCase();
      return name.contains(queryLower);
    }).toList();

    // Filtrar productos
    final filteredProds = _allProducts.where((p) {
      final name = (p["name"] ?? "").toString().toLowerCase();
      return name.contains(queryLower);
    }).toList();

    setState(() {
      _filteredCategories = filteredCats;
      _filteredProducts = filteredProds;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _filteredProducts = [];
      _filteredCategories = [];
      _visibleProductCount = 5;
    });
    _searchFocusNode.requestFocus();
  }

  void _loadMore() {
    setState(() {
      _visibleProductCount = min(
        _visibleProductCount + _loadMoreStep,
        _filteredProducts.length,
      );
    });
  }

  void _goToSearchResults() {
    if (_searchText.trim().isEmpty) return;

    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchResultsPage(query: _searchText.trim()),
      ),
    );
  }

  void _goToProduct(int productId) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductPage(id: productId)),
    );
  }

  void _goToCategory(Map<String, dynamic> category) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryPage(
          category: {
            'id': category['id'],
            'label': category['name'],
            'icon': Icons.category_outlined,
            'bg': AppColors.white,
            'color': AppColors.green600,
            'imageJpg': category['imageJpg'],
            'imagePng': category['imagePng'],
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenWidth * 0.88,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              bottomLeft: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildSearchBar(),
                const SizedBox(height: 12),

                Expanded(child: _buildSearchResults()),
                if (_filteredProducts.isNotEmpty ||
                    _filteredCategories.isNotEmpty)
                  _buildSearchAllButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icono y título
          Row(
            children: [
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Buscar", style: AppText.title.copyWith(fontSize: 18)),
                  Text(
                    "Categorías y productos",
                    style: AppText.small.copyWith(color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),

          // Botones: Escáner + Cerrar
          Row(
            children: [
              // ═══════════════════════════════════════
              // BOTÓN CERRAR
              // ═══════════════════════════════════════
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: Colors.grey.shade600,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BARRA DE BÚSQUEDA
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ═══════════════════════════════════════
            // CAMPO DE BÚSQUEDA
            // ═══════════════════════════════════════
            Expanded(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                onChanged: _filterAll,
                onSubmitted: (_) => _goToSearchResults(),
                style: AppText.body.copyWith(fontSize: 15),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar categorías o productos...',
                  hintStyle: AppText.body.copyWith(
                    color: AppColors.textDark.withOpacity(0.4),
                    fontSize: 15,
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
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: RESULTADOS DE BÚSQUEDA
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchResults() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: AppColors.green500,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            Text(
              "Cargando...",
              style: AppText.body.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    if (_searchText.length < 2) {
      return _buildInitialState();
    }

    if (_filteredCategories.isEmpty && _filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    final visibleProducts = _filteredProducts
        .take(_visibleProductCount)
        .toList();
    final hasMoreProducts = _visibleProductCount < _filteredProducts.length;

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        // ═══════════════════════════════════════════════
        // SECCIÓN: CATEGORÍAS
        // ═══════════════════════════════════════════════
        if (_filteredCategories.isNotEmpty) ...[
          _buildSectionHeader(
            icon: Icons.category_rounded,
            title: "Categorías",
            count: _filteredCategories.length,
            color: AppColors.purple500,
          ),
          const SizedBox(height: 15),
          ..._filteredCategories.map((cat) => _buildCategoryTile(cat)),
          const SizedBox(height: 25),
        ],
        const SizedBox(width: 8),
        // ═══════════════════════════════════════════════
        // SECCIÓN: PRODUCTOS
        // ═══════════════════════════════════════════════
        if (_filteredProducts.isNotEmpty) ...[
          _buildSectionHeader(
            icon: Icons.inventory_2_rounded,
            title: "Productos",
            count: _filteredProducts.length,
            color: AppColors.purple500,
          ),
          const SizedBox(height: 15),
          ...visibleProducts.map((prod) => _buildProductTile(prod)),
          if (hasMoreProducts) _buildLoadMoreButton(),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: HEADER DE SECCIÓN
  // ═══════════════════════════════════════════════════════════
  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required int count,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: AppText.body.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              "$count",
              style: AppText.small.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: ESTADO INICIAL
  // ═══════════════════════════════════════════════════════════
  Widget _buildInitialState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.purple50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search_rounded,
                size: 40,
                color: AppColors.purple400,
              ),
            ),
            const SizedBox(height: 20),
            Text("Busca en la tienda", style: AppText.subtitle),
            const SizedBox(height: 8),
            Text(
              "Escribe al menos 2 caracteres\npara buscar categorías y productos",
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                color: AppColors.textDark.withOpacity(0.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: ESTADO VACÍO
  // ═══════════════════════════════════════════════════════════
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
              "No encontramos categorías ni productos\ncon \"$_searchText\"",
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                color: AppColors.textDark.withOpacity(0.5),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _clearSearch,
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
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Nueva búsqueda"),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: CATEGORÍA EN LISTA
  // ═══════════════════════════════════════════════════════════
  Widget _buildCategoryTile(Map<String, dynamic> category) {
    final String name = category["name"] ?? "Categoría";
    final String? imageJpg = category["imageJpg"];
    final String? imagePng = category["imagePng"];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _goToCategory(category),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green500.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icono de categoría
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.green100, AppColors.green50],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: _buildCategoryIcon(imageJpg, imagePng),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Nombre y etiqueta
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                // Flecha
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.green50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.green500,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String? imageJpg, String? imagePng) {
    if (imageJpg == null || imageJpg.isEmpty) {
      return const Icon(
        Icons.category_outlined,
        size: 24,
        color: AppColors.purple600,
      );
    }

    return CachedNetworkImage(
      imageUrl: imageJpg,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Icon(
        Icons.category_outlined,
        size: 24,
        color: AppColors.purple400,
      ),
      errorWidget: (_, __, ___) {
        if (imagePng != null && imagePng.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: imagePng,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const Icon(
              Icons.category_outlined,
              size: 24,
              color: AppColors.purple600,
            ),
          );
        }
        return const Icon(
          Icons.category_outlined,
          size: 24,
          color: AppColors.purple600,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: PRODUCTO EN LISTA
  // ═══════════════════════════════════════════════════════════
  Widget _buildProductTile(Map<String, dynamic> product) {
    final int id = product["id"] ?? 0;
    final String name = product["name"] ?? "";
    final double price = product["price"] ?? 0.0;
    final String imageUrl = product["image"] ?? "";
    final bool isAvailable = product["isAvailable"] ?? true;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _goToProduct(id),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Imagen con badge
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: AppColors.background,
                        child: imageUrl.isNotEmpty
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: Colors.grey.shade400,
                                    size: 24,
                                  ),
                                ),
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  color: Colors.grey.shade400,
                                  size: 24,
                                ),
                              ),
                      ),
                    ),
                    if (!isAvailable)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            color: AppColors.white,
                            size: 10,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.2,
                          color: isAvailable
                              ? AppColors.textDark
                              : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "${price.toStringAsFixed(2)} €",
                        style: AppText.body.copyWith(
                          color: isAvailable
                              ? AppColors.green600
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Badge agotado
                if (!isAvailable)
                  Container(
                    margin: const EdgeInsets.only(left: 8, right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.red.shade200, width: 1),
                    ),
                    child: Text(
                      "Agotado",
                      style: AppText.small.copyWith(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                  ),

                // Flecha
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? AppColors.green50
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: isAvailable
                        ? AppColors.green500
                        : Colors.grey.shade400,
                    size: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BOTÓN "VER MÁS"
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadMoreButton() {
    final remaining = _filteredProducts.length - _visibleProductCount;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.green200, width: 1.5),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _loadMore,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
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

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BOTÓN "VER TODOS"
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchAllButton() {
    final totalResults = _filteredCategories.length + _filteredProducts.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _goToSearchResults,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green600,
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: const Icon(Icons.search_rounded, size: 20),
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Ver todos los resultados",
                style: AppText.button.copyWith(fontSize: 15),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "$totalResults",
                  style: AppText.small.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
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

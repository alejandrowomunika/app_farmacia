import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';
import 'producto.dart';

class CategoryPage extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // ─────────────────────────────────────────────────────────
  // VARIABLES DE ESTADO
  // ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _loading = true;
  bool _error = false;
  int _visibleCount = 8;
  String _searchText = '';

  // ═══════════════════════════════════════════════════════════
  // NUEVO: SUBCATEGORÍAS Y FILTROS
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> _subcategories = [];
  Map<String, List<String>> _subcategoryDescendants =
      {}; // Mapa de subcategoría -> todos sus descendientes
  String? _selectedSubcategoryId; // null = "Todas"
  bool _loadingSubcategories = true;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _subcategoryScrollController = ScrollController();

  final String _apiKey = 'CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS';
  final String _baseUrl = 'https://www.farmaciaguerrerozieza.com/api';
  final int _maxProducts = 700;

  int selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _subcategoryScrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    await Future.wait([_fetchSubcategories(), _fetchProducts()]);
  }

  // ─────────────────────────────────────────────────────────
  // NAVEGACIÓN FOOTER
  // ─────────────────────────────────────────────────────────
  void onFooterTap(int index) {
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

  // ═══════════════════════════════════════════════════════════
  // CARGAR SUBCATEGORÍAS (SOLO NIVEL 1 - HIJAS DIRECTAS)
  // ═══════════════════════════════════════════════════════════
  Future<void> _fetchSubcategories() async {
    final String parentId = widget.category['id'].toString();

    try {
      final url =
          '$_baseUrl/categories?ws_key=$_apiKey&output_format=JSON&display=[id,name,id_parent]&filter[id_parent]=$parentId&filter[active]=1';

      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        List<dynamic> rawItems = [];

        if (data is Map<String, dynamic>) {
          if (data.containsKey('categories')) {
            final c = data['categories'];
            if (c is Map && c.containsKey('category')) {
              rawItems = (c['category'] as List<dynamic>?) ?? [];
            } else if (c is List) {
              rawItems = c;
            }
          } else if (data.containsKey('category')) {
            rawItems = (data['category'] as List<dynamic>?) ?? [];
          }
        }

        final List<Map<String, dynamic>> subcats = [];

        for (final it in rawItems) {
          if (it is Map<String, dynamic>) {
            final id = (it['id'] ?? it['id_category'])?.toString();
            var name = it['name'];

            // Manejar nombre multilenguaje de PrestaShop
            if (name is Map && name['language'] is List) {
              name = name['language'][0]['value'] ?? 'Subcategoría';
            }

            if (id != null && id.isNotEmpty) {
              subcats.add({
                'id': id,
                'name': name?.toString() ?? 'Subcategoría',
              });

              // Cargar descendientes de esta subcategoría
              final descendants = await _getAllSubcategoryIds(id);
              _subcategoryDescendants[id] = [id, ...descendants];
            }
          }
        }

        setState(() {
          _subcategories = subcats;
          _loadingSubcategories = false;
        });
      } else {
        setState(() => _loadingSubcategories = false);
      }
    } catch (e) {
      debugPrint('Error cargando subcategorías: $e');
      setState(() => _loadingSubcategories = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // OBTENER SUBCATEGORÍAS RECURSIVAMENTE (TODOS LOS NIVELES)
  // ─────────────────────────────────────────────────────────
  Future<List<String>> _getAllSubcategoryIds(String parentId) async {
    final List<String> result = [];
    List<String> currentLevel = [parentId];

    while (currentLevel.isNotEmpty) {
      final filter = '[${currentLevel.join('|')}]';
      final url =
          '$_baseUrl/categories?ws_key=$_apiKey&output_format=JSON&display=[id,id_parent]&filter[id_parent]=$filter';

      try {
        final resp = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 8));
        if (!mounted || resp.statusCode != 200) break;

        final data = json.decode(resp.body);
        List<dynamic> rawItems = [];

        if (data is Map<String, dynamic>) {
          if (data.containsKey('categories')) {
            final c = data['categories'];
            if (c is Map && c.containsKey('category')) {
              rawItems = (c['category'] as List<dynamic>?) ?? [];
            } else if (c is List) {
              rawItems = c;
            }
          } else if (data.containsKey('category')) {
            rawItems = (data['category'] as List<dynamic>?) ?? [];
          } else {
            data.forEach((k, v) {
              if (rawItems.isEmpty && v is List) rawItems = v;
            });
          }
        }

        if (rawItems.isEmpty) break;

        final List<String> nextLevel = [];
        for (final it in rawItems) {
          if (it is Map<String, dynamic>) {
            final id = (it['id'] ?? it['id_category'] ?? it['category_id'])
                ?.toString();
            if (id != null && id.isNotEmpty) {
              result.add(id);
              nextLevel.add(id);
            }
          }
        }

        currentLevel = nextLevel;
      } catch (e) {
        debugPrint('getAllSubcategoryIds error: $e');
        break;
      }
    }

    return result.toSet().toList();
  }

  // ─────────────────────────────────────────────────────────
  // FETCH PRODUCTOS
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final String idCat = widget.category['id'].toString();

      // Obtener todas las subcategorías
      List<String> allIds = [idCat];
      final subIds = await _getAllSubcategoryIds(idCat);
      if (!mounted) return;
      allIds.addAll(subIds);
      allIds = allIds.toSet().toList();

      // Construir filtro
      final filter = '[${allIds.join('|')}]';

      final url =
          '$_baseUrl/products?ws_key=$_apiKey&output_format=JSON&display=[id,name,price,id_category_default,id_default_image]&filter[id_category_default]=$filter&filter[active]=1';

      final resp = await http.get(Uri.parse(url));
      if (!mounted) return;
      if (resp.statusCode != 200) throw Exception('Error al cargar productos');

      final data = json.decode(resp.body);
      final List<dynamic>? items = data['products'];

      if (items == null) throw Exception('Sin productos');

      String buildPrestashopImageUrl(String imgId) {
        if (imgId.isEmpty) return '';
        final digits = imgId.split('');
        final path = digits.join('/');
        return 'https://www.farmaciaguerrerozieza.com/img/p/$path/$imgId-home_default.jpg';
      }

      final List<Map<String, dynamic>> products = items.map((it) {
        final pid = it['id']?.toString() ?? '';
        final name = it['name']?.toString() ?? 'Producto';
        final price = it['price']?.toString() ?? '';
        final imgId = it['id_default_image']?.toString() ?? '';
        final categoryId = it['id_category_default']?.toString() ?? '';
        final imgUrl = buildPrestashopImageUrl(imgId);

        return {
          'id': pid,
          'name': name,
          'price': price,
          'image': imgUrl,
          'categoryId':
              categoryId, // ← IMPORTANTE: Guardar la categoría del producto
        };
      }).toList();

      final limited = products.length > _maxProducts
          ? products.sublist(0, _maxProducts)
          : products;

      if (!mounted) return;
      setState(() {
        _products = limited;
        _loading = false;
      });

      // Aplicar filtros después de cargar
      _applyFilters();
    } catch (e) {
      debugPrint('❌ Error: $e');
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  // ═══════════════════════════════════════════════════════════
  // APLICAR FILTROS (SUBCATEGORÍA + BÚSQUEDA)
  // ═══════════════════════════════════════════════════════════
  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_products);

    // 1. Filtrar por subcategoría seleccionada
    if (_selectedSubcategoryId != null) {
      final allowedCategories =
          _subcategoryDescendants[_selectedSubcategoryId] ??
          [_selectedSubcategoryId!];
      result = result.where((p) {
        final productCategoryId = p['categoryId']?.toString() ?? '';
        return allowedCategories.contains(productCategoryId);
      }).toList();
    }

    // 2. Filtrar por texto de búsqueda
    if (_searchText.isNotEmpty) {
      result = result.where((p) {
        return p['name'].toString().toLowerCase().contains(
          _searchText.toLowerCase(),
        );
      }).toList();
    }

    // Aplicar límite
    final limited = result.length > _maxProducts
        ? result.sublist(0, _maxProducts)
        : result;

    setState(() {
      _filteredProducts = limited;
      _visibleCount = min(16, _filteredProducts.length);
    });
  }

  void _filterProducts(String query) {
    _searchText = query;
    _applyFilters();
  }

  void _selectSubcategory(String? subcategoryId) {
    setState(() {
      _selectedSubcategoryId = subcategoryId;
    });
    _applyFilters();
  }

  void _clearSearch() {
    _searchController.clear();
    _searchText = '';
    _applyFilters();
    _searchFocusNode.unfocus();
  }

  void _clearAllFilters() {
    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedSubcategoryId = null;
    });
    _applyFilters();
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: _loading
                  ? _buildLoadingState()
                  : _error
                  ? _buildErrorState()
                  : _buildContent(),
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

  // ═══════════════════════════════════════════════════════════
  // ESTADO: CARGANDO
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
            "Cargando productos...",
            style: AppText.body.copyWith(
              color: AppColors.textDark.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADO: ERROR
  // ═══════════════════════════════════════════════════════════
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
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
            Text("¡Ups! Algo salió mal", style: AppText.subtitle),
            const SizedBox(height: 8),
            Text(
              "No pudimos cargar los productos de esta categoría",
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _initializeData,
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
              label: Text(
                "Reintentar",
                style: AppText.button.copyWith(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CONTENIDO PRINCIPAL
  // ═══════════════════════════════════════════════════════════
  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _initializeData,
      color: AppColors.green500,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          // Header de categoría
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCategoryHeader(),
                  const SizedBox(height: 16),
                  _buildSearchBar(),

                  // ═══════════════════════════════════════════════
                  // NUEVO: FILTRO POR SUBCATEGORÍAS
                  // ═══════════════════════════════════════════════
                  if (_subcategories.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildSubcategoryFilter(),
                  ],

                  const SizedBox(height: 8),
                  _buildResultsInfo(),

                  // Mostrar filtros activos
                  if (_selectedSubcategoryId != null || _searchText.isNotEmpty)
                    _buildActiveFilters(),
                ],
              ),
            ),
          ),

          // Grid de productos
          _filteredProducts.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false, // ← CLAVE: evita el overflow
                  child: _buildEmptyState(),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= _visibleCount) return null;
                        final product = _filteredProducts[index];
                        return _ProductCard(
                          id: product['id'] ?? '',
                          name: product['name'] ?? 'Producto',
                          price: product['price'] ?? '',
                          image: product['image'] ?? '',
                        );
                      },
                      childCount: min(_visibleCount, _filteredProducts.length),
                    ),
                  ),
                ),

          // Botón "Ver más"
          if (_visibleCount < _filteredProducts.length)
            SliverToBoxAdapter(child: _buildLoadMoreButton()),

          // Espacio final
          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: FILTRO POR SUBCATEGORÍAS (CHIPS HORIZONTALES)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSubcategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título de sección
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 16,
                color: AppColors.textDark.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Text(
                "Filtrar por subcategoría",
                style: AppText.small.copyWith(
                  color: AppColors.textDark.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Chips horizontales
        SizedBox(
          height: 40,
          child: ListView.builder(
            controller: _subcategoryScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _subcategories.length + 1, // +1 para "Todas"
            itemBuilder: (context, index) {
              if (index == 0) {
                // Chip "Todas"
                return _buildSubcategoryChip(
                  id: null,
                  name: "Todas",
                  isSelected: _selectedSubcategoryId == null,
                  isFirst: true,
                );
              }

              final subcat = _subcategories[index - 1];
              return _buildSubcategoryChip(
                id: subcat['id'],
                name: subcat['name'],
                isSelected: _selectedSubcategoryId == subcat['id'],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryChip({
    required String? id,
    required String name,
    required bool isSelected,
    bool isFirst = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: isFirst ? 0 : 8, right: 0),
      child: GestureDetector(
        onTap: () => _selectSubcategory(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.green500 : AppColors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.green500 : Colors.grey.shade300,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.green500.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected && id == null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.white,
                  ),
                ),
              Text(
                name,
                style: AppText.small.copyWith(
                  color: isSelected ? AppColors.white : AppColors.textDark,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: FILTROS ACTIVOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildActiveFilters() {
    // Obtener nombre de subcategoría seleccionada
    String? subcategoryName;
    if (_selectedSubcategoryId != null) {
      final subcat = _subcategories.firstWhere(
        (s) => s['id'] == _selectedSubcategoryId,
        orElse: () => {},
      );
      subcategoryName = subcat['name'];
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.purple50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.purple200),
        ),
        child: Row(
          children: [
            Icon(
              Icons.filter_alt_outlined,
              size: 18,
              color: AppColors.purple600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (subcategoryName != null)
                    _buildActiveFilterTag(
                      label: subcategoryName,
                      icon: Icons.category_outlined,
                      onRemove: () => _selectSubcategory(null),
                    ),
                  if (_searchText.isNotEmpty)
                    _buildActiveFilterTag(
                      label: '"$_searchText"',
                      icon: Icons.search_rounded,
                      onRemove: _clearSearch,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.purple100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Limpiar",
                  style: AppText.small.copyWith(
                    color: AppColors.purple600,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilterTag({
    required String label,
    required IconData icon,
    required VoidCallback onRemove,
  }) {
    return Container(
      constraints: const BoxConstraints(
        maxWidth: 200, // ← AÑADE ESTO: ancho máximo del tag
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.purple200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.purple500),
          const SizedBox(width: 6),
          Flexible(
            // ← CAMBIA DE Text directo a Flexible > Text
            child: Text(
              label,
              style: AppText.small.copyWith(
                color: AppColors.purple700,
                fontWeight: FontWeight.w500,
                fontSize: 12,
              ),
              maxLines: 1, // ← AÑADE ESTO
              overflow: TextOverflow.ellipsis, // ← AÑADE ESTO
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onRemove,
            child: Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.purple400,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: HEADER DE CATEGORÍA
  // ═══════════════════════════════════════════════════════════
  Widget _buildCategoryHeader() {
    final label = widget.category['label'] ?? 'Categoría';
    final imageJpg = (widget.category['imageJpg'] ?? '').toString();
    final imagePng = (widget.category['imagePng'] ?? '').toString();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de categoría
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.green100, AppColors.green50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: _buildCategoryIcon(imageJpg, imagePng),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Info de categoría
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppText.title.copyWith(fontSize: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Productos (siempre en primera línea)
                Text(
                  "${_products.length} productos",
                  style: AppText.small.copyWith(
                    color: AppColors.textDark.withOpacity(0.5),
                  ),
                ),

                // Subcategorías (en segunda línea si existen)
                if (_subcategories.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    "${_subcategories.length} subcategorías",
                    style: AppText.small.copyWith(
                      color: AppColors.purple500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Botón volver
          Container(
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_rounded,
                color: AppColors.green600,
              ),
              tooltip: 'Volver',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIcon(String imageJpg, String imagePng) {
    final image = imageJpg.isNotEmpty ? imageJpg : imagePng;

    if (image.isEmpty) {
      return const Icon(
        Icons.category_outlined,
        size: 32,
        color: AppColors.green600,
      );
    }

    return CachedNetworkImage(
      imageUrl: image,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Icon(
        Icons.category_outlined,
        size: 32,
        color: AppColors.green400,
      ),
      errorWidget: (_, __, ___) {
        if (imagePng.isNotEmpty && image != imagePng) {
          return CachedNetworkImage(
            imageUrl: imagePng,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const Icon(
              Icons.category_outlined,
              size: 32,
              color: AppColors.green600,
            ),
          );
        }
        return const Icon(
          Icons.category_outlined,
          size: 32,
          color: AppColors.green600,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BARRA DE BÚSQUEDA
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchBar() {
    return Container(
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
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        onChanged: _filterProducts,
        style: AppText.body.copyWith(fontSize: 15),
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
          fillColor: AppColors.white,
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
    final hasFilters = _selectedSubcategoryId != null || _searchText.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: hasFilters ? AppColors.purple500 : AppColors.green500,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hasFilters
                  ? "${_filteredProducts.length} resultado${_filteredProducts.length != 1 ? 's' : ''} con filtros"
                  : "Mostrando ${min(_visibleCount, _filteredProducts.length)} de ${_filteredProducts.length}",
              style: AppText.small.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: ESTADO VACÍO
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    final hasFilters = _selectedSubcategoryId != null || _searchText.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: hasFilters ? AppColors.purple50 : AppColors.green50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFilters
                    ? Icons.filter_alt_off_outlined
                    : Icons.inventory_2_outlined,
                size: 48,
                color: hasFilters ? AppColors.purple400 : AppColors.green400,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              hasFilters ? "Sin resultados" : "No hay productos",
              style: AppText.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              hasFilters
                  ? "No encontramos productos con los filtros actuales"
                  : "Esta categoría no tiene productos disponibles",
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _clearAllFilters,
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
                icon: const Icon(Icons.clear_all_rounded, size: 18),
                label: const Text("Limpiar filtros"),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BOTÓN "VER MÁS"
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadMoreButton() {
    final remaining = _filteredProducts.length - _visibleCount;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
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
            onTap: () => setState(
              () => _visibleCount = min(
                _visibleCount + 16,
                _filteredProducts.length,
              ),
            ),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
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
// WIDGET: TARJETA DE PRODUCTO
// ═══════════════════════════════════════════════════════════════════════════════
class _ProductCard extends StatefulWidget {
  final String id;
  final String name;
  final String price;
  final String image;

  const _ProductCard({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
  });

  @override
  State<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<_ProductCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    double priceValue = double.tryParse(widget.price) ?? 0;
    double priceWithTax = priceValue * 1.21;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
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
              Expanded(
                flex: 3,
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  child: Container(
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
                ),
              ),
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
                          ),
                        ),
                      ),
                      if (priceValue > 0)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${priceWithTax.toStringAsFixed(2)} €",
                              style: AppText.body.copyWith(
                                fontSize: 14,
                                color: AppColors.green600,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.green50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: AppColors.green600,
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

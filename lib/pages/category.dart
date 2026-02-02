import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';
import 'producto.dart';

import '../widgets/auto_text.dart';
import '../widgets/translated_text_field.dart';

import '../pages/scanner_page.dart';

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
  // SUBCATEGORÍAS Y FILTROS
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> _subcategories = [];
  Map<String, List<String>> _subcategoryDescendants = {};
  String? _selectedSubcategoryId;
  bool _loadingSubcategories = true;
  bool _loadingDescendants =
      false; // ← NUEVO: para saber si aún carga descendants

  // ═══════════════════════════════════════════════════════════
  // CONTROL DEL STICKY FILTER Y SCROLL TO TOP
  // ═══════════════════════════════════════════════════════════
  final ScrollController _scrollController = ScrollController();
  bool _isFilterSticky = false;
  bool _showScrollToTop = false;
  final double _stickyThreshold = 200;
  final double _scrollToTopThreshold = 400;

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
    _scrollController.addListener(_onScroll);
    _initializeData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _subcategoryScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final offset = _scrollController.offset;

    // Control del sticky filter
    final isSticky = offset > _stickyThreshold;
    if (isSticky != _isFilterSticky) {
      setState(() => _isFilterSticky = isSticky);
    }

    // Control del botón scroll to top
    final showScrollTop = offset > _scrollToTopThreshold;
    if (showScrollTop != _showScrollToTop) {
      setState(() => _showScrollToTop = showScrollTop);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SCROLL AL INICIO
  // ═══════════════════════════════════════════════════════════
  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _initializeData() async {
    await Future.wait([_fetchSubcategories(), _fetchProducts()]);
  }

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

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CARGAR SUBCATEGORÍAS (OPTIMIZADO)
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

            if (name is Map && name['language'] is List) {
              name = name['language'][0]['value'] ?? 'Subcategoría';
            }

            if (id != null && id.isNotEmpty) {
              subcats.add({
                'id': id,
                'name': name?.toString() ?? 'Subcategoría',
              });
            }
          }
        }

        // ✅ MOSTRAR SUBCATEGORÍAS INMEDIATAMENTE
        setState(() {
          _subcategories = subcats;
          _loadingSubcategories = false;
          _loadingDescendants = subcats.isNotEmpty;
        });

        // ✅ CARGAR DESCENDANTS EN PARALELO (en segundo plano)
        if (subcats.isNotEmpty) {
          _loadDescendantsInParallel(subcats);
        }
      } else {
        setState(() => _loadingSubcategories = false);
      }
    } catch (e) {
      debugPrint('Error cargando subcategorías: $e');
      setState(() => _loadingSubcategories = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // CARGAR DESCENDANTS EN PARALELO
  // ═══════════════════════════════════════════════════════════
  Future<void> _loadDescendantsInParallel(
    List<Map<String, dynamic>> subcats,
  ) async {
    try {
      // Crear lista de futures para cargar todos en paralelo
      final futures = subcats.map((subcat) async {
        final id = subcat['id'] as String;
        final descendants = await _getAllSubcategoryIds(id);
        return MapEntry(id, [id, ...descendants]);
      }).toList();

      // Ejecutar todos en paralelo
      final results = await Future.wait(futures);

      if (!mounted) return;

      // Guardar resultados
      for (final entry in results) {
        _subcategoryDescendants[entry.key] = entry.value;
      }

      setState(() {
        _loadingDescendants = false;
      });
    } catch (e) {
      debugPrint('Error cargando descendants: $e');
      if (mounted) {
        setState(() => _loadingDescendants = false);
      }
    }
  }

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
          }
        }

        if (rawItems.isEmpty) break;

        final List<String> nextLevel = [];
        for (final it in rawItems) {
          if (it is Map<String, dynamic>) {
            final id = (it['id'] ?? it['id_category'])?.toString();
            if (id != null && id.isNotEmpty) {
              result.add(id);
              nextLevel.add(id);
            }
          }
        }

        currentLevel = nextLevel;
      } catch (e) {
        break;
      }
    }

    return result.toSet().toList();
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final String idCat = widget.category['id'].toString();

      List<String> allIds = [idCat];
      final subIds = await _getAllSubcategoryIds(idCat);
      if (!mounted) return;
      allIds.addAll(subIds);
      allIds = allIds.toSet().toList();

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
        return {
          'id': it['id']?.toString() ?? '',
          'name': it['name']?.toString() ?? 'Producto',
          'price': it['price']?.toString() ?? '',
          'image': buildPrestashopImageUrl(
            it['id_default_image']?.toString() ?? '',
          ),
          'categoryId': it['id_category_default']?.toString() ?? '',
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

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_products);

    if (_selectedSubcategoryId != null) {
      final allowedCategories =
          _subcategoryDescendants[_selectedSubcategoryId] ??
          [_selectedSubcategoryId!];
      result = result.where((p) {
        final productCategoryId = p['categoryId']?.toString() ?? '';
        return allowedCategories.contains(productCategoryId);
      }).toList();
    }

    if (_searchText.isNotEmpty) {
      result = result.where((p) {
        return p['name'].toString().toLowerCase().contains(
          _searchText.toLowerCase(),
        );
      }).toList();
    }

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
    final wasSticky = _isFilterSticky;

    setState(() {
      _selectedSubcategoryId = subcategoryId;
    });
    _applyFilters();

    // Si estaba en modo sticky, volver al inicio
    if (wasSticky) {
      _scrollToTop();
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchText = '';
    _applyFilters();
    _searchFocusNode.unfocus();
  }

  void _clearAllFilters() {
    final wasSticky = _isFilterSticky;

    _searchController.clear();
    setState(() {
      _searchText = '';
      _selectedSubcategoryId = null;
    });
    _applyFilters();

    // Si estaba en modo sticky, volver al inicio
    if (wasSticky) {
      _scrollToTop();
    }
  }

  String _getSelectedSubcategoryName() {
    if (_selectedSubcategoryId == null) return "Todas";
    final subcat = _subcategories.firstWhere(
      (s) => s['id'] == _selectedSubcategoryId,
      orElse: () => {'name': 'Subcategoría'},
    );
    return subcat['name'] ?? 'Subcategoría';
  }

  bool get _hasActiveFilters =>
      _selectedSubcategoryId != null || _searchText.isNotEmpty;

  // ═══════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,

      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const AppHeader(),

            // STICKY FILTER SIMPLE
            if (_isFilterSticky && _subcategories.isNotEmpty)
              _buildStickyFilterBar(),

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

      floatingActionButton: _buildScrollToTopButton(),
      bottomNavigationBar: AppFooter(
        currentIndex: selectedIndex,
        onTap: onFooterTap,
        onScanTap: _openScanner,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BOTÓN SCROLL TO TOP
  // ═══════════════════════════════════════════════════════════
  Widget? _buildScrollToTopButton() {
    if (!_showScrollToTop || _loading) return null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.green600,
              elevation: 4,
              mini: true,
              child: const Icon(
                Icons.keyboard_arrow_up_rounded,
                color: AppColors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BARRA DE FILTRO STICKY (CON INDICADOR DE CARGA)
  // ═══════════════════════════════════════════════════════════
  Widget _buildStickyFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono de filtro compacto
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple600, AppColors.purple400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.purple500.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _loadingDescendants
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(
                    Icons.filter_list_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
          ),

          const SizedBox(width: 10),

          // Selector de subcategoría
          Expanded(
            child: GestureDetector(
              onTap: () => _showSubcategoryPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: _selectedSubcategoryId != null
                      ? AppColors.purple50
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _selectedSubcategoryId != null
                        ? AppColors.purple300
                        : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AutoText(
                        _getSelectedSubcategoryName(),
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: _selectedSubcategoryId != null
                              ? AppColors.purple700
                              : AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: _selectedSubcategoryId != null
                          ? AppColors.purple500
                          : Colors.grey.shade500,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Botón Limpiar
          if (_hasActiveFilters) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _clearAllFilters,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Icon(
                  Icons.close_rounded,
                  color: Colors.red.shade500,
                  size: 18,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // MODAL: SELECTOR DE SUBCATEGORÍAS (TEMA PÚRPURA)
  // ═══════════════════════════════════════════════════════════
  void _showSubcategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.65,
        ),
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Icono con gradiente púrpura
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppColors.purple600, AppColors.purple400],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple500.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _loadingDescendants
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.white,
                            ),
                          )
                        : const Icon(
                            Icons.filter_list_rounded,
                            color: AppColors.white,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 14),

                  // Título y subtítulo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoText(
                          "Filtrar productos",
                          style: AppText.title.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.purple100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AutoText(
                                    "${_subcategories.length + 1} opciones",
                                    style: AppText.small.copyWith(
                                      color: AppColors.purple700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                  if (_loadingDescendants) ...[
                                    const SizedBox(width: 6),
                                    SizedBox(
                                      width: 10,
                                      height: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        color: AppColors.purple600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botón cerrar
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Divider(color: Colors.grey.shade200, height: 1),

            // Lista de opciones
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: _subcategories.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildSubcategoryOption(
                      id: null,
                      name: "Todas las subcategorías",
                      icon: Icons.grid_view_rounded,
                      isSelected: _selectedSubcategoryId == null,
                      productCount: _products.length,
                    );
                  }

                  final subcat = _subcategories[index - 1];
                  final subcatProducts = _products.where((p) {
                    final allowedCategories =
                        _subcategoryDescendants[subcat['id']] ?? [subcat['id']];
                    return allowedCategories.contains(
                      p['categoryId']?.toString(),
                    );
                  }).length;

                  return _buildSubcategoryOption(
                    id: subcat['id'],
                    name: subcat['name'],
                    icon: Icons.folder_outlined,
                    isSelected: _selectedSubcategoryId == subcat['id'],
                    productCount: subcatProducts,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: OPCIÓN DE SUBCATEGORÍA (TEMA PÚRPURA)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSubcategoryOption({
    required String? id,
    required String name,
    required IconData icon,
    required bool isSelected,
    int productCount = 0,
  }) {
    final bool isLoadingCount = _loadingDescendants && id != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.pop(context);
            _selectSubcategory(id);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.purple50 : AppColors.background,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.purple400 : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                // Icono
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.purple100 : AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.purple300
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? AppColors.purple600
                        : Colors.grey.shade500,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // Nombre y contador
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoText(
                        name,
                        style: AppText.body.copyWith(
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 15,
                          color: isSelected
                              ? AppColors.purple800
                              : AppColors.textDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: isSelected
                                ? AppColors.purple600
                                : Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          if (isLoadingCount)
                            Row(
                              children: [
                                SizedBox(
                                  width: 10,
                                  height: 10,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                AutoText(
                                  "calculando...",
                                  style: AppText.small.copyWith(
                                    color: Colors.grey.shade500,
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            )
                          else
                            AutoText(
                              "$productCount productos",
                              style: AppText.small.copyWith(
                                color: isSelected
                                    ? AppColors.purple600
                                    : Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Indicador de selección
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.purple600
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? AppColors.purple600
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.white,
                          size: 16,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADOS
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
          AutoText(
            "Cargando productos...",
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
            AutoText("¡Ups! Algo salió mal", style: AppText.subtitle),
            const SizedBox(height: 8),
            AutoText(
              "No pudimos cargar los productos",
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
              label: const AutoText("Reintentar"),
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
        controller: _scrollController,
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

                  if (_subcategories.isNotEmpty && !_isFilterSticky) ...[
                    const SizedBox(height: 12),
                    _buildSubcategoryFilter(),
                  ],

                  // Skeleton de subcategorías mientras carga
                  if (_loadingSubcategories) ...[
                    const SizedBox(height: 12),
                    _buildLoadingSubcategoriesPlaceholder(),
                  ],

                  const SizedBox(height: 8),
                  _buildResultsInfo(),
                ],
              ),
            ),
          ),

          // Grid de productos
          _filteredProducts.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
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

          // Espacio para el footer flotante
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: PLACEHOLDER MIENTRAS CARGA SUBCATEGORÍAS
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadingSubcategoriesPlaceholder() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
          child: Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 16,
                color: AppColors.textDark.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              AutoText(
                "Cargando subcategorías...",
                style: AppText.small.copyWith(
                  color: AppColors.textDark.withOpacity(0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.purple500.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 36, child: _buildLoadingChips()),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: SKELETON CHIPS MIENTRAS CARGA
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadingChips() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
          child: Container(
            width: index == 0 ? 60 : 80 + (index * 10.0),
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Center(
              child: Container(
                width: 30 + (index * 8.0),
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: FILTRO POR SUBCATEGORÍAS (CON INDICADOR DE CARGA)
  // ═══════════════════════════════════════════════════════════
  Widget _buildSubcategoryFilter() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con título y botón limpiar
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, right: 4),
          child: Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 16,
                color: AppColors.textDark.withOpacity(0.5),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Row(
                  children: [
                    AutoText(
                      "Filtrar por subcategoría",
                      style: AppText.small.copyWith(
                        color: AppColors.textDark.withOpacity(0.5),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // ✅ INDICADOR DE CARGA DE DESCENDANTS
                    if (_loadingDescendants) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.purple500.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Botón Limpiar
              if (_hasActiveFilters)
                GestureDetector(
                  onTap: _clearAllFilters,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.purple100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: AutoText(
                      "Limpiar",
                      style: AppText.small.copyWith(
                        color: AppColors.purple700,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        SizedBox(
          height: 36,
          child: ListView.builder(
            controller: _subcategoryScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _subcategories.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
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
      padding: EdgeInsets.only(left: isFirst ? 0 : 8),
      child: GestureDetector(
        onTap: () => _selectSubcategory(id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purple700 : AppColors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected ? AppColors.purple700 : Colors.grey.shade300,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.purple700.withOpacity(0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: AutoText(
            name,
            style: AppText.small.copyWith(
              color: isSelected ? AppColors.white : AppColors.textDark,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // RESTO DE WIDGETS
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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoText(
                  label,
                  style: AppText.title.copyWith(fontSize: 18),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                AutoText(
                  "${_products.length} productos",
                  style: AppText.small.copyWith(
                    color: AppColors.textDark.withOpacity(0.5),
                  ),
                ),
                if (_subcategories.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      AutoText(
                        "${_subcategories.length} subcategorías",
                        style: AppText.small.copyWith(
                          color: AppColors.purple700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (_loadingDescendants) ...[
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.purple500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else if (_loadingSubcategories) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      AutoText(
                        "Cargando...",
                        style: AppText.small.copyWith(
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.green600,
            ),
            tooltip: 'Volver',
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
      errorWidget: (_, __, ___) => const Icon(
        Icons.category_outlined,
        size: 32,
        color: AppColors.green600,
      ),
    );
  }

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
      child: TranslatedTextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        hintText: 'Buscar por nombre...',
        onChanged: _filterProducts,
        style: AppText.body.copyWith(fontSize: 15),
        decoration: InputDecoration(
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

  Widget _buildResultsInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: _hasActiveFilters
                  ? AppColors.purple500
                  : AppColors.purple500,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AutoText(
              _hasActiveFilters
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
                color: _hasActiveFilters
                    ? AppColors.purple50
                    : AppColors.green50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _hasActiveFilters
                    ? Icons.filter_alt_off_outlined
                    : Icons.inventory_2_outlined,
                size: 48,
                color: _hasActiveFilters
                    ? AppColors.purple400
                    : AppColors.green400,
              ),
            ),
            const SizedBox(height: 20),
            AutoText(
              _hasActiveFilters ? "Sin resultados" : "No hay productos",
              style: AppText.subtitle,
            ),
            const SizedBox(height: 8),
            AutoText(
              _hasActiveFilters
                  ? "No encontramos productos con los filtros actuales"
                  : "Esta categoría no tiene productos disponibles",
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
            if (_hasActiveFilters) ...[
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
                label: const AutoText("Limpiar filtros"),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
                  AutoText(
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
                    child: AutoText(
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
                flex: 5,
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
                        child: AutoText(
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
                            AutoText(
                              "${priceWithTax.toStringAsFixed(2)} €",
                              style: AppText.body.copyWith(
                                fontSize: 14,
                                color: AppColors.green700,
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
                                color: AppColors.green700,
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

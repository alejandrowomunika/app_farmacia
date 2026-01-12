import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';
import 'category.dart';

class TiendaPage extends StatefulWidget {
  const TiendaPage({super.key});

  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

class _TiendaPageState extends State<TiendaPage> {
  int selectedIndex = 1;

  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _categories = [];

  final String _url =
      'https://www.farmaciaguerrerozieza.com/api/categories?ws_key=CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS&output_format=JSON&display=[id,name,id_parent]&filter[id_parent]=2&filter[active]=1';

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  // ─────────────────────────────────────────────────────────
  // NAVEGACIÓN FOOTER
  // ─────────────────────────────────────────────────────────
  void onFooterTap(int index) {
    if (index == selectedIndex) return;

    setState(() => selectedIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/');
        break;
      case 1:
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/chat');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/carrito');
        break;
    }
  }

  // ─────────────────────────────────────────────────────────
  // FETCH CATEGORÍAS
  // ─────────────────────────────────────────────────────────
  Future<void> _fetchCategories() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final resp = await http
          .get(Uri.parse(_url))
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode != 200) {
        throw Exception('Error HTTP ${resp.statusCode}');
      }

      final body = resp.body;
      final jsonData = json.decode(body);

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
        } else {
          jsonData.forEach((k, v) {
            if (items == null && v is List) items = v;
          });
        }
      }

      items ??= [];

      final List<Map<String, dynamic>> parsed = [];

      for (final it in items ?? []) {
        if (it is Map<String, dynamic>) {
          final id =
              (it['id'] ?? it['id_category'] ?? it['category_id'])?.toString();
          final name = (it['name'] ?? it['category_name']) ??
              ((it['name'] is Map && it['name']['language'] is List)
                  ? (it['name']['language'][0]['value'] ?? '')
                  : '');
          if (id != null) {
            final jpg = 'https://www.farmaciaguerrerozieza.com/img/c/$id.jpg';
            final png = 'https://www.farmaciaguerrerozieza.com/img/c/$id.png';

            parsed.add({
              'id': id,
              'name': name is String ? name : name.toString(),
              'imageJpg': jpg,
              'imagePng': png,
            });
          }
        }
      }

      setState(() {
        _categories = parsed;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Error cargando categorías: ${e.toString()}';
        _loading = false;
      });
    }
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
                  : _error.isNotEmpty
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
            "Cargando categorías...",
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
            Text(
              "¡Ups! Algo salió mal",
              style: AppText.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              _error,
              textAlign: TextAlign.center,
              style: AppText.small.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchCategories,
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
      onRefresh: _fetchCategories,
      color: AppColors.green500,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────────────
            // TÍTULO DE LA SECCIÓN
            // ─────────────────────────────────────────────────
            _buildSectionHeader(),

            const SizedBox(height: 20),

            // ─────────────────────────────────────────────────
            // GRID DE CATEGORÍAS
            // ─────────────────────────────────────────────────
            _buildCategoriesGrid(),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: HEADER DE SECCIÓN
  // ═══════════════════════════════════════════════════════════
  Widget _buildSectionHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.green500,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Categorías",
                style: AppText.title.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 2),
              Text(
                "${_categories.length} categorías disponibles",
                style: AppText.small.copyWith(
                  color: AppColors.textDark.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: GRID DE CATEGORÍAS (RESPONSIVE)
  // ═══════════════════════════════════════════════════════════
  Widget _buildCategoriesGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcular altura basada en el factor de escala de texto
        final textScaleFactor = MediaQuery.of(context).textScaleFactor;
        
        // Altura base ajustada según el tamaño de texto
        // A mayor escala de texto, mayor altura de la tarjeta
        final baseHeight = 120.0;
        final adjustedHeight = baseHeight * (0.8 + (textScaleFactor * 0.3));
        
        // Calcular el aspect ratio dinámicamente
        final cardWidth = (constraints.maxWidth - 12) / 2; // 12 es el crossAxisSpacing
        final aspectRatio = cardWidth / adjustedHeight;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _categories.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: aspectRatio.clamp(0.8, 1.6), // Limitar el rango
          ),
          itemBuilder: (context, index) {
            final cat = _categories[index];
            return _CategoryCard(
              id: cat['id'],
              name: cat['name'] ?? 'Categoría',
              imageJpg: cat['imageJpg'],
              imagePng: cat['imagePng'],
              onTap: () => _navigateToCategory(cat),
            );
          },
        );
      },
    );
  }

  void _navigateToCategory(Map<String, dynamic> cat) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryPage(
          category: {
            'id': cat['id'],
            'label': cat['name'],
            'icon': Icons.category_outlined,
            'bg': AppColors.white,
            'color': AppColors.green600,
            'imageJpg': cat['imageJpg'],
            'imagePng': cat['imagePng'],
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: TARJETA DE CATEGORÍA - VERSIÓN ADAPTATIVA
// ═══════════════════════════════════════════════════════════════════════════════
class _CategoryCard extends StatefulWidget {
  final String id;
  final String name;
  final String? imageJpg;
  final String? imagePng;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.id,
    required this.name,
    this.imageJpg,
    this.imagePng,
    required this.onTap,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  children: [
                    // ═══════════════════════════════════════════════
                    // ICONO DE FONDO (GRANDE PERO SUTIL)
                    // ═══════════════════════════════════════════════
                    Positioned(
                      bottom: 13,
                      right: -25,
                      child: Opacity(
                        opacity: 0.08,
                        child: SizedBox(
                          width: 100,
                          height: 100,
                          child: _buildLargeIcon(),
                        ),
                      ),
                    ),

                    // ═══════════════════════════════════════════════
                    // CONTENIDO PRINCIPAL - USANDO COLUMN FLEXIBLE
                    // ═══════════════════════════════════════════════
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          // ─────────────────────────────────────────
                          // ICONO EN CONTENEDOR (Tamaño fijo)
                          // ─────────────────────────────────────────
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.green100,
                                  AppColors.green50,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: _buildCategoryIcon(),
                            ),
                          ),

                          // ─────────────────────────────────────────
                          // ESPACIO FLEXIBLE
                          // ─────────────────────────────────────────
                          const Spacer(flex: 1),

                          // ─────────────────────────────────────────
                          // NOMBRE (Flexible, se ajusta al espacio)
                          // ─────────────────────────────────────────
                          Flexible(
                            flex: 2,
                            child: Text(
                              widget.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 4),

                          // ─────────────────────────────────────────
                          // INDICADOR "VER" (Tamaño adaptativo)
                          // ─────────────────────────────────────────
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Ver",
                                  style: AppText.small.copyWith(
                                    color: AppColors.green600,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 11,
                                  color: AppColors.green600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryIcon() {
    if (widget.imageJpg == null || widget.imageJpg!.isEmpty) {
      return const Icon(
        Icons.category_outlined,
        size: 22,
        color: AppColors.green600,
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageJpg!,
      fit: BoxFit.contain,
      placeholder: (_, __) => const Icon(
        Icons.category_outlined,
        size: 22,
        color: AppColors.green400,
      ),
      errorWidget: (_, __, ___) {
        if (widget.imagePng != null && widget.imagePng!.isNotEmpty) {
          return CachedNetworkImage(
            imageUrl: widget.imagePng!,
            fit: BoxFit.contain,
            errorWidget: (_, __, ___) => const Icon(
              Icons.category_outlined,
              size: 22,
              color: AppColors.green600,
            ),
          );
        }
        return const Icon(
          Icons.category_outlined,
          size: 22,
          color: AppColors.green600,
        );
      },
    );
  }

  Widget _buildLargeIcon() {
    if (widget.imageJpg == null || widget.imageJpg!.isEmpty) {
      return const Icon(
        Icons.category_outlined,
        size: 80,
        color: AppColors.green600,
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.imageJpg!,
      fit: BoxFit.contain,
      errorWidget: (_, __, ___) => const Icon(
        Icons.category_outlined,
        size: 80,
        color: AppColors.green600,
      ),
    );
  }
}
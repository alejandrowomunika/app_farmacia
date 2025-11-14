import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'producto.dart';

class CategoryPage extends StatefulWidget {
  final Map<String, dynamic> category;

  const CategoryPage({super.key, required this.category});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _loading = true;
  bool _error = false;
  int _visibleCount = 8;
  String _searchText = '';
  final String _apiKey = 'CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS';
  final String _baseUrl = 'https://www.farmaciaguerrerozieza.com/api';
  final Map<String, Uint8List?> _imageBytesCache = {};

  // límite máximo de productos a mostrar
  final int _maxProducts = 100;

  /// 🔁 Función recursiva para obtener todos los IDs de subcategorías
  Future<List<String>> _getAllSubcategoryIds(String parentId) async {
    final List<String> result = [];
    List<String> currentLevel = [parentId];

    // no incluir el parentId en el resultado (la llamada que use esta función ya añade el id raíz)
    while (currentLevel.isNotEmpty) {
      // construir filtro para pedir hijos de todos los ids del nivel en una sola petición
      final filter = '[${currentLevel.join('|')}]';
      final url =
          '$_baseUrl/categories?ws_key=$_apiKey&output_format=JSON&display=[id,id_parent]&filter[id_parent]=$filter';

      try {
        final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 8));
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
            final id = (it['id'] ?? it['id_category'] ?? it['category_id'])?.toString();
            if (id != null && id.isNotEmpty) {
              // añadir al resultado y al siguiente nivel
              result.add(id);
              nextLevel.add(id);
            }
          }
        }

        // avanzar al siguiente nivel
        currentLevel = nextLevel;
      } catch (e) {
        // en caso de error de red salimos para no bloquear la UI
        print('getAllSubcategoryIds error: $e');
        break;
      }
    }

    // dedupe por si acaso
    return result.toSet().toList();
  }

  /// Descargar bytes de imagen (igual que main.dart)
  Future<Uint8List?> _fetchImageBytes(String url) async {
    if (url.isEmpty) return null;
    if (_imageBytesCache.containsKey(url)) return _imageBytesCache[url];

    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        _imageBytesCache[url] = resp.bodyBytes;
        return resp.bodyBytes;
      } else {
        print('Image fetch failed: status=${resp.statusCode} url=$url');
        _imageBytesCache[url] = null;
        return null;
      }
    } catch (e) {
      print('Image fetch error: $e url=$url');
      _imageBytesCache[url] = null;
      return null;
    }
  }

  Future<void> _fetchProducts() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final String idCat = widget.category['id'].toString();

      // 1️⃣ Obtener todas las subcategorías (recursivamente)
      List<String> allIds = [idCat];
      final subIds = await _getAllSubcategoryIds(idCat);
      if (!mounted) return;
      allIds.addAll(subIds);

      // Quitar duplicados
      allIds = allIds.toSet().toList();

      // 2️⃣ Construir filtro con todos los IDs: [1|2|3|4|...]
      final filter = '[${allIds.join('|')}]';

      final url =
          '$_baseUrl/products?ws_key=$_apiKey&output_format=JSON&display=[id,name,price,id_category_default,id_default_image]&filter[id_category_default]=$filter&filter[active]=1';

      final resp = await http.get(Uri.parse(url));
      if (!mounted) return;
      if (resp.statusCode != 200) throw Exception('Error al cargar productos');

      final data = json.decode(resp.body);
      final List<dynamic>? items = data['products'];

      if (items == null) throw Exception('Sin productos');

      // Construye la URL correcta a partir del ID de la imagen
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


        // Imagen correcta
        final imgUrl = buildPrestashopImageUrl(imgId);

        return {
          'id': pid,
          'name': name,
          'price': price,
          'image': imgUrl,
        };
      }).toList();
      
      // aplicar límite máximo
      final limited = products.length > _maxProducts ? products.sublist(0, _maxProducts) : products;
      

      if (!mounted) return;
      setState(() {
        _products = limited;
        _filteredProducts = List<Map<String, dynamic>>.from(limited); // Inicialmente muestra todos
        _loading = false;
        _visibleCount = min(8, _filteredProducts.length);
      });
    } catch (e) {
      print('❌ Error: $e');
      if (!mounted) return;
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _imageBytesCache.clear();
    super.dispose();
  }

  void _filterProducts(String query) {
    final filtered = _products
        .where((p) => p['name'].toString().toLowerCase().contains(query.toLowerCase()))
        .toList();

    final limitedFiltered = filtered.length > _maxProducts ? filtered.sublist(0, _maxProducts) : filtered;

    setState(() {
      _searchText = query;
      _filteredProducts = limitedFiltered;
      _visibleCount = min(8, _filteredProducts.length); // reiniciar y capear
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Widget _buildIcon(BuildContext context) {
    final imageJpg = (widget.category['imageJpg'] ?? '').toString();
    final imagePng = (widget.category['imagePng'] ?? '').toString();
    final image = imageJpg.isNotEmpty ? imageJpg : imagePng;

    if (image.isEmpty) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.category, color: Colors.green, size: 32),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: FutureBuilder<Uint8List?>(
        future: _fetchImageBytes(image),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Container(
              width: 64,
              height: 64,
              color: Colors.grey.shade100,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(strokeWidth: 2),
            );
          }
          final bytes = snap.data;
          if (bytes == null || bytes.isEmpty) {
            return Container(
              width: 64,
              height: 64,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: const Icon(Icons.broken_image, size: 32, color: Colors.grey),
            );
          }
          return Image.memory(
            bytes,
            width: 64,
            height: 64,
            fit: BoxFit.cover,
            gaplessPlayback: true,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.category['label'] ?? 'Categoría';

    return Scaffold(
      appBar: AppBar(title: Text(label), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error
                ? const Center(child: Text('Error cargando productos'))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _buildIcon(context),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      /// 🔍 Campo de búsqueda
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Buscar producto...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        onChanged: _filterProducts,
                      ),
                      const SizedBox(height: 16),

                      Expanded(
                        child: _filteredProducts.isEmpty
                            ? const Center(
                                child: Text('No hay productos disponibles.'),
                              )
                            : GridView.builder(
                                itemCount: _visibleCount < _filteredProducts.length
                                    ? _visibleCount
                                    : _filteredProducts.length,
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 10,
                                  childAspectRatio: 0.75,
                                ),
                                itemBuilder: (context, index) {
                                  final p = _filteredProducts[index];
                                  return InkWell(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductPage(
                                            product: {
                                              'id': p['id'],
                                              'name': p['name'],
                                              'price': p['price'],
                                              'image': p['image'],
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    child: Container(
                                       decoration: BoxDecoration(
                                         color: Colors.white,
                                         borderRadius: BorderRadius.circular(12),
                                         boxShadow: const [
                                           BoxShadow(
                                             color: Colors.black12,
                                             blurRadius: 6,
                                             offset: Offset(0, 3),
                                           ),
                                         ],
                                       ),
                                       child: Column(
                                         mainAxisAlignment:
                                             MainAxisAlignment.spaceBetween,
                                         children: [
                                           Expanded(
                                             child: p['image'] != ''
                                                 ? FutureBuilder<Uint8List?>(
                                                     future: _fetchImageBytes(p['image']),
                                                     builder: (context, snap) {
                                                       if (snap.connectionState == ConnectionState.waiting) {
                                                         return Container(
                                                           color: Colors.grey.shade100,
                                                           alignment: Alignment.center,
                                                           child: const CircularProgressIndicator(strokeWidth: 2),
                                                         );
                                                       }
                                                       final bytes = snap.data;
                                                       if (bytes == null || bytes.isEmpty) {
                                                         return Container(
                                                           color: Colors.grey.shade200,
                                                           alignment: Alignment.center,
                                                           child: const Icon(Icons.broken_image, color: Colors.grey),
                                                         );
                                                       }
                                                       return Image.memory(
                                                         bytes,
                                                         fit: BoxFit.cover,
                                                         gaplessPlayback: true,
                                                       );
                                                     },
                                                   )
                                                 : const Icon(Icons.photo),
                                           ),
                                           Padding(
                                             padding: const EdgeInsets.all(8.0),
                                             child: Column(
                                               children: [
                                                 Text(
                                                   p['name'] ?? 'Producto',
                                                   maxLines: 2,
                                                   overflow: TextOverflow.ellipsis,
                                                 ),
                                                 const SizedBox(height: 4),
                                                 Text(
                                                   '${p['price']} €',
                                                   style: const TextStyle(
                                                     color: Colors.green,
                                                     fontWeight: FontWeight.bold,
                                                   ),
                                                 ),
                                               ],
                                             ),
                                           ),
                                         ],
                                       ),
                                    ),
                                  );
                                 },
                              ),
                      ),
                      if (_visibleCount < _filteredProducts.length)
                        Center(
                          child: ElevatedButton(
                            onPressed: () =>
                                setState(() => _visibleCount += 8),
                            child: const Text('Ver más'),
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }
}
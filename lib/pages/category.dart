import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  /// 🔁 Función recursiva para obtener todos los IDs de subcategorías
  Future<List<String>> _getAllSubcategoryIds(String parentId) async {
    final url =
        '$_baseUrl/categories?ws_key=$_apiKey&output_format=JSON&display=[id,id_parent]&filter[id_parent]=$parentId';
    final resp = await http.get(Uri.parse(url));

    if (resp.statusCode != 200) return [];

    final data = json.decode(resp.body);
    if (data is! Map || data['categories'] == null) return [];

    final List categories = data['categories'];
    List<String> ids = [];

    for (final cat in categories) {
      final String id = cat['id'].toString();
      ids.add(id);

      // 👇 Recursivo: obtener subcategorías de esta subcategoría
      final subIds = await _getAllSubcategoryIds(id);
      ids.addAll(subIds);
    }

    return ids;
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _loading = true;
      _error = false;
    });

    try {
      final String idCat = widget.category['id'].toString();

      // 1️⃣ Obtener todas las subcategorías (recursivamente)
      List<String> allIds = [idCat];
      final subIds = await _getAllSubcategoryIds(idCat);
      allIds.addAll(subIds);

      // Quitar duplicados
      allIds = allIds.toSet().toList();

      // 2️⃣ Construir filtro con todos los IDs: [1|2|3|4|...]
      final filter = '[${allIds.join('|')}]';

      final url =
          '$_baseUrl/products?ws_key=$_apiKey&output_format=JSON&display=[id,name,price,id_category_default,id_default_image]&filter[id_category_default]=$filter&filter[active]=1';

      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) throw Exception('Error al cargar productos');

      final data = json.decode(resp.body);
      final List<dynamic>? items = data['products'];

      if (items == null) throw Exception('Sin productos');

      final List<Map<String, dynamic>> products = items.map((it) {
        final pid = it['id']?.toString() ?? '';
        final name = it['name']?.toString() ?? 'Producto';
        final price = it['price']?.toString() ?? '';
        final imgId = it['id_default_image']?.toString() ?? '';
        final imgUrl = imgId.isNotEmpty
            ? 'https://www.farmaciaguerrerozieza.com/img/p/$imgId.jpg'
            : '';
        return {'id': pid, 'name': name, 'price': price, 'image': imgUrl};
      }).toList();

      setState(() {
        _products = products;
        _filteredProducts = products; // Inicialmente muestra todos
        _loading = false;
      });
    } catch (e) {
      print('❌ Error: $e');
      setState(() {
        _error = true;
        _loading = false;
      });
    }
  }

  void _filterProducts(String query) {
    setState(() {
      _searchText = query;
      _filteredProducts = _products
          .where((p) =>
              p['name'].toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
      _visibleCount = 8; // Reiniciamos el contador al buscar
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Widget _buildIcon(BuildContext context) {
    final image = widget.category['image'] as String?;
    if (image != null && image.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(image, width: 64, height: 64, fit: BoxFit.cover),
      );
    }
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
                                  return Container(
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
                                              ? Image.network(
                                                  p['image'],
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      const Icon(Icons.photo),
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

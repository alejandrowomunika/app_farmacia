import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/app_layout.dart';
import 'category.dart';

class TiendaPage extends StatefulWidget {
  const TiendaPage({super.key});

  @override
  State<TiendaPage> createState() => _TiendaPageState();
}

class _TiendaPageState extends State<TiendaPage> {
  int selectedIndex = 1; // Productos en footer

  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _categories = [];


  // URL proporcionada (usa la que diste)
  final String _url =
      'https://www.farmaciaguerrerozieza.com/api/categories?ws_key=CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS&output_format=JSON&display=[id,name,id_parent]&filter[id_parent]=2&filter[active]=1';
  
  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  void onFooterTap(int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 1) {
      // ya estás aquí
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/chat');
    } else if (index == 3) {
      Navigator.pushReplacementNamed(context, '/user');
    }
  }

  Future<void> _fetchCategories() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final resp = await http.get(Uri.parse(_url)).timeout(const Duration(seconds: 12));

      if (resp.statusCode != 200) {
        throw Exception('Error HTTP ${resp.statusCode}');
      }

      final body = resp.body;
      final jsonData = json.decode(body);

      // Prestar atención a la estructura posible del JSON.
      // Intentamos encontrar un array de categorías en varios lugares comunes.
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
          // buscar recursivamente por primer array de objetos con 'id' y 'name'
          jsonData.forEach((k, v) {
            if (items == null && v is List) items = v;
          });
        }
      }

      items ??= [];

      final List<Map<String, dynamic>> parsed = [];

      for (final it in items ?? []) {
        if (it is Map<String, dynamic>) {
          final id = (it['id'] ?? it['id_category'] ?? it['category_id'])?.toString();
          final name = (it['name'] ?? it['category_name']) ??
              // si el nombre viene con estructura multilenguaje en PrestaShop:
              ((it['name'] is Map && it['name']['language'] is List)
                  ? (it['name']['language'][0]['value'] ?? '')
                  : '');
          if (id != null) {
            // Intentamos construir una URL de imagen típica de PrestaShop
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
  
  @override
  Widget build(BuildContext context) {
    return AppLayout(
      currentIndex: selectedIndex,
      onFooterTap: onFooterTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Categorías',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error.isNotEmpty)
              Expanded(
                child: Center(
                  child: Text(_error, textAlign: TextAlign.center),
                ),
              )
            else
              Expanded(
                child: GridView.builder(
                  itemCount: _categories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final name = cat['name'] ?? 'Categoría';

                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryPage(category: {
                              'id': cat['id'],
                              'label': name,
                              'icon': Icons.category,
                              'bg': Colors.white, // fondo blanco
                              'color': Colors.black,
                              'imageJpg': cat['imageJpg'],  
                              'imagePng': cat['imagePng'],
                            }),
                          ),
                        );
                      },
                      child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white, // fondo base blanco
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 36,
                            child: Center(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 50,
                                  height: 40,
                                  child: (cat['imageJpg'] != null &&
                                          cat['imageJpg'].toString().isNotEmpty)
                                      ? Image.network(
                                          cat['imageJpg'],
                                          fit: BoxFit.cover,
                                          width: 86,
                                          height: 86,
                                          errorBuilder: (context, error, stackTrace) {
                                            final png = cat['imagePng'] ?? '';
                                            if (png.isNotEmpty) {
                                              return Image.network(
                                                png,
                                                fit: BoxFit.cover,
                                                width: 86,
                                                height: 86,
                                                errorBuilder: (c, e, s) =>
                                                    const Icon(Icons.photo, size: 36, color: Colors.black87),
                                              );
                                            }
                                            return const Icon(Icons.photo,
                                                size: 36, color: Colors.black87);
                                          },
                                        )
                                      : const Icon(Icons.photo, size: 36, color: Colors.black87),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),

                    );

                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
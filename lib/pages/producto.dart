import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/header.dart';
import '../widgets/footer.dart';

class ProductPage extends StatefulWidget {
  final Map<String, dynamic> product; // espera {id,name,price,image}

  const ProductPage({super.key, required this.product});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final Map<String, Uint8List?> _imageCache = {};
  bool _loading = true;
  String _error = '';
  // ------------------ ADICIONES ------------------
    int selectedIndex = 0;

    void onFooterTap(int index) {
      setState(() => selectedIndex = index);

      if (index == 0) {
        Navigator.pushReplacementNamed(context, '/');
      } else if (index == 1) {
        Navigator.pushReplacementNamed(context, '/tienda');
      } else if (index == 2) {
        Navigator.pushReplacementNamed(context, '/chat');
      } else if (index == 3) {
        Navigator.pushReplacementNamed(context, '/user');
      }
    }

    @override
    void initState() {
      super.initState();
      _loading = false;
    }

  Future<Uint8List?> _fetchImageBytes(String url) async {
    if (url.isEmpty) return null;
    if (_imageCache.containsKey(url)) return _imageCache[url];
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (!mounted) return null;
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        _imageCache[url] = resp.bodyBytes;
        return resp.bodyBytes;
      } else {
        _imageCache[url] = null;
        return null;
      }
    } catch (e) {
      _imageCache[url] = null;
      return null;
    }
  }

  @override
  void dispose() {
    _imageCache.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prod = widget.product;
    final name = (prod['name'] ?? prod['label'] ?? 'Producto').toString();
    final price = (prod['price'] ?? '').toString();
    final imageUrl = (prod['image'] ?? prod['imageUrl'] ?? '').toString();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header: usar el mismo que en main.dart
           const AppHeader(),

            // Contenido principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Imagen principal
                    AspectRatio(
                      aspectRatio: 1.2,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: imageUrl.isEmpty
                            ? Container(
                                color: Colors.grey.shade100,
                                alignment: Alignment.center,
                                child: const Icon(Icons.photo, size: 48, color: Colors.grey),
                              )
                            : FutureBuilder<Uint8List?>(
                                future: _fetchImageBytes(imageUrl),
                                builder: (context, snap) {
                                  if (snap.connectionState == ConnectionState.waiting) {
                                    return Container(
                                      color: Colors.grey.shade100,
                                      alignment: Alignment.center,
                                      child: const CircularProgressIndicator(),
                                    );
                                  }
                                  final bytes = snap.data;
                                  if (bytes == null || bytes.isEmpty) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                    );
                                  }
                                  return Image.memory(
                                    bytes,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    gaplessPlayback: true,
                                  );
                                },
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Nombre y precio
                    Text(
                      name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      price.isNotEmpty ? '$price €' : 'Precio no disponible',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.green),
                    ),

                    const SizedBox(height: 18),

                    // Información/acciones básicas (añade si quieres más)
                    ElevatedButton(
                      onPressed: () {
                        // ejemplo: añadir al carrito (implementa según tu app)
                      },
                      child: const Text('AÑADIR AL CARRITO'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ],
                ),
              ),
            ),

           
          ],
        ),
      ),
      // footer en bottomNavigationBar para que siempre quede accesible
      bottomNavigationBar: AppFooter(
        currentIndex: selectedIndex,
        onTap: onFooterTap,
      ),
    );
  }
}
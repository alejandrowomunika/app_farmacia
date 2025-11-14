import 'dart:async';
import 'dart:convert';
import 'package:app_farmacia/pages/category.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'widgets/header.dart';
import 'widgets/footer.dart';
import 'pages/tienda.dart';
import 'pages/user.dart';
import 'pages/chat.dart';
import 'dart:typed_data';

import 'theme/app_theme.dart';

// CONFIGURACIÓN API
const String baseUrl = 'https://www.farmaciaguerrerozieza.com';
const String apiKey = 'CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS';

void main() {
  runApp(const MainApp());
}

// APP ROOT
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmacia App',
      initialRoute: '/',
      routes: {
        '/': (context) => const ProductsScreen(),
        '/tienda': (context) => const TiendaPage(),
        '/chat': (context) => const Chat(),
        '/user': (context) => const UserPage(),
      },
    );
  }
}

// PANTALLA PRINCIPAL
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // ------ SLIDER DEL CMS (ID = 15) ------
  List<Map<String, String>> sliderItems = [];
  bool loadingSlider = true;

  // Pedir HTML del CMS y extraer imágenes <img src="...">
  Future<List<Map<String, String>>> loadSliderItems() async {
  const String url =
      'https://www.farmaciaguerrerozieza.com/api/content_management_system'
      '?ws_key=CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS'
      '&output_format=JSON'
      '&display=[id,content]'
      '&filter[id]=15';

  try {
    final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      print('loadSliderItems: HTTP ${response.statusCode}');
      return [];
    }

    final decoded = json.decode(response.body);
    final html = (decoded is Map && decoded['content_management_system'] != null)
        ? decoded['content_management_system'][0]['content'].toString()
        : response.body;

    // 1) extraer posibles src (src, data-src, data-lazy, data-original) y srcset
    final imgAttrRegex =
        RegExp(r"(?:src|data-src|data-lazy|data-original)=['\']?([^'\'>\s]+)", caseSensitive: false);
    final srcsetRegex = RegExp(r"srcset=['\']([^'\']+)['\']", caseSensitive: false);
    final imgMatches = <String>[];

    for (final m in imgAttrRegex.allMatches(html)) {
      final src = (m.group(1) ?? '').trim();
      if (src.isNotEmpty) imgMatches.add(src);
    }

    for (final m in srcsetRegex.allMatches(html)) {
      final set = (m.group(1) ?? '').trim();
      if (set.isEmpty) continue;
      final first = set.split(',').first.split(' ').first.trim();
      if (first.isNotEmpty && !imgMatches.contains(first)) imgMatches.add(first);
    }

    List<String> normalize(List<String> list) {
      return list.map((s) {
        var src = s.trim();
        if (src.startsWith('//')) src = 'https:$src';
        if (src.startsWith('/')) src = 'https://www.farmaciaguerrerozieza.com$src';
        if (src.startsWith('http://')) src = src.replaceFirst('http://', 'https://');
        return src;
      }).where((u) => u.isNotEmpty).toList();
    }

    final images = normalize(imgMatches).toSet().toList(); // dedupe

    // 2) extraer todos los h1 (limpios)
    final h1Regex = RegExp(r'<h1[^>]*>(.*?)</h1>', caseSensitive: false, dotAll: true);
    final h1Matches = h1Regex
        .allMatches(html)
        .map((m) => (m.group(1) ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // 3) buscar bloques <img ...> ... <h1> ... </h1>
    final blockRegex =
        RegExp(r'(<img\b[^>]*>).*?<h1[^>]*>([^<]+)</h1>', caseSensitive: false, dotAll: true);
    final blockMatches = blockRegex.allMatches(html);
    final List<Map<String, String>> items = [];

    if (blockMatches.isNotEmpty) {
      for (final b in blockMatches) {
        final imgTag = b.group(1) ?? '';
        final srcMatch = imgAttrRegex.firstMatch(imgTag);
        var src = srcMatch?.group(1) ?? '';
        src = src.trim();
        if (src.isEmpty) continue;
        if (src.startsWith('//')) src = 'https:$src';
        if (src.startsWith('/')) src = 'https://www.farmaciaguerrerozieza.com$src';
        if (src.startsWith('http://')) src = src.replaceFirst('http://', 'https://');

        final title = (b.group(2) ?? '').replaceAll(RegExp(r'<[^>]*>'), '').trim();
        items.add({'image': src, 'title': title});
      }
    }

    // 4) fallback: emparejar por índice images[i] con h1[i]
    if (items.isEmpty && images.isNotEmpty) {
      for (int i = 0; i < images.length; i++) {
        final img = images[i];
        final title = (i < h1Matches.length) ? h1Matches[i] : '';
        items.add({'image': img, 'title': title});
      }
    }

    // debug
    print(
        'loadSliderItems: found images=${images.length} h1s=${h1Matches.length} blocks=${blockMatches.length} items=${items.length}');
    for (var it in items.take(5)) {
      print(' - item image=${it['image']} title=${it['title']}');
    }

    // Evict opcional para forzar recarga en caso de caché
    for (final it in items) {
      final urlStr = it['image'];
      if (urlStr != null && urlStr.isNotEmpty) {
        try {
          await NetworkImage(urlStr).evict();
        } catch (_) {}
      }
    }

    return items;
  } catch (e) {
    print('loadSliderItems error: $e');
    return [];
  }
}

  // Extraer imágenes del HTML
  List<String> extractImageUrls(String html) {
    final regex = RegExp(r'src="([^"]+)"');
    final matches = regex.allMatches(html);

    return matches.map((m) {
      String url = m.group(1)!;

      if (url.startsWith('/')) {
        url = 'https://www.farmaciaguerrerozieza.com$url';
      }

      return url;
    }).toList();
  }

  bool isLoading = true;
  String error = '';
  List<Map<String, dynamic>> products = [];

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();

    // Cargar items del CMS para el slideshow
    loadSliderItems().then((items) {
      if (!mounted) return;
      setState(() {
        sliderItems = items;
        loadingSlider = false;
      });
    });

    fetchProducts();
  }

  // FOOTER NAV
  void onFooterTap(int index) {
    setState(() => selectedIndex = index);

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const ProductsScreen()),
      );
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TiendaPage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const Chat()),
      );
    } else if (index == 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UserPage()),
      );
    }
  }

  // GENERA URL DE IMAGEN DE PRESTASHOP
  String buildPrestashopImageUrl(int imgId) {
    final digits = imgId.toString().split('');
    final path = digits.join('/');
    return "$baseUrl/img/p/$path/$imgId-home_default.jpg";
  }

  // PEDIR PRODUCTOS Y STOCK
  Future<void> fetchProducts() async {
    try {
      final url =
          '$baseUrl/api/products?ws_key=$apiKey&display=full&output_format=JSON&filter[id_category_default]=5';

      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode != 200) {
        setState(() {
          error = "Error al cargar productos: ${response.statusCode}";
          isLoading = false;
        });
        return;
      }

      final decoded = json.decode(response.body);
      final List rawProducts = decoded["products"];

      // Tomamos SOLO los 6 primeros
      final limitedProducts = rawProducts.take(2).toList();

      List<Map<String, dynamic>> finalList = [];

      for (var p in limitedProducts) {
        final int productId = int.tryParse(p["id"].toString()) ?? 0;

        String name = p["name"] ?? "Sin nombre";

        double price = 0.0;
        if (p["price"] is String) {
          price = double.tryParse(p["price"]) ?? 0.0;
        }

        // STOCK
        int stock = 0;

        final stockUrl =
            "$baseUrl/api/stock_availables?ws_key=$apiKey&output_format=JSON&display=full&filter[id_product]=$productId";

        final stockResp = await http.get(Uri.parse(stockUrl));

        if (stockResp.statusCode == 200) {
          final stockDecoded = json.decode(stockResp.body);

          if (stockDecoded["stock_availables"] is List &&
              stockDecoded["stock_availables"].isNotEmpty) {
            stock =
                int.tryParse(
                  stockDecoded["stock_availables"][0]["quantity"].toString(),
                ) ??
                0;
          }
        }

        // IMAGEN
        int imgId = 0;
        if (p["associations"]?["images"] is List &&
            p["associations"]["images"].isNotEmpty) {
          imgId =
              int.tryParse(p["associations"]["images"][0]["id"].toString()) ??
              0;
        }

        String imageUrl = imgId > 0 ? buildPrestashopImageUrl(imgId) : "";

        finalList.add({
          "name": name,
          "price": price,
          "stock": stock,
          "id": productId,
          "image": imageUrl,
        });
      }

      setState(() {
        products = finalList;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = "Error inesperado: $e";
        isLoading = false;
      });
    }
  }

  // UI PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // body ahora es un CustomScrollView con slivers para permitir scroll vertical correcto
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                const AppHeader(),
                const SizedBox(height: 10),

                // CARRUSEL INFINITO
                Padding(
                  padding: const EdgeInsets.only(bottom: 0),
                  child: SizedBox(
                    height: 92,
                    child: InfiniteCarousel(
                      items: CardInfo.values
                          .map(
                            (info) => InkWell(
                              onTap: () =>
                                  Navigator.pushNamed(context, '/products'),
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                                decoration: BoxDecoration(
                                  color: info.backgroundColor,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Colors.black12,
                                      offset: Offset(1, 0),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        info.icon,
                                        color: info.color,
                                        size: 28,
                                      ),
                                      const SizedBox(height: 6),
                                      SizedBox(
                                        width: 80,
                                        child: Text(
                                          info.label,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),

                // SLIDESHOW GRANDE
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      width: double.infinity,
                      child: loadingSlider
                          ? const Center(child: CircularProgressIndicator())
                          : (sliderItems.isEmpty
                              ? const Center(child: Text("No hay imágenes disponibles"))
                              : FadeImageCarousel(items: sliderItems)),
                    ),
                  ),
                ),

                // BANNER debajo del slideshow
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 8.0,
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 20 / 5,
                        child: Image.asset(
                          'assets/banner.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: Colors.grey.shade200,
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.broken_image,
                                  size: 36,
                                  color: Colors.grey,
                                ),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),

          // GRID DE PRODUCTOS como SliverGrid para integrarse en el scroll
          isLoading
              ? SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : error.isNotEmpty
              ? SliverFillRemaining(
                  child: Center(child: Text(error, style: AppText.subtitle)),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final p = products[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppStyles.radius,
                          boxShadow: [AppStyles.shadow],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: p["image"] != ""
                                    ? Image.network(
                                        p["image"],
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image_not_supported,
                                        size: 60,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p["name"],
                              maxLines: 3,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.small.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${p["price"].toStringAsFixed(2)} €",
                              style: AppText.subtitle.copyWith(
                                color: AppColors.green600,
                              ),
                            ),
                            Text(
                              "Stock: ${p["stock"]}",
                              style: AppText.small.copyWith(
                                color: AppColors.purple600,
                              ),
                            ),
                            Text("ID: ${p["id"]}"),
                          ],
                        ),
                      );
                    }, childCount: products.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.5,
                        ),
                  ),
                ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 10),

                // // SLIDESHOW GRANDE
                // Padding(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 12,
                //   ), // <- 12 px a los laterales
                //   child: ClipRRect(
                //     borderRadius: BorderRadius.circular(
                //       5,
                //     ), // <- redondez de 12 px
                //     child: SizedBox(
                //       height: MediaQuery.of(context).size.height * 0.55,
                //       width: double.infinity,
                //       child: FadeImageCarousel(
                //         images: [
                //           'assets/a.webp',
                //           'assets/c.webp',
                //           'assets/b.webp',
                //         ],
                //       ),
                //     ),
                //   ),
                // ),

                const SizedBox(height: 6),
              ],
            ),
          ),
          // GRID DE PRODUCTOS como SliverGrid para integrarse en el scroll
          isLoading
              ? SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              : error.isNotEmpty
              ? SliverFillRemaining(
                  child: Center(child: Text(error, style: AppText.subtitle)),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final p = products[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: AppStyles.radius,
                          boxShadow: [AppStyles.shadow],
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Expanded(
                              flex: 6,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: p["image"] != ""
                                    ? Image.network(
                                        p["image"],
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => const Icon(
                                          Icons.broken_image,
                                          size: 50,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.image_not_supported,
                                        size: 60,
                                      ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p["name"],
                              maxLines: 3,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: AppText.small.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              "${p["price"].toStringAsFixed(2)} €",
                              style: AppText.subtitle.copyWith(
                                color: AppColors.green600,
                              ),
                            ),
                            Text(
                              "Stock: ${p["stock"]}",
                              style: AppText.small.copyWith(
                                color: AppColors.purple600,
                              ),
                            ),
                            Text("ID: ${p["id"]}"),
                          ],
                        ),
                      );
                    }, childCount: products.length),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.5,
                        ),
                  ),
                ),
        ],
      ),

      // footer en bottomNavigationBar para que siempre quede accesible
      bottomNavigationBar: AppFooter(
        currentIndex: selectedIndex,
        onTap: onFooterTap,
      ),
    );
  }
}

// ENUM CON LOS ÍCONOS DEL CARRUSEL
enum CardInfo {
  cuidadoCorporal(
    'CUIDADO CORPORAL',
    Icons.spa,
    Color(0xff8E63D2),
    Color(0xffF1E8FF),
  ),

  optica('ÓPTICA', Icons.visibility, Color(0xff3A86FF), Color(0xffE4EFFF)),

  medicacionFamiliar(
    'MEDICACIÓN FAMILIAR',
    Icons.medication,
    Color(0xffFF595E),
    Color(0xffFFE5E6),
  ),

  higieneCapilar(
    'HIGIENE CAPILAR',
    Icons.water_drop,
    Color(0xff0096C7),
    Color(0xffDFF7FF),
  ),

  cuidadoPaciente(
    'CUIDADO DEL PACIENTE',
    Icons.health_and_safety,
    Color(0xff6A4C93),
    Color(0xffEFE7FF),
  ),

  formulacionMagistral(
    'FORMULACIÓN MAGISTRAL',
    Icons.science,
    Color(0xffFF8500),
    Color(0xffFFF1DE),
  ),

  higieneBucodental(
    'HIGIENE BUCODENTAL',
    Icons.brush,
    Color(0xff2A9D8F),
    Color(0xffDBFFF7),
  ),

  mobiliario('MOBILIARIO', Icons.chair, Color(0xff8D99AE), Color(0xffF4F6F8)),

  dermocosmetica(
    'DERMOCOSMÉTICA',
    Icons.face,
    Color(0xffF28482),
    Color(0xffFFECEC),
  ),

  sGenerica('S.', Icons.category, Color(0xff6C757D), Color(0xffF2F2F2)),

  sinFamilia(
    'SIN FAMILIA',
    Icons.help_outline,
    Color(0xffADB5BD),
    Color(0xffF7F7F7),
  ),

  solares('SOLARES', Icons.wb_sunny, Color(0xffFFB703), Color(0xffFFF7D9)),

  dietetica(
    'DIETÉTICA Y NUTRICIÓN',
    Icons.restaurant_menu,
    Color(0xff52B788),
    Color(0xffE9FFF3),
  ),

  infantil(
    'INFANTIL',
    Icons.child_friendly,
    Color(0xffFF9EAA),
    Color(0xffFFE8EC),
  ),

  ortopedia(
    'ORTOPEDIA',
    Icons.accessibility_new,
    Color(0xff4C6EF5),
    Color(0xffE5EBFF),
  ),

  covid('COVID', Icons.coronavirus, Color(0xffE63946), Color(0xffFFE6E8)),

  terapiasNaturales(
    'TERAPIAS NATURALES',
    Icons.eco,
    Color(0xff2A9D8F),
    Color(0xffDBFFF7),
  ),

  prescripcion(
    'PRESCRIPCIÓN',
    Icons.receipt_long,
    Color(0xff5C677D),
    Color(0xffEEF2F7),
  ),

  otraParafarmacia(
    'OTRA PARAFARMACIA FI',
    Icons.store,
    Color(0xff6D597A),
    Color(0xffF3ECF7),
  ),

  veterinaria('VETERINARIA', Icons.pets, Color(0xff7F4F24), Color(0xffF5EDE3)),

  saludSexual(
    'SALUD SEXUAL',
    Icons.favorite,
    Color(0xffFF006E),
    Color(0xffFFD6E8),
  ),

  homeopatia('HOMEOPATÍA', Icons.opacity, Color(0xff38A3A5), Color(0xffE9FFFB)),

  efectosAccesorios(
    'EFECTOS Y ACCESORIOS',
    Icons.backpack,
    Color(0xff6C757D),
    Color(0xffF2F2F2),
  );

  const CardInfo(this.label, this.icon, this.color, this.backgroundColor);
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

// CARROUSEL INFINITO (auto-play que se pausa al interactuar)
class InfiniteCarousel extends StatefulWidget {
  final List<Widget> items;

  const InfiniteCarousel({super.key, required this.items});

  @override
  State<InfiniteCarousel> createState() => _InfiniteCarouselState();
}

class _InfiniteCarouselState extends State<InfiniteCarousel> {
  late final PageController _controller;
  int _currentPage = 1000; // empieza lejos para simular infinito
  bool _isUserInteracting = false;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.28, // tamaño de cada item
    );

    _startAutoPlay();
  }

  void _startAutoPlay() async {
    while (mounted && _running) {
      await Future.delayed(const Duration(seconds: 8));
      if (!mounted) break;

      // esperar mientras el usuario está interactuando con el carrusel
      while (mounted && _isUserInteracting) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (!mounted) break;

      // asegúrate de partir desde la página actual real
      final nextPage = (_currentPage) + 1;
      _currentPage = nextPage;
      try {
        await _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOut,
        );
      } catch (_) {
        // La animación puede ser interrumpida por la interacción del usuario; ignorar
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Listener detecta toques/arrastres incluso si PageView gestiona el gesto
      onPointerDown: (_) {
        _isUserInteracting = true;
      },
      onPointerUp: (_) {
        // Al soltar, actualizamos la página actual desde el controller para sincronizar
        _isUserInteracting = false;
        final page = _controller.hasClients
            ? (_controller.page?.round())
            : null;
        if (page != null) {
          _currentPage = page;
        }
      },
      onPointerCancel: (_) => _isUserInteracting = false,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (index) {
          // Mantener _currentPage sincronizado con el índice real
          _currentPage = index;
        },
        itemBuilder: (_, index) {
          final realIndex = index % widget.items.length;
          return widget.items[realIndex];
        },
      ),
    );
  }

  @override
  void dispose() {
    _running = false;
    _controller.dispose();
    super.dispose();
  }
}

// CARRUSEL DE IMÁGENES CON FADE
class FadeImageCarousel extends StatefulWidget {
  final List<Map<String, String>> items;

  const FadeImageCarousel({super.key, required this.items});

  @override
  State<FadeImageCarousel> createState() => _FadeImageCarouselState();
}

class _FadeImageCarouselState extends State<FadeImageCarousel>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  Timer? _timer;
  final Map<String, Uint8List?> _bytesCache = {};

  @override
  void initState() {
    super.initState();
    if (widget.items.isNotEmpty) {
      _timer = Timer.periodic(const Duration(seconds: 6), (_) {
        if (!mounted) return;
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.items.length;
        });
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<Uint8List?> _fetchBytes(String url) async {
    if (_bytesCache.containsKey(url)) return _bytesCache[url];
    try {
      final resp = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        _bytesCache[url] = resp.bodyBytes;
        return resp.bodyBytes;
      } else {
        _bytesCache[url] = null;
        print('Image fetch failed: status=${resp.statusCode} url=$url');
        return null;
      }
    } catch (e) {
      _bytesCache[url] = null;
      print('Image fetch error: $e url=$url');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const Center(child: Text('No hay imágenes'));
    final item = widget.items[_currentIndex];
    final imgUrl = (item['image'] ?? '').trim();
    final title = item['title'] ?? '';

    return AspectRatio(
      aspectRatio: 16 / 8,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 700),
        child: GestureDetector(
          key: ValueKey(imgUrl + _currentIndex.toString()),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CategoryPage(category: {
                  'label': title,
                  'imageUrl': imgUrl,
                }),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imgUrl.isEmpty
                ? Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                  )
                : FutureBuilder<Uint8List?>(
                    future: _fetchBytes(imgUrl),
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
      ),
    );
  }
}
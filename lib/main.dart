import 'dart:async';
import 'dart:convert';
import 'package:app_farmacia/pages/SplashAnimated.dart';
import 'package:app_farmacia/pages/carrito.dart';
import 'package:app_farmacia/pages/producto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'widgets/header.dart';
import 'widgets/footer.dart';
import 'pages/tienda.dart';
import 'pages/user.dart';
import 'pages/chat.dart';

import 'theme/app_theme.dart';

// ═══════════════════════════════════════════════════════════
// CONFIGURACIÓN API
// ═══════════════════════════════════════════════════════════
const String baseUrl = 'https://www.farmaciaguerrerozieza.com';
const String apiKey = 'CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS';

void main() {
  runApp(const MainApp());
}

// ═══════════════════════════════════════════════════════════
// APP ROOT
// ═══════════════════════════════════════════════════════════
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Farmacia App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Mulish',
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.green500,
          primary: AppColors.green500,
          secondary: AppColors.purple500,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const ProductsScreen(),
        '/tienda': (context) => const TiendaPage(),
        '/chat': (context) => const Chat(),
        '/user': (context) => const UserPage(),
        '/splash': (context) => SplashAnimated(),
        '/producto': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ProductPage(id: args['id']);
        },
        "/carrito": (context) => const CarritoPage(),
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PANTALLA PRINCIPAL (HOME)
// ═══════════════════════════════════════════════════════════
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  // ─────────────────────────────────────────────────────────
  // VARIABLES DE ESTADO
  // ─────────────────────────────────────────────────────────
  List<String> sliderImages = [];
  List<String> slider1Images = [];
  List<String> slider2Images = [];
  bool loadingSlider = true;

  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> products2 = [];
  bool isLoading = true;
  String error = "";

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    await Future.wait([
      _loadSliderImages(),
      fetchProducts(),
      fetchProducts2(),
    ]);
  }

  // ─────────────────────────────────────────────────────────
  // CARGAR IMÁGENES DEL SLIDER (CMS)
  // ─────────────────────────────────────────────────────────
  Future<void> _loadSliderImages() async {
    final imgs = await loadSliderImages();
    if (!mounted) return;

    setState(() {
      sliderImages = imgs;
      loadingSlider = false;

      slider1Images = [];
      slider2Images = [];

      if (imgs.isNotEmpty) {
        slider1Images = imgs.sublist(0, imgs.length >= 3 ? 3 : imgs.length);
      }

      if (imgs.length > 3) {
        slider2Images = imgs.sublist(3, imgs.length >= 6 ? 6 : imgs.length);
      }
    });
  }

  Future<List<String>> loadSliderImages() async {
    const String url =
        'https://www.farmaciaguerrerozieza.com/api/content_management_system'
        '?ws_key=CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS'
        '&output_format=JSON'
        '&display=[id,content]'
        '&filter[id]=15';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return [];

      final decoded = json.decode(response.body);
      final html = decoded["content_management_system"][0]["content"];
      final imgs = extractImageUrls(html);

      for (final imgUrl in imgs) {
        try {
          await NetworkImage(imgUrl).evict();
        } catch (_) {}
      }

      return imgs;
    } catch (e) {
      return [];
    }
  }

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

  // ─────────────────────────────────────────────────────────
  // UTILIDADES
  // ─────────────────────────────────────────────────────────
  String buildPrestashopImageUrl(int imgId) {
    final digits = imgId.toString().split('');
    final path = digits.join('/');
    return "$baseUrl/img/p/$path/$imgId-home_default.jpg";
  }

  // ─────────────────────────────────────────────────────────
  // FETCH PRODUCTOS (Categoría 5 - Destacados)
  // ─────────────────────────────────────────────────────────
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
      final limitedProducts = rawProducts.take(5).toList();

      List<Map<String, dynamic>> finalList = [];

      for (var p in limitedProducts) {
        final int productId = int.tryParse(p["id"].toString()) ?? 0;
        String name = p["name"] ?? "Sin nombre";

        double price = 0.0;
        if (p["price"] is String) {
          price = double.tryParse(p["price"]) ?? 0.0;
        }

        // Stock
        int stock = 0;
        final stockUrl =
            "$baseUrl/api/stock_availables?ws_key=$apiKey&output_format=JSON&display=full&filter[id_product]=$productId";
        final stockResp = await http.get(Uri.parse(stockUrl));

        if (stockResp.statusCode == 200) {
          final stockDecoded = json.decode(stockResp.body);
          if (stockDecoded["stock_availables"] is List &&
              stockDecoded["stock_availables"].isNotEmpty) {
            stock = int.tryParse(
                  stockDecoded["stock_availables"][0]["quantity"].toString(),
                ) ?? 0;
          }
        }

        // Imagen
        int imgId = 0;
        if (p["associations"]?["images"] is List &&
            p["associations"]["images"].isNotEmpty) {
          imgId = int.tryParse(p["associations"]["images"][0]["id"].toString()) ?? 0;
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

  // ─────────────────────────────────────────────────────────
  // FETCH PRODUCTOS 2 (Categoría 28 - Recomendados)
  // ─────────────────────────────────────────────────────────
  Future<void> fetchProducts2() async {
    try {
      final url =
          '$baseUrl/api/products?ws_key=$apiKey&display=full&output_format=JSON&filter[id_category_default]=28';

      final response = await http.get(Uri.parse(url));

      if (!mounted) return;

      if (response.statusCode != 200) return;

      final decoded = json.decode(response.body);
      final List rawProducts = decoded["products"];
      final limitedProducts = rawProducts.take(5).toList();

      List<Map<String, dynamic>> finalList = [];

      for (var p in limitedProducts) {
        final int productId = int.tryParse(p["id"].toString()) ?? 0;
        String name = p["name"] ?? "Sin nombre";

        double price = 0.0;
        if (p["price"] is String) {
          price = double.tryParse(p["price"]) ?? 0.0;
        }

        int stock = 0;
        final stockUrl =
            "$baseUrl/api/stock_availables?ws_key=$apiKey&output_format=JSON&display=full&filter[id_product]=$productId";
        final stockResp = await http.get(Uri.parse(stockUrl));

        if (stockResp.statusCode == 200) {
          final stockDecoded = json.decode(stockResp.body);
          if (stockDecoded["stock_availables"] is List &&
              stockDecoded["stock_availables"].isNotEmpty) {
            stock = int.tryParse(
                  stockDecoded["stock_availables"][0]["quantity"].toString(),
                ) ?? 0;
          }
        }

        int imgId = 0;
        if (p["associations"]?["images"] is List &&
            p["associations"]["images"].isNotEmpty) {
          imgId = int.tryParse(p["associations"]["images"][0]["id"].toString()) ?? 0;
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
        products2 = finalList;
      });
    } catch (e) {
      debugPrint("Error cargando productos2: $e");
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
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─────────────────────────────────────────────────
            // HEADER + CARRUSEL CATEGORÍAS + SLIDER 1 + BANNER
            // ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const AppHeader(),
                  const SizedBox(height: 8),

                  // CARRUSEL DE CATEGORÍAS
                  _buildCategoryCarousel(),
                  
                  const SizedBox(height: 12),

                  // SLIDESHOW PRINCIPAL
                  _buildMainSlider(),
                  
                  const SizedBox(height: 16),

                  // BANNER CHAT/ASISTENTE
                  _buildChatBanner(),
                ],
              ),
            ),

            // ─────────────────────────────────────────────────
            // PRODUCTOS DESTACADOS
            // ─────────────────────────────────────────────────
            _buildProductsSection(
              title: "PRODUCTOS DESTACADOS",
              subtitle: "Los más populares de nuestra farmacia",
              products: products,
              isLoading: isLoading,
              error: error,
            ),

            // ─────────────────────────────────────────────────
            // SLIDER 2
            // ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 30),
                  _buildSecondarySlider(),
                ],
              ),
            ),

            // ─────────────────────────────────────────────────
            // PRODUCTOS RECOMENDADOS
            // ─────────────────────────────────────────────────
            _buildProductsSection(
              title: "PRODUCTOS RECOMENDADOS",
              subtitle: "Seleccionados especialmente para ti",
              products: products2,
              isLoading: isLoading,
              error: "",
            ),

            // Espacio final
            const SliverToBoxAdapter(
              child: SizedBox(height: 30),
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
  // WIDGET: CARRUSEL DE CATEGORÍAS
  // ═══════════════════════════════════════════════════════════
  Widget _buildCategoryCarousel() {
    return SizedBox(
      height: 95,
      child: InfiniteCarousel(
        items: CardInfo.values.map((info) => _buildCategoryCard(info)).toList(),
      ),
    );
  }

  Widget _buildCategoryCard(CardInfo info) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, '/tienda'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        decoration: BoxDecoration(
          color: info.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
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
                  style: AppText.small.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: SLIDER PRINCIPAL
  // ═══════════════════════════════════════════════════════════
  Widget _buildMainSlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: loadingSlider
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.green500,
                  ),
                )
              : slider1Images.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "No hay imágenes disponibles",
                            style: AppText.body.copyWith(
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                  : FadeImageCarousel(images: slider1Images),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: BANNER CHAT/ASISTENTE
  // ═══════════════════════════════════════════════════════════
  Widget _buildChatBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/chat'),
        child: Container(
          padding: const EdgeInsets.all(11),
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
          child: Row(
            children: [
              // Icono/GIF del asistente
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.green500, AppColors.green400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green500.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.smart_toy_outlined,
                  color: AppColors.white,
                  size: 36,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¿Necesitas ayuda?',
                      style: AppText.subtitle.copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consulta con nuestro asistente farmacéutico inteligente',
                      style: AppText.small.copyWith(
                        color: AppColors.textDark.withOpacity(0.6),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),
                    
                    // Badge "Próximamente" - Purple como detalle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.purple100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.purple200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule,
                            size: 14,
                            color: AppColors.purple600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Próximamente',
                            style: AppText.small.copyWith(
                              color: AppColors.purple600,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
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
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.green600,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: SECCIÓN DE PRODUCTOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildProductsSection({
    required String title,
    required String subtitle,
    required List<Map<String, dynamic>> products,
    required bool isLoading,
    required String error,
  }) {
    if (isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(color: AppColors.green500),
          ),
        ),
      );
    }

    if (error.isNotEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    error,
                    style: AppText.body.copyWith(color: Colors.red.shade700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 30, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.green500,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppText.subtitle.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppText.small.copyWith(
                          color: AppColors.textDark.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Carrusel de productos
            SizedBox(
              height: 265,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.48),
                padEnds: false,
                physics: const BouncingScrollPhysics(),
                itemCount: (products.length >= 5 ? 5 : products.length) + 1,
                itemBuilder: (context, index) {
                  final maxItems = products.length >= 5 ? 5 : products.length;

                  // BOTÓN "VER TODOS"
                  if (index == maxItems) {
                    return _buildViewAllCard();
                  }

                  final product = products[index];
                  return ProductCard(
                    id: product['id'] ?? 0,
                    name: product['name'] ?? '',
                    image: product['image'] ?? '',
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
  // WIDGET: TARJETA "VER TODOS"
  // ═══════════════════════════════════════════════════════════
  Widget _buildViewAllCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/tienda'),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.purple200,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.purple100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
                    size: 36,
                    color: AppColors.purple500,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ver todos',
                  style: AppText.subtitle.copyWith(
                    fontSize: 15,
                    color: AppColors.purple600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'los productos',
                  style: AppText.small.copyWith(
                    color: AppColors.textDark.withOpacity(0.5),
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
  // WIDGET: SLIDER SECUNDARIO
  // ═══════════════════════════════════════════════════════════
  Widget _buildSecondarySlider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.32,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: loadingSlider
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.green500),
                )
              : slider2Images.isEmpty
                  ? Center(
                      child: Text(
                        "No hay imágenes disponibles",
                        style: AppText.body.copyWith(color: Colors.grey.shade500),
                      ),
                    )
                  : FadeImageCarouselSmall(images: slider2Images),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// ENUM: CATEGORÍAS DEL CARRUSEL
// ═══════════════════════════════════════════════════════════════════════════════
enum CardInfo {
  cuidadoCorporal('CUIDADO CORPORAL', Icons.spa_outlined, Color(0xff8E63D2), Color(0xffF1E8FF)),
  optica('ÓPTICA', Icons.visibility_outlined, Color(0xff3A86FF), Color(0xffE4EFFF)),
  medicacionFamiliar('MEDICACIÓN', Icons.medication_outlined, Color(0xffFF595E), Color(0xffFFE5E6)),
  higieneCapilar('HIGIENE CAPILAR', Icons.water_drop_outlined, Color(0xff0096C7), Color(0xffDFF7FF)),
  cuidadoPaciente('CUIDADO PACIENTE', Icons.health_and_safety_outlined, Color(0xff6A4C93), Color(0xffEFE7FF)),
  formulacionMagistral('FORMULACIÓN', Icons.science_outlined, Color(0xffFF8500), Color(0xffFFF1DE)),
  higieneBucodental('BUCODENTAL', Icons.brush_outlined, Color(0xff2A9D8F), Color(0xffDBFFF7)),
  mobiliario('MOBILIARIO', Icons.chair_outlined, Color(0xff8D99AE), Color(0xffF4F6F8)),
  dermocosmetica('DERMOCOSMÉTICA', Icons.face_outlined, Color(0xffF28482), Color(0xffFFECEC)),
  solares('SOLARES', Icons.wb_sunny_outlined, Color(0xffFFB703), Color(0xffFFF7D9)),
  dietetica('DIETÉTICA', Icons.restaurant_menu_outlined, Color(0xff52B788), Color(0xffE9FFF3)),
  infantil('INFANTIL', Icons.child_friendly_outlined, Color(0xffFF9EAA), Color(0xffFFE8EC)),
  ortopedia('ORTOPEDIA', Icons.accessibility_new_outlined, Color(0xff4C6EF5), Color(0xffE5EBFF)),
  covid('COVID', Icons.coronavirus_outlined, Color(0xffE63946), Color(0xffFFE6E8)),
  terapiasNaturales('TERAPIAS NAT.', Icons.eco_outlined, Color(0xff2A9D8F), Color(0xffDBFFF7)),
  veterinaria('VETERINARIA', Icons.pets_outlined, Color(0xff7F4F24), Color(0xffF5EDE3)),
  saludSexual('SALUD SEXUAL', Icons.favorite_outline, Color(0xffFF006E), Color(0xffFFD6E8)),
  homeopatia('HOMEOPATÍA', Icons.opacity_outlined, Color(0xff38A3A5), Color(0xffE9FFFB));

  const CardInfo(this.label, this.icon, this.color, this.backgroundColor);
  final String label;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: CARRUSEL INFINITO
// ═══════════════════════════════════════════════════════════════════════════════
class InfiniteCarousel extends StatefulWidget {
  final List<Widget> items;

  const InfiniteCarousel({super.key, required this.items});

  @override
  State<InfiniteCarousel> createState() => _InfiniteCarouselState();
}

class _InfiniteCarouselState extends State<InfiniteCarousel> {
  late final PageController _controller;
  int _currentPage = 1000;
  bool _isUserInteracting = false;
  bool _running = true;

  @override
  void initState() {
    super.initState();
    _controller = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.28,
    );
    _startAutoPlay();
  }

  void _startAutoPlay() async {
    while (mounted && _running) {
      await Future.delayed(const Duration(seconds: 8));
      if (!mounted) break;

      while (mounted && _isUserInteracting) {
        await Future.delayed(const Duration(milliseconds: 150));
      }
      if (!mounted) break;

      final nextPage = (_currentPage) + 1;
      _currentPage = nextPage;
      try {
        await _controller.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1400),
          curve: Curves.easeOut,
        );
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _isUserInteracting = true,
      onPointerUp: (_) {
        _isUserInteracting = false;
        final page = _controller.hasClients ? (_controller.page?.round()) : null;
        if (page != null) _currentPage = page;
      },
      onPointerCancel: (_) => _isUserInteracting = false,
      child: PageView.builder(
        controller: _controller,
        onPageChanged: (index) => _currentPage = index,
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

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: FADE IMAGE CAROUSEL (Principal)
// ═══════════════════════════════════════════════════════════════════════════════
class FadeImageCarousel extends StatefulWidget {
  final List<String> images;

  const FadeImageCarousel({super.key, required this.images});

  @override
  State<FadeImageCarousel> createState() => _FadeImageCarouselState();
}

class _FadeImageCarouselState extends State<FadeImageCarousel> {
  int _currentIndex = 0;
  late Timer _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    _preloadFirst().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      _preloadRest();
    });

    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || widget.images.isEmpty) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.images.length;
      });
    });
  }

  Future<void> _preloadFirst() async {
    if (widget.images.isEmpty) return;
    final url = widget.images[0];
    try {
      if (url.startsWith('http')) {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } else {
        await precacheImage(AssetImage(url), context);
      }
    } catch (_) {}
  }

  void _preloadRest() {
    for (int i = 1; i < widget.images.length; i++) {
      final url = widget.images[i];
      Future.microtask(() async {
        try {
          if (url.startsWith('http')) {
            await precacheImage(CachedNetworkImageProvider(url), context);
          } else {
            await precacheImage(AssetImage(url), context);
          }
        } catch (_) {}
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Text(
            'No hay imágenes',
            style: AppText.body.copyWith(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final img = widget.images[_currentIndex];
    final isNetwork = img.startsWith('http');

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tienda'),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: !_ready
            ? Container(
                key: const ValueKey('loading'),
                color: AppColors.background,
                child: const Center(
                  child: CircularProgressIndicator(color: AppColors.green500),
                ),
              )
            : isNetwork
                ? CachedNetworkImage(
                    key: ValueKey(img),
                    imageUrl: img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    fadeInDuration: const Duration(milliseconds: 350),
                    placeholder: (_, __) => Container(
                      color: AppColors.background,
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.green500),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.background,
                      child: const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : Image.asset(
                    img,
                    key: ValueKey(img),
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: FADE IMAGE CAROUSEL SMALL (Secundario)
// ═══════════════════════════════════════════════════════════════════════════════
class FadeImageCarouselSmall extends StatefulWidget {
  final List<String> images;

  const FadeImageCarouselSmall({super.key, required this.images});

  @override
  State<FadeImageCarouselSmall> createState() => _FadeImageCarouselSmallState();
}

class _FadeImageCarouselSmallState extends State<FadeImageCarouselSmall> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.images.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.images.isEmpty) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Text(
            'No hay imágenes',
            style: AppText.body.copyWith(color: Colors.grey.shade500),
          ),
        ),
      );
    }

    final currentImg = widget.images[_currentIndex];

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/tienda'),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 800),
        child: CachedNetworkImage(
          key: ValueKey(currentImg),
          imageUrl: currentImg,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          placeholder: (ctx, url) => Container(
            color: AppColors.background,
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.green500,
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (ctx, url, error) => Container(
            color: AppColors.background,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: Colors.grey,
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
class ProductCard extends StatelessWidget {
  final int id;
  final String name;
  final String image;

  const ProductCard({
    super.key,
    required this.id,
    required this.name,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductPage(id: id)),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.white,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 4),
              blurRadius: 12,
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGEN
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                child: image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: image,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Container(
                          color: AppColors.background,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.green500,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 40,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.background,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            size: 40,
                            color: Colors.grey,
                          ),
                        ),
                      ),
              ),
            ),

            // NOMBRE
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.body.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
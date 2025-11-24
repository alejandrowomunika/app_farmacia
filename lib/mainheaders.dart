import 'dart:async';
import 'dart:convert';
import 'package:app_farmacia/pages/producto.dart';
import 'package:app_farmacia/widgets/header2.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';

import 'widgets/header.dart';
import 'widgets/footer.dart';
import 'pages/tienda.dart';
import 'pages/user.dart';
import 'pages/chat.dart';

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
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const ProductsScreen(),
        '/tienda': (context) => const TiendaPage(),
        '/chat': (context) => const Chat(),
        '/user': (context) => const UserPage(),
        '/producto': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProductPage(id: args['id']);
        },
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
  List<String> sliderImages = [];
  List<String> slider1Images = [];
  List<String> slider2Images = [];
  bool loadingSlider = true;

  List<Map<String, dynamic>> products2 = [];
  bool loading2 = true;
  String error2 = "";

  // Pedir HTML del CMS y extraer imágenes <img src="...">
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

      // Evictar imágenes antiguas en el ImageCache para forzar descarga si ya estaban cacheadas
      for (final imgUrl in imgs) {
        try {
          await NetworkImage(imgUrl).evict();
        } catch (_) {
          // ignorar si falla la evicción
        }
      }

      return imgs; // o return imgsWithVersion si usas cache-busting
    } catch (e) {
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
    // Cargar imágenes del CMS para el slideshow
    loadSliderImages().then((imgs) {
      if (!mounted) return;

      setState(() {
        sliderImages = imgs;
        loadingSlider = false;

        slider1Images = [];
        slider2Images = [];

        if (imgs.length > 0) {
          slider1Images = imgs.sublist(0, imgs.length >= 3 ? 3 : imgs.length);
        }

        if (imgs.length > 3) {
          slider2Images = imgs.sublist(3, imgs.length >= 6 ? 6 : imgs.length);
        }
      });
    });

    fetchProducts();
    fetchProducts2();
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
  Future<void> fetchProducts2() async {
    try {
      final url =
          '$baseUrl/api/products?ws_key=$apiKey&display=full&output_format=JSON&filter[id_category_default]=28';

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
      final limitedProducts = rawProducts.take(5).toList();

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
        products2 = finalList;
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
      final limitedProducts = rawProducts.take(5).toList();

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

  //******************************************************************************************************************************************
  //***********************************************************                    ***********************************************************
  //***********************************************************WIDGETS DE LA PAGINA***********************************************************
  //***********************************************************                    ***********************************************************
  //******************************************************************************************************************************************

  // UI PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 0, 0),

      // body ahora es un CustomScrollView con slivers para permitir scroll vertical correcto
      body: CustomScrollView(
        slivers: [
          // 1) Header grande que se va al hacer scroll
          // Header combinado con cross-fade
          SliverPersistentHeader(
            pinned: true,
            delegate: _FadeSwapHeaderDelegate(
              backgroundColor: AppColors.background,
              big: const AppHeader(),    // header grande
              small: const AppHeader2(), // header secundario sticky
              bigHeight: 30,            // altura del grande
              smallHeight: 140,          // altura del sticky
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
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
                                  Navigator.pushNamed(context, '/tienda'),
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
                const SizedBox(height: 5),

                // SLIDESHOW 1
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.54,
                      width: double.infinity,
                      child: loadingSlider
                          ? const Center(child: CircularProgressIndicator())
                          : (slider1Images.isEmpty
                                ? const Center(
                                    child: Text("No hay imágenes disponibles"),
                                  )
                                : FadeImageCarousel(images: slider1Images)),
                    ),
                  ),
                ),
                const SizedBox(height: 1),

                // BANNER
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14.0,
                    vertical: 2.0,
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                    child: Container(
                      height: 120, // <- AJUSTA AQUÍ LA ALTURA DEL CONTENEDOR
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ).withOpacity(0.08),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // GIF a la izquierda
                          SizedBox(
                            width: 100, // ancho del gif
                            height: 100, // igual a altura del contenedor
                            child: ClipRRect(
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(14),
                                bottomLeft: Radius.circular(14),
                              ),
                              child: Image.asset(
                                'assets/banner.gif',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.grey.shade200,
                                      alignment: Alignment.center,
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 32,
                                        color: Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                                      ),
                                    ),
                              ),
                            ),
                          ),
                          // Texto a la derecha
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                                vertical: 12.0,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¿Necesitas ayuda?',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Consulta con nuestro farmacéutico inteligente',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade600,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Chat',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        //TEXTO "PRODUCTOS DESTACADOS"
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'PRODUCTOS DESTACADOS',
                            style: AppText.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // CARRUSEL DE PRODUCTOS
                        SizedBox(
                          height: 260,
                          child: PageView.builder(
                            controller: PageController(viewportFraction: 0.5),
                            padEnds: false,
                            physics: const BouncingScrollPhysics(),
                            itemCount:
                                (products.length >= 5 ? 5 : products.length) +
                                1,
                            itemBuilder: (context, index) {
                              final maxItems = (products.length >= 5
                                  ? 5
                                  : products.length);

                              // BOTÓN "VER TODOS"
                              if (index == maxItems) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 6,
                                  ),
                                  child: GestureDetector(
                                    onTap: () =>
                                        Navigator.pushNamed(context, '/tienda'),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(
                                              0.06,
                                            ),
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: const [
                                            Icon(
                                              Icons.grid_view_rounded,
                                              size: 44,
                                              color: AppColors.purple500,
                                            ),
                                            SizedBox(height: 10),
                                            Text(
                                              'Ver todos',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }

                              final product = products[index];

                              return _ProductCard(
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
                ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 50),

                // SLIDESHOW 2
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.35,
                      width: double.infinity,
                      child: loadingSlider
                          ? const Center(child: CircularProgressIndicator())
                          : (slider2Images.isEmpty
                                ? const Center(
                                    child: Text("No hay imágenes disponibles"),
                                  )
                                : FadeImageCarouselSmall(
                                    images: slider2Images,
                                  )),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // PRODUCTOS RECOMENDADOS 2
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "PRODUCTOS RECOMENDADOS",
                    style: AppText.subtitle.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // CARRUSEL DE PRODUCTOS
                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    controller: PageController(viewportFraction: 0.5),
                    padEnds: false,
                    physics: const BouncingScrollPhysics(),
                    itemCount:
                        (products2.length >= 5 ? 5 : products2.length) + 1,
                    itemBuilder: (context, index) {
                      final maxItems = (products2.length >= 5
                          ? 5
                          : products2.length);

                      // BOTÓN "VER TODOS"
                      if (index == maxItems) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8.0,
                            vertical: 6,
                          ),
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/tienda'),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.06),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.grid_view_rounded,
                                      size: 44,
                                      color: AppColors.purple500,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Ver todos',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }

                      final product = products2[index];

                      return _ProductCard(
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

//******************************************************************************************************************************************
//***********************************************************         **********************************************************************
//***********************************************************VARIABLES**********************************************************************
//***********************************************************         **********************************************************************
//******************************************************************************************************************************************

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

class FadeImageCarousel extends StatefulWidget {
  final List<String> images;

  const FadeImageCarousel({super.key, required this.images});

  @override
  State<FadeImageCarousel> createState() => _FadeImageCarouselState();
}

class _FadeImageCarouselState extends State<FadeImageCarousel>
    with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late Timer _timer;
  bool _ready = false;

  @override
  void initState() {
    super.initState();

    // Preload only first image synchronously to be able to show something rápido
    _preloadFirst().then((_) {
      if (!mounted) return;
      setState(() => _ready = true);
      // Preload remaining images in background, no await (fire-and-forget)
      _preloadRest();
    });

    // Carousel timer: puedes bajar de 10s a 6s si quieres rotación más rápida
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
    } catch (_) {
      // no bloquear si falla
    }
  }

  void _preloadRest() {
    for (int i = 1; i < widget.images.length; i++) {
      final url = widget.images[i];
      // No await: lanzamos concurrencia para no bloquear UI
      Future.microtask(() async {
        try {
          if (url.startsWith('http')) {
            await precacheImage(CachedNetworkImageProvider(url), context);
          } else {
            await precacheImage(AssetImage(url), context);
          }
        } catch (_) {
          // ignorar errores individuales
        }
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
        color: Colors.grey.shade100,
        child: const Center(child: Text('No hay imágenes')),
      );
    }

    final img = widget.images[_currentIndex];
    final isNetwork = img.startsWith('http');

    return AspectRatio(
      aspectRatio: 16 / 8,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/tienda'),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 600), // transición más rápida
          child: !_ready
              ? Container(
                  key: const ValueKey('loading'),
                  color: Colors.grey.shade200,
                  child: const Center(child: CircularProgressIndicator()),
                )
              : isNetwork
              ? CachedNetworkImage(
                  key: ValueKey(img),
                  imageUrl: img,
                  fit: BoxFit.cover,
                  fadeInDuration: const Duration(milliseconds: 350),
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image, size: 36)),
                  ),
                  errorWidget: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image, size: 36)),
                )
              : Image.asset(img, key: ValueKey(img), fit: BoxFit.cover),
        ),
      ),
    );
  }
}

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
    final currentImg = widget.images[_currentIndex];

    return SizedBox(
      height: 400, // ←← ALTURA FIJA
      width: double.infinity, // ←← ANCHO DINÁMICO (≈500 en móviles)
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 800),
          child: CachedNetworkImage(
            key: ValueKey(currentImg),
            imageUrl: currentImg,
            fit: BoxFit.cover,
            placeholder: (ctx, url) => Container(
              color: Colors.grey.shade200,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (ctx, url, error) => Container(
              color: Colors.grey.shade300,
              child: const Center(child: Icon(Icons.broken_image, size: 60)),
            ),
          ),
        ),
      ),
    );
  }
}

// TARJETA DE PRODUCTO
class _ProductCard extends StatelessWidget {
  final int id;
  final String name;
  final String image;
  const _ProductCard({
    required this.id,
    required this.name,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width * 0.46;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ProductPage(id: id)),
        );
      },
      child: Container(
        width: width,
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              offset: const Offset(0, 3),
              blurRadius: 8,
              color: Colors.black.withOpacity(0.08),
            ),
          ],
        ),
        child: Column(
          children: [
            // IMAGEN
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: image != ""
                  ? Image.network(
                      image,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 180,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image_not_supported, size: 60),
                    ),
            ),

            const SizedBox(height: 8),

            // NOMBRE
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

class _FadeSwapHeaderDelegate extends SliverPersistentHeaderDelegate {
  _FadeSwapHeaderDelegate({
    required this.big,
    required this.small,
    required this.bigHeight,
    required this.smallHeight,
    required this.backgroundColor,
  });

  final Widget big;           // AppHeader
  final Widget small;         // AppHeader2
  final double bigHeight;     // 120
  final double smallHeight;   // 100
  final Color backgroundColor;

  @override
  double get minExtent => smallHeight;

  @override
  double get maxExtent => bigHeight + smallHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    // 0 => expandido (solo grande), 1 => colapsado (solo sticky)
    final double t = (shrinkOffset / bigHeight).clamp(0.0, 1.0);
    final double currentHeight = maxExtent - shrinkOffset; // de 220 a 100

    return ColoredBox(
      color: backgroundColor,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Header grande: ocupa todo el alto disponible y se desvanece
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: currentHeight,
            child: Opacity(
              opacity: 1 - t,
              child: big,
            ),
          ),
          // Header pequeño: aparece pegado abajo y se queda sticky
          Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              height: smallHeight,
              child: Opacity(
                opacity: t,
                child: small,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FadeSwapHeaderDelegate old) {
    return big != old.big ||
           small != old.small ||
           bigHeight != old.bigHeight ||
           smallHeight != old.smallHeight ||
           backgroundColor != old.backgroundColor;
  }
}
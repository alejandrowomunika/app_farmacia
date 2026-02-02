import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/auto_text.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';
import '../data/cart.dart';
import '../pages/scanner_page.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  int selectedIndex = 3;
  bool _isProcessing = false;
  bool _isLoading = true;
  bool _isCheckoutCollapsed = false;

  Map<int, int> _stockDisponible = {};
  Set<int> _processingItems = {};

  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";
  final String appSecretKey = "FarmaciaGuerrero_App_25_SecretKey_X7k9m2";

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);

    Cart.onSessionExpired = (items) async {
      for (final item in items) {
        await _sumarStockOfItem(item, item.quantity);
      }
    };

    _loadCart();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final showScrollTop = _scrollController.offset > 300;
    if (showScrollTop != _showScrollToTop) {
      setState(() => _showScrollToTop = showScrollTop);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    await Cart.loadCart();
    await _loadAllStock();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadAllStock() async {
    for (final item in Cart.items) {
      final stock = await _getAvailableStock(item.id);
      if (mounted) {
        setState(() {
          _stockDisponible[item.id] = stock;
        });
      }
    }
  }

  Future<int> _getAvailableStock(int productId) async {
    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables"
      "?ws_key=$apiKey&output_format=JSON&display=full&filter[id_product]=$productId",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["stock_availables"] != null &&
            data["stock_availables"].isNotEmpty) {
          return int.tryParse(
                data["stock_availables"][0]["quantity"].toString(),
              ) ??
              0;
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo stock: $e");
    }
    return 0;
  }

  void onFooterTap(int index) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/tienda');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/chat');
    }
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // STOCK MANAGEMENT
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> _loadStockOfItem(int productId) async {
    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables"
      "?ws_key=$apiKey&output_format=JSON&display=full&filter[id_product]=$productId",
    );

    try {
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data["stock_availables"] != null &&
            data["stock_availables"].isNotEmpty) {
          return data["stock_availables"][0];
        }
      }
    } catch (e) {
      debugPrint("Error cargando stock: $e");
    }
    return null;
  }

  Future<bool> _sumarStockOfItem(CartItem item, int amount) async {
    final stock = await _loadStockOfItem(item.id);
    if (stock == null) return false;

    final currentStock = int.tryParse(stock["quantity"].toString()) ?? 0;
    final newQuantity = currentStock + amount;

    final xmlBody =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <stock_available>
    <id><![CDATA[${stock["id"]}]]></id>
    <id_product><![CDATA[${stock["id_product"]}]]></id_product>
    <id_product_attribute><![CDATA[${stock["id_product_attribute"]}]]></id_product_attribute>
    <id_shop><![CDATA[${stock["id_shop"]}]]></id_shop>
    <id_shop_group><![CDATA[${stock["id_shop_group"]}]]></id_shop_group>
    <quantity><![CDATA[$newQuantity]]></quantity>
    <depends_on_stock><![CDATA[${stock["depends_on_stock"]}]]></depends_on_stock>
    <out_of_stock><![CDATA[${stock["out_of_stock"]}]]></out_of_stock>
    <location><![CDATA[${stock["location"] ?? ""}]]></location>
  </stock_available>
</prestashop>
''';

    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables/${stock["id"]}?ws_key=$apiKey",
    );

    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/xml"},
        body: xmlBody,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _stockDisponible[item.id] = newQuantity;
        return true;
      }
    } catch (e) {
      debugPrint("Error actualizando stock: $e");
    }
    return false;
  }

  Future<bool> _restarStockOfItem(CartItem item, int amount) async {
    final stock = await _loadStockOfItem(item.id);
    if (stock == null) return false;

    final currentStock = int.tryParse(stock["quantity"].toString()) ?? 0;
    if (currentStock < amount) return false;

    final newQuantity = currentStock - amount;

    final xmlBody =
        '''
<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <stock_available>
    <id><![CDATA[${stock["id"]}]]></id>
    <id_product><![CDATA[${stock["id_product"]}]]></id_product>
    <id_product_attribute><![CDATA[${stock["id_product_attribute"]}]]></id_product_attribute>
    <id_shop><![CDATA[${stock["id_shop"]}]]></id_shop>
    <id_shop_group><![CDATA[${stock["id_shop_group"]}]]></id_shop_group>
    <quantity><![CDATA[$newQuantity]]></quantity>
    <depends_on_stock><![CDATA[${stock["depends_on_stock"]}]]></depends_on_stock>
    <out_of_stock><![CDATA[${stock["out_of_stock"]}]]></out_of_stock>
    <location><![CDATA[${stock["location"] ?? ""}]]></location>
  </stock_available>
</prestashop>
''';

    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api/stock_availables/${stock["id"]}?ws_key=$apiKey",
    );

    try {
      final res = await http.put(
        url,
        headers: {"Content-Type": "application/xml"},
        body: xmlBody,
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        _stockDisponible[item.id] = newQuantity;
        return true;
      }
    } catch (e) {
      debugPrint("Error actualizando stock: $e");
    }
    return false;
  }

  // ═══════════════════════════════════════════════════════════
  // ACCIONES DEL CARRITO
  // ═══════════════════════════════════════════════════════════
  Future<void> _incrementItem(CartItem item) async {
    if (_processingItems.contains(item.id)) return;

    setState(() => _processingItems.add(item.id));

    try {
      final stockActual = await _getAvailableStock(item.id);

      if (stockActual <= 0) {
        _showWarningSnackBar("No hay más stock disponible");
        return;
      }

      final success = await _restarStockOfItem(item, 1);

      if (success) {
        setState(() {
          item.quantity++;
          _stockDisponible[item.id] = stockActual - 1;
        });
        await Cart.saveCart();
      } else {
        _showWarningSnackBar("No se pudo añadir más unidades");
      }
    } catch (e) {
      _showErrorSnackBar("Error al actualizar cantidad");
    } finally {
      if (mounted) {
        setState(() => _processingItems.remove(item.id));
      }
    }
  }

  Future<void> _decrementItem(CartItem item) async {
    if (_processingItems.contains(item.id)) return;

    if (item.quantity <= 1) {
      _showRemoveDialog(item);
      return;
    }

    setState(() => _processingItems.add(item.id));

    try {
      final success = await _sumarStockOfItem(item, 1);

      if (success) {
        setState(() {
          item.quantity--;
          _stockDisponible[item.id] = (_stockDisponible[item.id] ?? 0) + 1;
        });
        await Cart.saveCart();
      } else {
        _showErrorSnackBar("Error al actualizar cantidad");
      }
    } catch (e) {
      _showErrorSnackBar("Error al actualizar cantidad");
    } finally {
      if (mounted) {
        setState(() => _processingItems.remove(item.id));
      }
    }
  }

  Future<void> _removeItem(CartItem item) async {
    setState(() => _processingItems.add(item.id));

    try {
      await _sumarStockOfItem(item, item.quantity);
      Cart.removeItem(item.id);
      await Cart.saveCart();

      if (mounted) {
        setState(() {
          _stockDisponible.remove(item.id);
          _processingItems.remove(item.id);
        });
        _showSuccessSnackBar("Producto eliminado");
      }
    } catch (e) {
      _showErrorSnackBar("Error al eliminar producto");
      if (mounted) {
        setState(() => _processingItems.remove(item.id));
      }
    }
  }

  Future<void> _clearCart() async {
    setState(() => _isProcessing = true);

    try {
      for (final item in Cart.items) {
        await _sumarStockOfItem(item, item.quantity);
      }

      Cart.clear();
      await Cart.saveCart();

      if (mounted) {
        setState(() {
          _stockDisponible.clear();
          _isProcessing = false;
        });
        _showSuccessSnackBar("Carrito vaciado");
      }
    } catch (e) {
      _showErrorSnackBar("Error al vaciar el carrito");
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SINCRONIZAR Y FINALIZAR PEDIDO
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> _syncCartWithPrestashop() async {
    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api_cart_sync.php",
    );

    final products = Cart.items
        .map(
          (item) => {
            'id_product': item.id,
            'id_product_attribute': 0,
            'quantity': item.quantity,
          },
        )
        .toList();

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Api-Key': appSecretKey,
        },
        body: jsonEncode({'products': products}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint("Error sincronizando carrito: $e");
    }
    return null;
  }

  Future<void> _finalizarPedido() async {
    setState(() => _isProcessing = true);

    try {
      final result = await _syncCartWithPrestashop();

      if (result != null && result['success'] == true) {
        final idCart = result['id_cart'];
        final secureKey = result['secure_key'];

        final url =
            "https://www.farmaciaguerrerozieza.com/app-carrito?id_cart=$idCart&key=$secureKey";

        launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar(result?['error'] ?? 'No se pudo crear el carrito');
      }
    } catch (e) {
      _showErrorSnackBar("Error al procesar el pedido");
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SNACKBARS
  // ═══════════════════════════════════════════════════════════
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AutoText(
                message,
                style: AppText.body.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ), // ← MODIFICADO: espacio para el footer
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.check_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AutoText(
                message,
                style: AppText.body.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.green600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 100), // ← MODIFICADO
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AutoText(
                message,
                style: AppText.body.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 100), // ← MODIFICADO
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CALCULAR TOTALES
  // ═══════════════════════════════════════════════════════════
  double get _subtotal => Cart.items.fold(
    0,
    (sum, item) => sum + (item.priceTaxExcl * item.quantity),
  );

  double get _totalIva => Cart.items.fold(
    0,
    (sum, item) =>
        sum + ((item.priceTaxIncl - item.priceTaxExcl) * item.quantity),
  );

  double get _total => Cart.items.fold(
    0,
    (sum, item) => sum + (item.priceTaxIncl * item.quantity),
  );

  int get _totalItems => Cart.items.fold(0, (sum, item) => sum + item.quantity);

  // ═══════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true, // ← AÑADIDO

      body: SafeArea(
        bottom: false, // ← AÑADIDO
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : Cart.items.isEmpty
                  ? _buildEmptyState()
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
  // BOTÓN SCROLL TO TOP
  // ═══════════════════════════════════════════════════════════
  Widget? _buildScrollToTopButton() {
    if (!_showScrollToTop || _isLoading || Cart.items.isEmpty) return null;

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 80,
      ), // ← AÑADIDO: espacio sobre el footer
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: FloatingActionButton(
              onPressed: _scrollToTop,
              backgroundColor: AppColors.purple600,
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
  // ESTADO: CARGANDO
  // ═══════════════════════════════════════════════════════════
  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(
          bottom: 100,
        ), // ← AÑADIDO: espacio para el footer
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.purple50,
                shape: BoxShape.circle,
              ),
              child: const CircularProgressIndicator(
                color: AppColors.purple500,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            AutoText(
              "Cargando tu carrito...",
              style: AppText.body.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADO: VACÍO
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          32,
          32,
          32,
          120,
        ), // ← MODIFICADO: espacio inferior
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.purple100, AppColors.purple50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 56,
                color: AppColors.purple400,
              ),
            ),
            const SizedBox(height: 28),
            AutoText(
              "Tu carrito está vacío",
              style: AppText.title.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            AutoText(
              "Explora nuestra tienda y añade\nproductos a tu carrito",
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.green500.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/tienda');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green500,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.store_outlined, size: 22),
                label: AutoText(
                  "Explorar tienda",
                  style: AppText.button.copyWith(fontSize: 16),
                ),
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
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCart,
            color: AppColors.purple500,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // Header del carrito
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildCartHeader(),
                  ),
                ),

                // Lista de items
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = Cart.items[index];
                      final stockDisponible = _stockDisponible[item.id] ?? 0;
                      final isProcessing = _processingItems.contains(item.id);

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < Cart.items.length - 1 ? 12 : 0,
                        ),
                        child: _CartItemCard(
                          item: item,
                          stockDisponible: stockDisponible,
                          isProcessing: isProcessing,
                          onIncrement: () => _incrementItem(item),
                          onDecrement: () => _decrementItem(item),
                          onRemove: () => _showRemoveDialog(item),
                        ),
                      );
                    }, childCount: Cart.items.length),
                  ),
                ),

                // Espacio para el checkout
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          ),
        ),

        // Checkout section
        _buildCheckoutSection(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: HEADER DEL CARRITO
  // ═══════════════════════════════════════════════════════════
  Widget _buildCartHeader() {
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.green100, AppColors.green50],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.green500.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: AppColors.textDark,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoText(
                  "Mi Carrito",
                  style: AppText.title.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.green100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 14,
                            color: AppColors.green700,
                          ),
                          const SizedBox(width: 6),
                          AutoText(
                            "$_totalItems ${_totalItems == 1 ? 'artículo' : 'artículos'}",
                            style: AppText.small.copyWith(
                              color: AppColors.green700,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botón vaciar
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _isProcessing ? null : _showClearCartDialog,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_outline_rounded,
                  color: _isProcessing
                      ? Colors.grey.shade400
                      : Colors.red.shade400,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: SECCIÓN DE CHECKOUT (MODIFICADA PARA FOOTER FLOTANTE)
  // ═══════════════════════════════════════════════════════════
  Widget _buildCheckoutSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ═══════════════════════════════════════════════════════
            // HANDLE PARA CONTRAER/EXPANDIR
            // ═══════════════════════════════════════════════════════
            GestureDetector(
              onTap: () {
                setState(() {
                  _isCheckoutCollapsed = !_isCheckoutCollapsed;
                });
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    // Barra handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Icono y texto
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedRotation(
                          turns: _isCheckoutCollapsed ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 20,
                            color: AppColors.textDark.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        AutoText(
                          _isCheckoutCollapsed ? "Expandir" : "Contraer",
                          style: AppText.small.copyWith(
                            color: AppColors.textDark.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ═══════════════════════════════════════════════════════
            // CONTENIDO EXPANDIDO (Resumen de precios)
            // ═══════════════════════════════════════════════════════
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 300),
              crossFadeState: _isCheckoutCollapsed
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Column(
                children: [
                  // Resumen de precios con tarjeta
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildPriceRow("Subtotal (sin IVA)", _subtotal),
                        const SizedBox(height: 10),
                        _buildPriceRow(
                          "IVA incluido",
                          _totalIva,
                          isSecondary: true,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Divider(
                            color: Colors.grey.shade300,
                            height: 1,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AutoText(
                              "Total",
                              style: AppText.subtitle.copyWith(fontSize: 17),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.green100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: AutoText(
                                "${_total.toStringAsFixed(2)} €",
                                style: AppText.title.copyWith(
                                  fontSize: 20,
                                  color: AppColors.green700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Botón de checkout expandido
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _finalizarPedido,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green500,
                        foregroundColor: AppColors.white,
                        disabledBackgroundColor: AppColors.green300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    color: AppColors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                AutoText(
                                  "Procesando...",
                                  style: AppText.button.copyWith(fontSize: 16),
                                ),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                AutoText(
                                  "Finalizar Pedido",
                                  style: AppText.button.copyWith(fontSize: 17),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 20,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Info de seguridad
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        size: 14,
                        color: AppColors.textDark.withOpacity(0.4),
                      ),
                      const SizedBox(width: 6),
                      AutoText(
                        "Pago 100% seguro",
                        style: AppText.small.copyWith(
                          color: AppColors.textDark.withOpacity(0.4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 14,
                        color: AppColors.textDark.withOpacity(0.4),
                      ),
                      const SizedBox(width: 6),
                      AutoText(
                        "Envío rápido",
                        style: AppText.small.copyWith(
                          color: AppColors.textDark.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // ═══════════════════════════════════════════════════════
              // CONTENIDO CONTRAÍDO (Solo botón con precio)
              // ═══════════════════════════════════════════════════════
              secondChild: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isProcessing ? null : _finalizarPedido,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green500,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.green300,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: _isProcessing
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                            const SizedBox(width: 12),
                            AutoText(
                              "Procesando...",
                              style: AppText.button.copyWith(fontSize: 16),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Precio a la izquierda
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: AutoText(
                                "${_total.toStringAsFixed(2)} €",
                                style: AppText.button.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            // Texto y flecha a la derecha
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.lock_outline,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                AutoText(
                                  "Finalizar",
                                  style: AppText.button.copyWith(fontSize: 16),
                                ),
                                const SizedBox(width: 6),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isSecondary = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AutoText(
          label,
          style: AppText.body.copyWith(
            color: isSecondary
                ? AppColors.textDark.withOpacity(0.5)
                : AppColors.textDark.withOpacity(0.7),
            fontSize: isSecondary ? 13 : 14,
          ),
        ),
        AutoText(
          "${amount.toStringAsFixed(2)} €",
          style: AppText.body.copyWith(
            fontWeight: FontWeight.w600,
            color: isSecondary
                ? AppColors.textDark.withOpacity(0.5)
                : AppColors.textDark,
            fontSize: isSecondary ? 13 : 14,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════
  void _showRemoveDialog(CartItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.remove_shopping_cart_outlined,
                size: 32,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            AutoText(
              "¿Eliminar producto?",
              style: AppText.subtitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            AutoText(
              item.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppText.body.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: AutoText(
                    "Cancelar",
                    style: AppText.body.copyWith(
                      color: AppColors.textDark.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _removeItem(item);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const AutoText("Eliminar"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_forever_outlined,
                size: 32,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 16),
            AutoText(
              "¿Vaciar carrito?",
              style: AppText.subtitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            AutoText(
              "Se eliminarán todos los productos.\nEsta acción no se puede deshacer.",
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: AutoText(
                    "Cancelar",
                    style: AppText.body.copyWith(
                      color: AppColors.textDark.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _clearCart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade500,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const AutoText("Vaciar"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: TARJETA DE ITEM DEL CARRITO (REDISEÑADA)
// ═══════════════════════════════════════════════════════════════════════════════
class _CartItemCard extends StatefulWidget {
  final CartItem item;
  final int stockDisponible;
  final bool isProcessing;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.stockDisponible,
    required this.isProcessing,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
  });

  @override
  State<_CartItemCard> createState() => _CartItemCardState();
}

class _CartItemCardState extends State<_CartItemCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final double itemTotal = widget.item.priceTaxIncl * widget.item.quantity;
    final bool canIncrement = widget.stockDisponible > 0;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
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
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ═══════════════════════════════════════════════
                    // IMAGEN
                    // ═══════════════════════════════════════════════
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 80,
                            height: 80,
                            color: AppColors.background,
                            child: widget.item.image.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: widget.item.image,
                                    fit: BoxFit.cover,
                                    placeholder: (_, __) => const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.purple400,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (_, __, ___) => const Center(
                                      child: Icon(
                                        Icons.image_not_supported_outlined,
                                        color: Colors.grey,
                                        size: 28,
                                      ),
                                    ),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image_not_supported_outlined,
                                      color: Colors.grey,
                                      size: 28,
                                    ),
                                  ),
                          ),
                        ),
                        // Badge de cantidad
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.purple600,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.purple600.withOpacity(0.3),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: AutoText(
                              "x${widget.item.quantity}",
                              style: AppText.small.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(width: 14),

                    // ═══════════════════════════════════════════════
                    // INFO
                    // ═══════════════════════════════════════════════
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Nombre
                          AutoText(
                            widget.item.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.body.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              height: 1.3,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Precio unitario
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.green50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: AutoText(
                                  "${widget.item.priceTaxIncl.toStringAsFixed(2)} €/ud",
                                  style: AppText.small.copyWith(
                                    color: AppColors.green700,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          // Indicador de stock
                          if (widget.stockDisponible > 0 &&
                              widget.stockDisponible <= 5)
                            _buildStockIndicator(
                              icon: Icons.inventory_2_outlined,
                              text: "Quedan ${widget.stockDisponible} en stock",
                              color: Colors.orange,
                            ),

                          if (widget.stockDisponible == 0)
                            _buildStockIndicator(
                              icon: Icons.warning_amber_rounded,
                              text: "Sin stock adicional",
                              color: Colors.red,
                            ),
                        ],
                      ),
                    ),

                    // Botón eliminar
                    GestureDetector(
                      onTap: widget.isProcessing ? null : widget.onRemove,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: widget.isProcessing
                              ? Colors.grey.shade300
                              : Colors.red.shade400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ═══════════════════════════════════════════════
              // BARRA INFERIOR: CONTROLES Y TOTAL
              // ═══════════════════════════════════════════════
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Selector de cantidad
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          _QuantityButton(
                            icon: Icons.remove_rounded,
                            onTap: widget.onDecrement,
                            isDecrease: true,
                            isEnabled: !widget.isProcessing,
                          ),
                          Container(
                            constraints: const BoxConstraints(minWidth: 40),
                            alignment: Alignment.center,
                            child: widget.isProcessing
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      color: AppColors.purple500,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : AutoText(
                                    widget.item.quantity.toString(),
                                    style: AppText.subtitle.copyWith(
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                          _QuantityButton(
                            icon: Icons.add_rounded,
                            onTap: widget.onIncrement,
                            isEnabled: canIncrement && !widget.isProcessing,
                          ),
                        ],
                      ),
                    ),

                    // Total del item
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AutoText(
                          "Total",
                          style: AppText.small.copyWith(
                            color: AppColors.textDark.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 2),
                        AutoText(
                          "${itemTotal.toStringAsFixed(2)} €",
                          style: AppText.subtitle.copyWith(
                            fontSize: 17,
                            color: AppColors.green600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStockIndicator({
    required IconData icon,
    required String text,
    required MaterialColor color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color.shade600),
          const SizedBox(width: 4),
          AutoText(
            text,
            style: AppText.small.copyWith(
              color: color.shade600,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: BOTÓN DE CANTIDAD
// ═══════════════════════════════════════════════════════════════════════════════
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDecrease;
  final bool isEnabled;

  const _QuantityButton({
    required this.icon,
    required this.onTap,
    this.isDecrease = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: isEnabled
                ? (isDecrease ? AppColors.purple600 : AppColors.green600)
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';
import '../data/cart.dart';

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  int selectedIndex = 3;
  bool _isProcessing = false;
  bool _isLoading = true;

  // Mapa para guardar el stock disponible de cada producto
  Map<int, int> _stockDisponible = {};
  
  // Set para controlar qué items están procesando una acción
  Set<int> _processingItems = {};

  // API Keys
  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";
  final String appSecretKey = "FarmaciaGuerrero_App_25_SecretKey_X7k9m2";

  @override
  void initState() {
    super.initState();

    Cart.onSessionExpired = (items) async {
      for (final item in items) {
        await _sumarStockOfItem(item, item.quantity);
      }
    };

    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => _isLoading = true);
    
    await Cart.loadCart();
    
    // Cargar stock de todos los productos del carrito
    await _loadAllStock();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────────────────────
  // CARGAR STOCK DE TODOS LOS PRODUCTOS
  // ─────────────────────────────────────────────────────────
  Future<void> _loadAllStock() async {
    for (final item in Cart.items) {
      final stock = await _getAvailableStock(item.id);
      _stockDisponible[item.id] = stock;
    }
  }

  // ─────────────────────────────────────────────────────────
  // OBTENER STOCK DISPONIBLE DE UN PRODUCTO
  // ─────────────────────────────────────────────────────────
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
          return int.tryParse(data["stock_availables"][0]["quantity"].toString()) ?? 0;
        }
      }
    } catch (e) {
      debugPrint("Error obteniendo stock: $e");
    }
    return 0;
  }

  // ─────────────────────────────────────────────────────────
  // NAVEGACIÓN FOOTER
  // ─────────────────────────────────────────────────────────
  void onFooterTap(int index) {

    // Ocultar cualquier SnackBar activo antes de navegar
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    if (index == selectedIndex) return;

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
        // Ya estás aquí
        break;
    }
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

    final xmlBody = '''
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
        // Actualizar stock local
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
    
    // Verificar si hay stock suficiente
    if (currentStock < amount) {
      return false;
    }
    
    final newQuantity = currentStock - amount;

    final xmlBody = '''
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
        // Actualizar stock local
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
  
  /// Incrementar cantidad de un item
  Future<void> _incrementItem(CartItem item) async {
    // Evitar múltiples clics
    if (_processingItems.contains(item.id)) return;
    
    setState(() => _processingItems.add(item.id));
    
    try {
      // Obtener stock actual desde la API
      final stockActual = await _getAvailableStock(item.id);
      
      if (stockActual <= 0) {
        _showWarningSnackBar("No hay más stock disponible de este producto");
        return;
      }
      
      // Intentar restar del stock
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
      debugPrint("Error incrementando: $e");
      _showErrorSnackBar("Error al actualizar cantidad");
    } finally {
      if (mounted) {
        setState(() => _processingItems.remove(item.id));
      }
    }
  }
  
  /// Decrementar cantidad de un item
  Future<void> _decrementItem(CartItem item) async {
    // Evitar múltiples clics
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
      debugPrint("Error decrementando: $e");
      _showErrorSnackBar("Error al actualizar cantidad");
    } finally {
      if (mounted) {
        setState(() => _processingItems.remove(item.id));
      }
    }
  }
  
  /// Eliminar un item del carrito
  Future<void> _removeItem(CartItem item) async {
    setState(() => _processingItems.add(item.id));
    
    try {
      // Devolver todo el stock
      await _sumarStockOfItem(item, item.quantity);
      
      // Eliminar del carrito
      Cart.removeItem(item.id);
      await Cart.saveCart();
      
      // Actualizar UI
      setState(() {
        _stockDisponible.remove(item.id);
        _processingItems.remove(item.id);
      });
      
      _showSuccessSnackBar("Producto eliminado del carrito");
    } catch (e) {
      debugPrint("Error eliminando: $e");
      _showErrorSnackBar("Error al eliminar producto");
      setState(() => _processingItems.remove(item.id));
    }
  }
  
  /// Vaciar todo el carrito
  Future<void> _clearCart() async {
    setState(() => _isProcessing = true);
    
    try {
      // Devolver stock de todos los items
      for (final item in Cart.items) {
        await _sumarStockOfItem(item, item.quantity);
      }
      
      // Limpiar carrito
      Cart.clear();
      await Cart.saveCart();
      
      // Actualizar UI
      setState(() {
        _stockDisponible.clear();
        _isProcessing = false;
      });
      
      _showSuccessSnackBar("Carrito vaciado");
    } catch (e) {
      debugPrint("Error vaciando carrito: $e");
      _showErrorSnackBar("Error al vaciar el carrito");
      setState(() => _isProcessing = false);
    }
  }

  // ═══════════════════════════════════════════════════════════
  // SINCRONIZAR CARRITO CON PRESTASHOP
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>?> _syncCartWithPrestashop() async {
    final url = Uri.parse(
      "https://www.farmaciaguerrerozieza.com/api_cart_sync.php",
    );

    final products = Cart.items
        .map((item) => {
              'id_product': item.id,
              'id_product_attribute': 0,
              'quantity': item.quantity,
            })
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

      debugPrint("Response status: ${response.statusCode}");
      debugPrint("Response body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
    } catch (e) {
      debugPrint("Error sincronizando carrito: $e");
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════
  // FINALIZAR PEDIDO
  // ═══════════════════════════════════════════════════════════
  Future<void> _finalizarPedido() async {
    setState(() => _isProcessing = true);

    try {
      final result = await _syncCartWithPrestashop();

      if (result != null && result['success'] == true) {
        final idCart = result['id_cart'];
        final secureKey = result['secure_key'];

        final url =
            "https://www.farmaciaguerrerozieza.com/carrito-app.php?id_cart=$idCart&key=$secureKey";

        debugPrint("Abriendo URL: $url");

        launchUrl(
          Uri.parse(url),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showErrorSnackBar(result?['error'] ?? 'No se pudo crear el carrito');
      }
    } catch (e) {
      debugPrint("Error: $e");
      _showErrorSnackBar("Error al procesar el pedido");
    } finally {
      setState(() => _isProcessing = false);
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
            const Icon(Icons.error_outline, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppText.body.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_rounded,
              color: AppColors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              "Carrito Vaciado",
              style: AppText.body.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const Spacer(), // ← Empuja la X hacia la derecha
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.green600.withOpacity(0.85),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        margin: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        elevation: 8,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: AppText.body.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // CALCULAR TOTALES
  // ═══════════════════════════════════════════════════════════
  double get _subtotal {
    return Cart.items.fold(
      0,
      (sum, item) => sum + (item.priceTaxExcl * item.quantity),
    );
  }

  double get _totalIva {
    return Cart.items.fold(
      0,
      (sum, item) =>
          sum + ((item.priceTaxIncl - item.priceTaxExcl) * item.quantity),
    );
  }

  double get _total {
    return Cart.items.fold(
      0,
      (sum, item) => sum + (item.priceTaxIncl * item.quantity),
    );
  }

  int get _totalItems {
    return Cart.items.fold(0, (sum, item) => sum + item.quantity);
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
              child: _isLoading
                  ? _buildLoadingState()
                  : Cart.items.isEmpty
                      ? _buildEmptyState()
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.green50,
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: AppColors.green500,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Cargando carrito...",
            style: AppText.body.copyWith(
              color: AppColors.textDark.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ESTADO: VACÍO
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.purple50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.shopping_cart_outlined,
                size: 64,
                color: AppColors.purple400,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              "Tu carrito está vacío",
              style: AppText.title.copyWith(fontSize: 22),
            ),
            const SizedBox(height: 12),
            Text(
              "Añade productos desde nuestra tienda para empezar tu pedido",
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
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
              label: Text(
                "Ir a la tienda",
                style: AppText.button.copyWith(fontSize: 16),
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
        // Lista de productos
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadCart,
            color: AppColors.green500,
            child: CustomScrollView(
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final item = Cart.items[index];
                        final stockDisponible = _stockDisponible[item.id] ?? 0;
                        final isProcessing = _processingItems.contains(item.id);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CartItemCard(
                            item: item,
                            stockDisponible: stockDisponible,
                            isProcessing: isProcessing,
                            onIncrement: () => _incrementItem(item),
                            onDecrement: () => _decrementItem(item),
                            onRemove: () => _showRemoveDialog(item),
                          ),
                        );
                      },
                      childCount: Cart.items.length,
                    ),
                  ),
                ),

                // Espacio para el resumen
                const SliverToBoxAdapter(
                  child: SizedBox(height: 16),
                ),
              ],
            ),
          ),
        ),

        // Resumen y botón de checkout
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
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.purple500, AppColors.purple400],
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
            child: const Icon(
              Icons.shopping_cart_outlined,
              color: AppColors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mi Carrito",
                  style: AppText.title.copyWith(fontSize: 20),
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
                        color: AppColors.green100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        "$_totalItems ${_totalItems == 1 ? 'producto' : 'productos'}",
                        style: AppText.small.copyWith(
                          color: AppColors.green700,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Botón vaciar carrito
          Container(
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: _isProcessing ? null : _showClearCartDialog,
              icon: Icon(
                Icons.delete_outline_rounded,
                color: _isProcessing ? Colors.grey : Colors.red.shade400,
              ),
              tooltip: 'Vaciar carrito',
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: SECCIÓN DE CHECKOUT
  // ═══════════════════════════════════════════════════════════
  Widget _buildCheckoutSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Indicador visual
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Resumen de precios
            _buildPriceRow("Subtotal", _subtotal, isSubtotal: true),
            const SizedBox(height: 8),
            _buildPriceRow("IVA incluido", _totalIva, isIva: true),
            
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: Colors.grey.shade200),
            ),
            
            _buildPriceRow("Total", _total, isTotal: true),

            const SizedBox(height: 20),

            // Botón de checkout
            SizedBox(
              width: double.infinity,
              height: 56,
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
                          Text(
                            "Procesando...",
                            style: AppText.button.copyWith(fontSize: 16),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock_outline, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "Finalizar Pedido",
                            style: AppText.button.copyWith(fontSize: 17),
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
                Text(
                  "Pago seguro garantizado",
                  style: AppText.small.copyWith(
                    color: AppColors.textDark.withOpacity(0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    double amount, {
    bool isSubtotal = false,
    bool isIva = false,
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppText.subtitle.copyWith(fontSize: 18)
              : AppText.body.copyWith(
                  color: isIva
                      ? AppColors.textDark.withOpacity(0.5)
                      : AppColors.textDark.withOpacity(0.7),
                  fontSize: isIva ? 13 : 14,
                ),
        ),
        Text(
          "${amount.toStringAsFixed(2)} €",
          style: isTotal
              ? AppText.title.copyWith(
                  fontSize: 22,
                  color: AppColors.green600,
                )
              : AppText.body.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isIva
                      ? AppColors.textDark.withOpacity(0.5)
                      : AppColors.textDark,
                  fontSize: isIva ? 13 : 15,
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "¿Eliminar producto?",
          style: AppText.subtitle,
        ),
        content: Text(
          "¿Estás seguro de que quieres eliminar \"${item.name}\" del carrito?",
          style: AppText.body.copyWith(
            color: AppColors.textDark.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: AppText.body.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _removeItem(item);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "¿Vaciar carrito?",
          style: AppText.subtitle,
        ),
        content: Text(
          "Se eliminarán todos los productos del carrito. Esta acción no se puede deshacer.",
          style: AppText.body.copyWith(
            color: AppColors.textDark.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancelar",
              style: AppText.body.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text("Vaciar"),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: TARJETA DE ITEM DEL CARRITO
// ═══════════════════════════════════════════════════════════════════════════════
class _CartItemCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final double itemTotal = item.priceTaxIncl * item.quantity;
    final bool canIncrement = stockDisponible > 0;

    return Container(
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ═══════════════════════════════════════════════
            // IMAGEN
            // ═══════════════════════════════════════════════
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 85,
                height: 85,
                color: AppColors.background,
                child: item.image.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.image,
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
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.image_not_supported_outlined,
                          color: Colors.grey,
                        ),
                      ),
              ),
            ),

            const SizedBox(width: 14),

            // ═══════════════════════════════════════════════
            // INFO
            // ═══════════════════════════════════════════════
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre y botón eliminar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.body.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.2,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: isProcessing ? null : onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: isProcessing 
                                ? Colors.grey.shade300 
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // Precio unitario
                  Text(
                    "${item.priceTaxIncl.toStringAsFixed(2)} €/ud",
                    style: AppText.small.copyWith(
                      color: AppColors.textDark.withOpacity(0.5),
                    ),
                  ),

                  // Indicador de stock
                  if (stockDisponible > 0 && stockDisponible <= 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 12,
                            color: Colors.orange.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Quedan $stockDisponible en stock",
                            style: AppText.small.copyWith(
                              color: Colors.orange.shade600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  if (stockDisponible == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 12,
                            color: Colors.red.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            "Sin stock adicional",
                            style: AppText.small.copyWith(
                              color: Colors.red.shade600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 10),

                  // Controles de cantidad y total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Selector de cantidad
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            _QuantityButton(
                              icon: Icons.remove_rounded,
                              onTap: onDecrement,
                              isDecrease: true,
                              isEnabled: !isProcessing,
                            ),
                            Container(
                              constraints: const BoxConstraints(minWidth: 36),
                              alignment: Alignment.center,
                              child: isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        color: AppColors.green500,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      item.quantity.toString(),
                                      style: AppText.body.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                            _QuantityButton(
                              icon: Icons.add_rounded,
                              onTap: onIncrement,
                              isEnabled: canIncrement && !isProcessing,
                            ),
                          ],
                        ),
                      ),

                      // Total del item
                      Text(
                        "${itemTotal.toStringAsFixed(2)} €",
                        style: AppText.subtitle.copyWith(
                          fontSize: 16,
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
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: isEnabled
                ? (isDecrease ? Colors.orange.shade600 : AppColors.green600)
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}
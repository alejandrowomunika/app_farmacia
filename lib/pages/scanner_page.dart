import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import '../widgets/auto_text.dart';
import '../theme/app_theme.dart';
import '../data/cart.dart';
import 'producto.dart';

class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  // ═══════════════════════════════════════════════════════════
  // CONTROLADORES Y ESTADO
  // ═══════════════════════════════════════════════════════════
  MobileScannerController? _scannerController;

  bool _isScanning = true;
  bool _isSearching = false;
  bool _isFlashOn = false;
  String? _lastScannedCode;
  Map<String, dynamic>? _foundProduct;
  String? _errorMessage;

  final String baseUrl = "https://www.farmaciaguerrerozieza.com";
  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";

  @override
  void initState() {
    super.initState();
    _initScanner();
  }

  void _initScanner() {
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _scannerController?.dispose();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════
  // MANEJAR CÓDIGO ESCANEADO
  // ═══════════════════════════════════════════════════════════
  void _onBarcodeDetected(BarcodeCapture capture) async {
    // Evitar escaneos múltiples
    if (!_isScanning || _isSearching) return;

    final List<Barcode> barcodes = capture.barcodes;

    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;

    if (code == null || code.isEmpty) return;

    // Evitar escanear el mismo código repetidamente
    if (code == _lastScannedCode) return;

    setState(() {
      _isScanning = false;
      _isSearching = true;
      _lastScannedCode = code;
      _errorMessage = null;
      _foundProduct = null;
    });

    // Buscar producto por EAN
    await _searchProductByEAN(code);
  }

  // ═══════════════════════════════════════════════════════════
  // BUSCAR PRODUCTO POR EAN EN LA API
  // ═══════════════════════════════════════════════════════════
  Future<void> _searchProductByEAN(String ean) async {
    try {
      // Buscar por EAN13 (código de barras estándar)
      final url = Uri.parse(
        "$baseUrl/api/products?ws_key=$apiKey&output_format=JSON&display=full&filter[ean13]=$ean",
      );

      final response = await http.get(url);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List products = decoded["products"] ?? [];

        if (products.isNotEmpty) {
          // Producto encontrado
          final product = products.first;

          setState(() {
            _foundProduct = _parseProduct(product);
            _isSearching = false;
          });

          // Mostrar modal con el producto
          _showProductModal();
        } else {
          // Producto no encontrado
          setState(() {
            _errorMessage = "Producto no encontrado";
            _isSearching = false;
          });
          _showNotFoundModal(ean);
        }
      } else {
        setState(() {
          _errorMessage = "Error de conexión";
          _isSearching = false;
        });
        _showErrorModal();
      }
    } catch (e) {
      debugPrint("Error buscando producto: $e");
      setState(() {
        _errorMessage = "Error al buscar";
        _isSearching = false;
      });
      _showErrorModal();
    }
  }

  // ═══════════════════════════════════════════════════════════
  // PARSEAR PRODUCTO DE LA API
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic> _parseProduct(Map<String, dynamic> product) {
    final int id = int.tryParse(product["id"].toString()) ?? 0;

    // Nombre
    String name = "Sin nombre";
    final rawName = product["name"];
    if (rawName is String) {
      name = rawName;
    } else if (rawName is Map && rawName["language"] is List) {
      name = rawName["language"][0]["value"] ?? "Sin nombre";
    }

    // Precio
    double price = 0.0;
    if (product["price"] is String) {
      price = double.tryParse(product["price"]) ?? 0.0;
    } else if (product["price"] is num) {
      price = product["price"].toDouble();
    }

    // IVA
    final taxGroupId = product["id_tax_rules_group"]?.toString() ?? "0";
    double taxRate = 0;
    switch (taxGroupId) {
      case "1":
        taxRate = 4;
        break;
      case "2":
        taxRate = 10;
        break;
      case "3":
        taxRate = 21;
        break;
    }
    final double priceWithTax = price * (1 + taxRate / 100);

    // Imagen
    final String imageId = product["id_default_image"]?.toString() ?? "";
    String imageUrl = "";
    if (imageId.isNotEmpty) {
      final digits = imageId.split('');
      final path = digits.join('/');
      imageUrl = "$baseUrl/img/p/$path/$imageId-home_default.jpg";
    }

    // EAN
    final String ean = product["ean13"]?.toString() ?? "";

    return {
      "id": id,
      "name": name,
      "price": price,
      "priceWithTax": priceWithTax,
      "taxRate": taxRate,
      "image": imageUrl,
      "ean": ean,
    };
  }

  // ═══════════════════════════════════════════════════════════
  // MODAL: PRODUCTO ENCONTRADO
  // ═══════════════════════════════════════════════════════════
  void _showProductModal() {
    if (_foundProduct == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => _ProductFoundModal(
        product: _foundProduct!,
        onAddToCart: () => _addToCart(_foundProduct!),
        onViewProduct: () => _viewProduct(_foundProduct!["id"]),
        onScanAgain: () {
          Navigator.pop(context);
          _resetScanner();
        },
      ),
    ).whenComplete(() {
      // Al cerrar el modal, permitir escanear de nuevo
      _resetScanner();
    });
  }

  // ═══════════════════════════════════════════════════════════
  // MODAL: PRODUCTO NO ENCONTRADO
  // ═══════════════════════════════════════════════════════════
  void _showNotFoundModal(String ean) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: Colors.orange.shade600,
                size: 48,
              ),
            ),

            const SizedBox(height: 20),

            AutoText(
              "Producto no encontrado",
              style: AppText.title.copyWith(fontSize: 20),
            ),

            const SizedBox(height: 8),

            AutoText(
              "No encontramos ningún producto con el código:",
              style: AppText.body.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: AutoText(
                ean,
                style: AppText.body.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  letterSpacing: 2,
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _resetScanner();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green600,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.qr_code_scanner_rounded),
                label: const AutoText("Escanear otro producto"),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: AutoText(
                "Cerrar",
                style: AppText.body.copyWith(color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _resetScanner());
  }

  // ═══════════════════════════════════════════════════════════
  // MODAL: ERROR
  // ═══════════════════════════════════════════════════════════
  void _showErrorModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: Colors.red.shade600,
                size: 48,
              ),
            ),

            const SizedBox(height: 20),

            AutoText(
              "Producto no encontrado",
              style: AppText.title.copyWith(fontSize: 20),
            ),

            const SizedBox(height: 8),

            AutoText(
              "No pudimos encontrar el producto con ese código EAN.",
              style: AppText.body.copyWith(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _resetScanner();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green600,
                  foregroundColor: AppColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: const AutoText("Intentar de nuevo"),
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _resetScanner());
  }

  // ═══════════════════════════════════════════════════════════
  // RESETEAR ESCÁNER
  // ═══════════════════════════════════════════════════════════
  void _resetScanner() {
    setState(() {
      _isScanning = true;
      _isSearching = false;
      _lastScannedCode = null;
      _foundProduct = null;
      _errorMessage = null;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // TOGGLE FLASH
  // ═══════════════════════════════════════════════════════════
  void _toggleFlash() {
    _scannerController?.toggleTorch();
    setState(() {
      _isFlashOn = !_isFlashOn;
    });
  }

  // ═══════════════════════════════════════════════════════════
  // AÑADIR AL CARRITO
  // ═══════════════════════════════════════════════════════════
  void _addToCart(Map<String, dynamic> product) {
    Cart.addItem(
      CartItem(
        id: product["id"],
        name: product["name"],
        priceTaxExcl: product["price"],
        priceTaxIncl: product["priceWithTax"],
        taxRate: product["taxRate"],
        quantity: 1,
        image: product["image"],
      ),
    );

    Navigator.pop(context); // Cerrar modal

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.white),
            const SizedBox(width: 12),
            Expanded(
              child: AutoText(
                "Añadido al carrito",
                style: AppText.body.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                Navigator.pushNamed(context, '/carrito');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AutoText(
                  "Ver carrito",
                  style: AppText.small.copyWith(
                    color: AppColors.green600,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.green600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );

    _resetScanner();
  }

  // ═══════════════════════════════════════════════════════════
  // VER PRODUCTO
  // ═══════════════════════════════════════════════════════════
  void _viewProduct(int productId) {
    Navigator.pop(context); // Cerrar modal
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductPage(id: productId)),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // BUILD PRINCIPAL
  // ═══════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ═══════════════════════════════════════════
          // CÁMARA
          // ═══════════════════════════════════════════
          if (_scannerController != null)
            MobileScanner(
              controller: _scannerController!,
              onDetect: _onBarcodeDetected,
            ),

          // ═══════════════════════════════════════════
          // OVERLAY OSCURO CON VENTANA
          // ═══════════════════════════════════════════
          _buildScannerOverlay(),

          // ═══════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════
          _buildHeader(),

          // ═══════════════════════════════════════════
          // INDICADOR DE BÚSQUEDA
          // ═══════════════════════════════════════════
          if (_isSearching) _buildSearchingIndicator(),

          // ═══════════════════════════════════════════
          // CONTROLES INFERIORES
          // ═══════════════════════════════════════════
          _buildBottomControls(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: HEADER
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Botón volver
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.white,
                  size: 24,
                ),
              ),
            ),

            // Título
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.qr_code_scanner_rounded,
                    color: AppColors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  AutoText(
                    "Escanear producto",
                    style: AppText.body.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Botón flash
            GestureDetector(
              onTap: _toggleFlash,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isFlashOn
                      ? AppColors.yellow500
                      : Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  color: _isFlashOn ? Colors.black : AppColors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: OVERLAY CON VENTANA DE ESCANEO
  // ═══════════════════════════════════════════════════════════
  Widget _buildScannerOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanAreaSize = constraints.maxWidth * 0.75;
        final scanAreaTop = (constraints.maxHeight - scanAreaSize) / 2;
        final scanAreaLeft = (constraints.maxWidth - scanAreaSize) / 2;

        return Stack(
          children: [
            // Overlay oscuro
            ColorFiltered(
              colorFilter: ColorFilter.mode(
                Colors.black.withOpacity(0.6),
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(color: Colors.transparent),
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: scanAreaSize,
                        height: scanAreaSize,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Marco de escaneo
            Positioned(
              top: scanAreaTop,
              left: scanAreaLeft,
              child: Container(
                width: scanAreaSize,
                height: scanAreaSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isSearching
                        ? AppColors.yellow500
                        : AppColors.green500,
                    width: 3,
                  ),
                ),
                child: Stack(
                  children: [
                    // Esquinas decorativas
                    ..._buildCorners(scanAreaSize),
                  ],
                ),
              ),
            ),

            // Texto instrucción
            Positioned(
              top: scanAreaTop + scanAreaSize + 24,
              left: 0,
              right: 0,
              child: AutoText(
                _isSearching
                    ? "Buscando producto..."
                    : "Centra el código de barras en el recuadro",
                style: AppText.body.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCorners(double size) {
    const cornerSize = 30.0;
    const cornerWidth = 4.0;
    final color = _isSearching ? AppColors.yellow500 : AppColors.green500;

    return [
      // Top Left
      Positioned(
        top: 0,
        left: 0,
        child: _buildCorner(cornerSize, cornerWidth, color, isTopLeft: true),
      ),
      // Top Right
      Positioned(
        top: 0,
        right: 0,
        child: _buildCorner(cornerSize, cornerWidth, color, isTopRight: true),
      ),
      // Bottom Left
      Positioned(
        bottom: 0,
        left: 0,
        child: _buildCorner(cornerSize, cornerWidth, color, isBottomLeft: true),
      ),
      // Bottom Right
      Positioned(
        bottom: 0,
        right: 0,
        child: _buildCorner(
          cornerSize,
          cornerWidth,
          color,
          isBottomRight: true,
        ),
      ),
    ];
  }

  Widget _buildCorner(
    double size,
    double width,
    Color color, {
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          strokeWidth: width,
          isTopLeft: isTopLeft,
          isTopRight: isTopRight,
          isBottomLeft: isBottomLeft,
          isBottomRight: isBottomRight,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: INDICADOR DE BÚSQUEDA
  // ═══════════════════════════════════════════════════════════
  Widget _buildSearchingIndicator() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              color: AppColors.green500,
              strokeWidth: 3,
            ),
            const SizedBox(height: 16),
            AutoText(
              "Buscando producto...",
              style: AppText.body.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: CONTROLES INFERIORES
  // ═══════════════════════════════════════════════════════════
  Widget _buildBottomControls() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Botón cancelar
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: AutoText(
                    "Cancelar",
                    style: AppText.button.copyWith(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAINTER: ESQUINAS DEL MARCO
// ═══════════════════════════════════════════════════════════════════════════════
class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    if (isTopLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTopRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (isBottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (isBottomRight) {
      path.moveTo(0, size.height);
      path.lineTo(size.width, size.height);
      path.lineTo(size.width, 0);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════════════════════
// WIDGET: MODAL PRODUCTO ENCONTRADO
// ═══════════════════════════════════════════════════════════════════════════════
class _ProductFoundModal extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onAddToCart;
  final VoidCallback onViewProduct;
  final VoidCallback onScanAgain;

  const _ProductFoundModal({
    required this.product,
    required this.onAddToCart,
    required this.onViewProduct,
    required this.onScanAgain,
  });

  @override
  Widget build(BuildContext context) {
    final String name = product["name"] ?? "Sin nombre";
    final double priceWithTax = product["priceWithTax"] ?? 0.0;
    final String imageUrl = product["image"] ?? "";
    final String ean = product["ean"] ?? "";

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de arrastre
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header éxito
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.green100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.green600,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoText(
                        "¡Producto encontrado!",
                        style: AppText.subtitle.copyWith(
                          color: AppColors.green700,
                        ),
                      ),
                      if (ean.isNotEmpty)
                        AutoText(
                          "EAN: $ean",
                          style: AppText.small.copyWith(
                            color: AppColors.green600,
                            fontFamily: 'monospace',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Producto
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 100,
                    height: 100,
                    color: AppColors.background,
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.image_not_supported,
                              color: Colors.grey,
                              size: 40,
                            ),
                          )
                        : const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                            size: 40,
                          ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoText(
                        name,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      AutoText(
                        "${priceWithTax.toStringAsFixed(2)} €",
                        style: AppText.title.copyWith(
                          color: AppColors.green600,
                          fontSize: 22,
                        ),
                      ),
                      AutoText(
                        "IVA incluido",
                        style: AppText.small.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // Añadir al carrito
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: onAddToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green600,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: AutoText(
                      "Añadir al carrito",
                      style: AppText.button.copyWith(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Fila con Ver producto y Escanear otro
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewProduct,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.purple600,
                          side: const BorderSide(color: AppColors.purple300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.visibility_rounded, size: 20),
                        label: const AutoText("Ver producto"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onScanAgain,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade600,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(
                          Icons.qr_code_scanner_rounded,
                          size: 20,
                        ),
                        label: const AutoText("Escanear otro"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

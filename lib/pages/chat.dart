import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/auto_text.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';
import '../pages/scanner_page.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  int selectedIndex = 2;
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _hasError = true;
              });
            }
            debugPrint('Error cargando chatbot: ${error.description}');
          },
        ),
      )
      // ═══════════════════════════════════════════
      // RECOGEMOS LA URL PARA MOSTRAR EL CHATBOT
      // ═══════════════════════════════════════════
      ..loadRequest(
        Uri.parse('https://chatbot.womunika-ia.com/chatbot/XdqWeUUUu5KG2PnR'),
      );
  }

  void _reloadWebView() {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    _controller.reload();
  }

  void onFooterTap(int index) {
    setState(() => selectedIndex = index);

    if (index == 0) Navigator.pushReplacementNamed(context, '/');
    if (index == 1) Navigator.pushReplacementNamed(context, '/tienda');
    if (index == 2) Navigator.pushReplacementNamed(context, '/chat');
    if (index == 3) Navigator.pushReplacementNamed(context, '/carrito');
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),

            // ═══════════════════════════════════════════
            // HEADER DEL CHAT
            // ═══════════════════════════════════════════
            _buildChatHeader(),

            // ═══════════════════════════════════════════
            // WEBVIEW DEL CHATBOT
            // ═══════════════════════════════════════════
            Expanded(
              child: _hasError ? _buildErrorState() : _buildChatbotView(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: selectedIndex,
        onTap: onFooterTap,
        onScanTap: _openScanner,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: HEADER DEL CHAT
  // ═══════════════════════════════════════════════════════════
  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar del bot
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.green600, AppColors.green400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.green500.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy_outlined,
              color: AppColors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          // Información del bot
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AutoText(
                  "Asistente Farmacéutico",
                  style: AppText.subtitle.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.green500,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    AutoText(
                      "En línea",
                      style: AppText.small.copyWith(
                        color: AppColors.green600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Botón recargar
          IconButton(
            onPressed: _reloadWebView,
            icon: const Icon(Icons.refresh_rounded, color: AppColors.green600),
            tooltip: 'Recargar chat',
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: VISTA DEL CHATBOT
  // ═══════════════════════════════════════════════════════════
  Widget _buildChatbotView() {
    return Stack(
      children: [
        // WebView del chatbot
        WebViewWidget(controller: _controller),

        // Indicador de carga
        if (_isLoading)
          Container(
            color: AppColors.background,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animación de carga
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.green500,
                        strokeWidth: 3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  AutoText(
                    "Conectando con el asistente...",
                    style: AppText.body.copyWith(
                      color: AppColors.textDark.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AutoText(
                    "Esto puede tardar unos segundos",
                    style: AppText.small.copyWith(
                      color: AppColors.textDark.withOpacity(0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: ESTADO DE ERROR
  // ═══════════════════════════════════════════════════════════
  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 48,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            AutoText(
              "No se pudo conectar",
              style: AppText.subtitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            AutoText(
              "Verifica tu conexión a internet e inténtalo de nuevo",
              textAlign: TextAlign.center,
              style: AppText.body.copyWith(
                color: AppColors.textDark.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _reloadWebView,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.green500,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: AutoText(
                "Reintentar",
                style: AppText.button.copyWith(fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),

            // Alternativa de contacto
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.green50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.green200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.phone_outlined,
                    color: AppColors.green600,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AutoText(
                          "¿Necesitas ayuda?",
                          style: AppText.small.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.green700,
                          ),
                        ),
                        AutoText(
                          "Llámanos al teléfono de la farmacia",
                          style: AppText.small.copyWith(
                            color: AppColors.textDark.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
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

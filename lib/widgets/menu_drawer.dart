import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../pages/scanner_page.dart'; // ← AÑADIR ESTE IMPORT

class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  bool _isPoliciesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenWidth * 0.80,
          height: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildMenuHeader(context),
                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade200, height: 1),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        // ═══════════════════════════════════════
                        // NAVEGACIÓN PRINCIPAL
                        // ═══════════════════════════════════════
                        _MenuLink(
                          icon: Icons.home_rounded,
                          label: "Inicio",
                          onTap: () => _navigateTo(context, '/'),
                        ),
                        _MenuLink(
                          icon: Icons.store_rounded,
                          label: "Tienda",
                          onTap: () => _navigateTo(context, '/tienda'),
                        ),

                        _MenuLink(
                          icon: Icons.chat_rounded,
                          label: "Chat",
                          onTap: () => _navigateTo(context, '/chat'),
                        ),
                        _MenuLink(
                          icon: Icons.shopping_cart_rounded,
                          label: "Carrito",
                          onTap: () => _navigateTo(context, '/carrito'),
                        ),

                        // ═══════════════════════════════════════
                        // ESCÁNER DE CÓDIGO DE BARRAS
                        // ═══════════════════════════════════════
                        _MenuLink(
                          icon: Icons.qr_code_scanner_rounded,
                          label: "Escanear producto",
                          onTap: () => _openScanner(context),
                        ),

                        _buildDivider(),

                        _MenuLink(
                          icon: Icons.phone_rounded,
                          label: "Contacto",
                          onTap: () => _navigateTo(context, '/contacto'),
                        ),

                        _buildPoliciesSection(),
                      ],
                    ),
                  ),
                ),

                _buildMenuFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Divider(color: Colors.grey.shade200),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // ABRIR ESCÁNER ← NUEVO MÉTODO
  // ═══════════════════════════════════════════════════════════
  void _openScanner(BuildContext context) {
    Navigator.pop(context); // Cerrar menú
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ScannerPage()),
    );
  }

  Widget _buildPoliciesSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _isPoliciesExpanded = !_isPoliciesExpanded;
                });
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: _isPoliciesExpanded
                      ? AppColors.purple50
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),

                      child: Icon(
                        Icons.policy_rounded,
                        color: AppColors.purple800,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        "Políticas",
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _isPoliciesExpanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        color: _isPoliciesExpanded
                            ? AppColors.purple800
                            : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _buildPoliciesSubItems(),
          crossFadeState: _isPoliciesExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildPoliciesSubItems() {
    return Container(
      margin: const EdgeInsets.only(left: 24, top: 4),
      padding: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.purple800, width: 2)),
      ),
      child: Column(
        children: [
          _PolicySubItem(
            icon: Icons.gavel_rounded,
            label: "Aviso Legal",
            onTap: () => _navigateTo(context, '/aviso-legal'),
          ),
          _PolicySubItem(
            icon: Icons.privacy_tip_rounded,
            label: "Política de Privacidad",
            onTap: () => _navigateTo(context, '/politica-privacidad'),
          ),
          _PolicySubItem(
            icon: Icons.cookie_rounded,
            label: "Política de Cookies",
            onTap: () => _navigateTo(context, '/politica-cookies'),
          ),
          _PolicySubItem(
            icon: Icons.local_shipping_rounded,
            label: "Política de Envíos",
            onTap: () => _navigateTo(context, '/politica-envios'),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),

                child: const Icon(
                  Icons.local_pharmacy_rounded,
                  color: AppColors.purple600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Menú", style: AppText.title.copyWith(fontSize: 18)),
                  Text(
                    "Farmacia Guerrero",
                    style: AppText.small.copyWith(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: Colors.grey.shade600,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 12),
          Text(
            "Farmacia Guerrero Zieza",
            style: AppText.small.copyWith(
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "© 2026 Todos los derechos reservados a Womunika",
            style: AppText.small.copyWith(
              color: Colors.grey.shade400,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, String route) {
    Navigator.pop(context);
    Navigator.pushNamed(context, route);
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: ENLACE DEL MENÚ (ACTUALIZADO CON highlighted)
// ═══════════════════════════════════════════════════════════
class _MenuLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;
  final String? badge;
  final bool highlighted; // ← NUEVO

  const _MenuLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
    this.badge,
    this.highlighted = false, // ← NUEVO
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Icono
                Container(
                  padding: const EdgeInsets.all(4),

                  child: Icon(
                    icon,
                    color: highlighted
                        ? AppColors.purple800
                        : (enabled
                              ? AppColors.purple800
                              : Colors.grey.shade400),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),

                // Label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.body.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: highlighted
                              ? AppColors.purple800
                              : (enabled
                                    ? AppColors.textDark
                                    : Colors.grey.shade400),
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: AppText.small.copyWith(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Flecha o candado
                Icon(
                  enabled
                      ? Icons.chevron_right_rounded
                      : Icons.lock_outline_rounded,
                  color: highlighted
                      ? Colors.grey.shade400
                      : Colors.grey.shade400,
                  size: enabled ? 22 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: SUBITEM DE POLÍTICAS
// ═══════════════════════════════════════════════════════════
class _PolicySubItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PolicySubItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: AppColors.purple800, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppText.small.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: AppColors.textDark.withOpacity(0.8),
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

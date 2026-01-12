import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Asegúrate de que esta ruta sea correcta

// ═══════════════════════════════════════════════════════════
// WIDGET PRINCIPAL: MenuDrawer (ahora StatefulWidget)
// ═══════════════════════════════════════════════════════════
class MenuDrawer extends StatefulWidget {
  const MenuDrawer({super.key});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  // Opcional: Si quieres controlar el estado de la expansión manualmente
  // bool _isPoliciesExpanded = false;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: screenWidth * 0.80, // 80% del ancho
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
                // ═══════════════════════════════════════════
                // HEADER DEL MENÚ
                // ═══════════════════════════════════════════
                _buildMenuHeader(context),

                const SizedBox(height: 8),

                Divider(color: Colors.grey.shade200, height: 1),

                // ═══════════════════════════════════════════
                // ENLACES DEL MENÚ
                // ═══════════════════════════════════════════
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
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
                          icon: Icons.local_offer_rounded,
                          label: "Ofertas",
                          onTap: null, // Establecer onTap a null para deshabilitar
                          isEnabled: false, // Indicar que está deshabilitado
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Divider(color: Colors.grey.shade200),
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

                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                          ),
                          child: Divider(color: Colors.grey.shade200),
                        ),

                        _MenuLink(
                          icon: Icons.phone_rounded,
                          label: "Contacto",
                          onTap: () => _navigateTo(context, '/contacto'),
                        ),

                        // ═══════════════════════════════════════════
                        // SECCIÓN DE POLÍTICAS (Desplegable)
                        // ═══════════════════════════════════════════
                        Theme(
                          // Usamos Theme para quitar el divider interno de ExpansionTile y otros estilos si es necesario
                          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
                            childrenPadding: const EdgeInsets.only(left: 32, right: 16), // Indentación para los elementos hijos
                            leading: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.gavel_rounded, // Icono para la sección Políticas
                                color: AppColors.purple600,
                                size: 20,
                              ),
                            ),
                            title: Text(
                              "Políticas",
                              style: AppText.body.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            iconColor: AppColors.purple600, // Color de la flecha de expansión
                            collapsedIconColor: AppColors.purple600,
                            
                            children: [
                              _MenuLink(
                                icon: Icons.description_rounded, // Icono para Aviso Legal
                                label: "Aviso Legal",
                                onTap: () => _navigateTo(context, '/aviso-legal'),
                              ),
                              _MenuLink(
                                icon: Icons.lock_rounded, // Icono para Política de Privacidad
                                label: "Política de Privacidad",
                                onTap: () => _navigateTo(context, '/politica-privacidad'),
                              ),
                              _MenuLink(
                                icon: Icons.cookie_rounded, // Icono para Política de Cookies
                                label: "Política de Cookies",
                                onTap: () => _navigateTo(context, '/politica-cookies'),
                              ),
                              _MenuLink(
                                icon: Icons.local_shipping_rounded, // Icono para Política de Envíos
                                label: "Política de Envíos",
                                onTap: () => _navigateTo(context, '/politica-envios'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ═══════════════════════════════════════════
                // FOOTER DEL MENÚ
                // ═══════════════════════════════════════════
                _buildMenuFooter(),
              ],
            ),
          ),
        ),
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
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                  Text(
                    "Menú",
                    style: AppText.title.copyWith(fontSize: 18),
                  ),
                ],
              ),
            ],
          ),
          // Botón cerrar
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
    Navigator.pop(context); // Cerrar drawer
    Navigator.pushNamed(context, route);
  }
}

// ═══════════════════════════════════════════════════════════
// WIDGET: ENLACE DEL MENÚ (Modificado para habilitar/deshabilitar)
// ═══════════════════════════════════════════════════════════
class _MenuLink extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap; // Ahora puede ser null
  final bool isEnabled; // Nuevo parámetro para controlar la habilitación

  const _MenuLink({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isEnabled = true, // Por defecto está habilitado
  });

  @override
  Widget build(BuildContext context) {
    // Definir colores basados en si el enlace está habilitado o no
    final Color iconColor = isEnabled ? AppColors.purple600 : Colors.grey.shade400;
    final Color textColor = isEnabled ? AppText.body.color ?? Colors.black : Colors.grey.shade600;
    final Color chevronColor = isEnabled ? AppColors.purple600 : Colors.grey.shade300;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onTap : null, // Deshabilita el InkWell si isEnabled es false
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor, // Color condicional
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: textColor, // Color condicional
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: chevronColor, // Color condicional
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
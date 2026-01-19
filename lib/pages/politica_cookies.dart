import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';

class PoliticaCookies extends StatefulWidget {
  const PoliticaCookies({super.key});

  @override
  State<PoliticaCookies> createState() => _PoliticaCookiesState();
}

class _PoliticaCookiesState extends State<PoliticaCookies> {
  int selectedIndex = -1;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(),
                      const SizedBox(height: 20),

                      _buildPageHeader(
                        icon: Icons.cookie_rounded,
                        title: "Política de Cookies",
                        subtitle: "Información sobre el uso de cookies",
                      ),
                      const SizedBox(height: 24),

                      _buildSection(
                        title: "1. ¿Qué son las cookies?",
                        content: """
Las cookies son pequeños archivos de texto que los sitios web y aplicaciones almacenan en su dispositivo (ordenador, tablet o móvil) cuando los visita. Estas cookies permiten que el sitio web recuerde sus acciones y preferencias durante un período de tiempo.

Las cookies pueden ser:
• **Cookies propias:** Establecidas por el sitio web que está visitando.
• **Cookies de terceros:** Establecidas por otros sitios web diferentes al que está visitando.""",
                      ),

                      _buildSection(
                        title: "2. ¿Qué tipos de cookies utilizamos?",
                        content: """
En nuestra web y aplicación utilizamos los siguientes tipos de cookies:

**Cookies técnicas (necesarias)**
Son esenciales para el funcionamiento del sitio web y la aplicación. Permiten la navegación y el uso de las diferentes opciones y servicios. Sin estas cookies, algunas funcionalidades no estarían disponibles.

**Cookies de preferencias**
Permiten recordar información para que el usuario acceda al servicio con determinadas características que pueden diferenciar su experiencia de la de otros usuarios (idioma, número de resultados, etc.).

**Cookies de análisis**
Permiten el seguimiento y análisis del comportamiento de los usuarios. Se utilizan para medir la actividad del sitio web y elaborar perfiles de navegación con el fin de mejorar el servicio.

**Cookies de publicidad comportamental**
Almacenan información del comportamiento de los usuarios obtenida a través de la observación continuada de sus hábitos de navegación, lo que permite desarrollar un perfil específico para mostrar publicidad personalizada.""",
                      ),

                      _buildCookieTable(),

                      _buildSection(
                        title: "3. ¿Cómo gestionar las cookies?",
                        content: """
Usted puede permitir, bloquear o eliminar las cookies instaladas en su equipo mediante la configuración de las opciones del navegador instalado en su ordenador o dispositivo móvil.

**Google Chrome:**
Configuración → Privacidad y seguridad → Cookies y otros datos de sitios

**Mozilla Firefox:**
Opciones → Privacidad y seguridad → Cookies y datos del sitio

**Safari:**
Preferencias → Privacidad → Cookies y datos de sitios web

**Microsoft Edge:**
Configuración → Cookies y permisos del sitio → Cookies y datos del sitio

Tenga en cuenta que si bloquea las cookies, algunas funcionalidades del sitio web o aplicación podrían no estar disponibles.""",
                      ),

                      _buildSection(
                        title: "4. Cookies de terceros",
                        content: """
Nuestro sitio web puede utilizar servicios de terceros que recopilan información con fines estadísticos, de uso del sitio y para la prestación de otros servicios relacionados:

• **Google Analytics:** Análisis del tráfico web y comportamiento de usuarios.
• **Redes sociales:** Botones de compartir contenido en redes sociales.
• **Pasarelas de pago:** Para procesar pagos de forma segura.

Cada uno de estos servicios tiene su propia política de privacidad y de cookies.""",
                      ),

                      _buildSection(
                        title: "5. Actualizaciones de esta política",
                        content: """
FARMACIA GUERRERO C.B. puede modificar esta Política de Cookies en función de exigencias legislativas, reglamentarias, o con la finalidad de adaptar dicha política a las instrucciones dictadas por la Agencia Española de Protección de Datos.

Se recomienda revisar esta política cada vez que acceda a nuestro sitio web o aplicación con el objetivo de estar adecuadamente informado sobre cómo y para qué usamos las cookies.""",
                      ),

                      _buildSection(
                        title: "6. Contacto",
                        content: """
Si tiene alguna duda sobre esta Política de Cookies, puede contactar con nosotros:

• **Correo electrónico:** farmaciaguerrerocb@gmail.com
• **Teléfono:** +34 616 335 693
• **Dirección:** Fernández Ballesteros 7, 11009 Cádiz, España""",
                      ),

                      _buildUpdateInfo("Última actualización: Enero 2026"),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
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

  Widget _buildCookieTable() {
    final cookies = [
      {
        "nombre": "session_id",
        "tipo": "Técnica",
        "duracion": "Sesión",
        "proposito": "Identificación de sesión",
      },
      {
        "nombre": "cart_items",
        "tipo": "Técnica",
        "duracion": "30 días",
        "proposito": "Carrito de compra",
      },
      {
        "nombre": "user_preferences",
        "tipo": "Preferencias",
        "duracion": "1 año",
        "proposito": "Configuración del usuario",
      },
      {
        "nombre": "_ga",
        "tipo": "Análisis",
        "duracion": "2 años",
        "proposito": "Google Analytics",
      },
      {
        "nombre": "_gid",
        "tipo": "Análisis",
        "duracion": "24 horas",
        "proposito": "Google Analytics",
      },
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Cookies utilizadas",
            style: AppText.subtitle.copyWith(
              fontSize: 16,
              color: AppColors.green700,
            ),
          ),
          const SizedBox(height: 16),
          ...cookies.map((cookie) => _buildCookieRow(cookie)),
        ],
      ),
    );
  }

  Widget _buildCookieRow(Map<String, String> cookie) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCookieTypeColor(cookie["tipo"]!),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  cookie["tipo"]!,
                  style: AppText.small.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cookie["nombre"]!,
                  style: AppText.body.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(
                cookie["duracion"]!,
                style: AppText.small.copyWith(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  cookie["proposito"]!,
                  style: AppText.small.copyWith(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getCookieTypeColor(String tipo) {
    switch (tipo) {
      case "Técnica":
        return AppColors.green600;
      case "Preferencias":
        return AppColors.purple500;
      case "Análisis":
        return Colors.green.shade600;
      default:
        return Colors.grey;
    }
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.purple600,
              size: 20,
            ),
            const SizedBox(width: 6),
            Text(
              "Volver",
              style: AppText.small.copyWith(
                color: AppColors.purple600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green700, AppColors.green500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.green500.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.title.copyWith(
                    color: AppColors.white,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppText.small.copyWith(
                    color: AppColors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppText.subtitle.copyWith(
              fontSize: 16,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 12),
          _buildFormattedText(content),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String text) {
    final List<InlineSpan> spans = [];
    final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in boldPattern.allMatches(text)) {
      if (match.start > lastEnd)
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      spans.add(
        TextSpan(
          text: match.group(1),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      lastEnd = match.end;
    }
    if (lastEnd < text.length)
      spans.add(TextSpan(text: text.substring(lastEnd)));

    return RichText(
      text: TextSpan(
        style: AppText.body.copyWith(
          color: AppColors.textDark.withOpacity(0.75),
          height: 1.6,
          fontSize: 14,
        ),
        children: spans,
      ),
    );
  }

  Widget _buildUpdateInfo(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.update_rounded, color: Colors.green.shade600, size: 18),
          const SizedBox(width: 10),
          Text(
            text,
            style: AppText.small.copyWith(
              color: Colors.green.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

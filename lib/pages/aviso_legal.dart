import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:translator/translator.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';
import '../widgets/auto_text.dart';
import '../providers/language_provider.dart';
import '../widgets/auto_formatted_text.dart';
import '../pages/scanner_page.dart';

class AvisoLegal extends StatefulWidget {
  const AvisoLegal({super.key});

  @override
  State<AvisoLegal> createState() => _AvisoLegalState();
}

class _AvisoLegalState extends State<AvisoLegal> {
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
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Botón volver
                      _buildBackButton(),
                      const SizedBox(height: 20),

                      // Header
                      _buildPageHeader(
                        icon: Icons.gavel_rounded,
                        title: "Aviso Legal",
                        subtitle: "Información legal y términos de uso",
                      ),
                      const SizedBox(height: 24),

                      // Contenido - TODO TRADUCIDO
                      _buildSection(
                        title: "1. Datos identificativos",
                        content: """
En cumplimiento del deber de información recogido en el artículo 10 de la Ley 34/2002, de 11 de julio, de Servicios de la Sociedad de la Información y del Comercio Electrónico (LSSI-CE), a continuación se reflejan los siguientes datos:

• **Denominación social:** FARMACIA GUERRERO C.B.
• **CIF/NIF:** E67886093
• **Domicilio:** Fernández Ballesteros 7, 11009 Cádiz, España
• **Teléfono:** +34 616 335 693
• **Correo electrónico:** farmaciaguerrerocb@gmail.com
• **Sitio web:** https://www.farmaciaguerrerozieza.com

La farmacia se encuentra debidamente autorizada por las autoridades sanitarias competentes y está inscrita en el Registro de Farmacias de la Junta de Andalucía.""",
                      ),

                      _buildSection(
                        title: "2. Objeto",
                        content: """
El presente Aviso Legal regula el uso del sitio web y la aplicación móvil de FARMACIA GUERRERO C.B. (en adelante, "la Farmacia"), poniendo a disposición de los usuarios información sobre sus productos y servicios.

La Farmacia se reserva el derecho a modificar cualquier tipo de información que pudiera aparecer en el sitio web o aplicación, sin que exista obligación de preavisar o poner en conocimiento de los usuarios dichas modificaciones, entendiéndose como suficiente la publicación en el sitio web.""",
                      ),

                      _buildSection(
                        title: "3. Condiciones de uso",
                        content: """
El acceso al sitio web y/o aplicación de la Farmacia atribuye la condición de usuario e implica la aceptación plena y sin reservas de todas las disposiciones incluidas en este Aviso Legal.

El usuario se compromete a:

• Hacer un uso adecuado y lícito del sitio web y aplicación
• No realizar actividades ilícitas, ilegales o contrarias a la buena fe
• No difundir contenidos de carácter racista, xenófobo, pornográfico, de apología del terrorismo o que atenten contra los derechos humanos
• No provocar daños en los sistemas físicos y lógicos de la Farmacia
• No introducir virus informáticos o cualesquiera otros sistemas que causen daños
• No intentar acceder a áreas restringidas de los sistemas de la Farmacia""",
                      ),

                      _buildSection(
                        title: "4. Propiedad intelectual e industrial",
                        content: """
El sitio web, aplicación y todos sus contenidos (textos, fotografías, gráficos, imágenes, iconos, tecnología, software, links y demás contenidos audiovisuales o sonoros), así como su diseño gráfico y códigos fuente, son propiedad de la Farmacia o de terceros cuyos derechos al respecto ostenta legítimamente la Farmacia.

Quedan expresamente prohibidas:
• La reproducción, distribución o modificación de los contenidos sin autorización expresa
• La utilización de los contenidos con fines comerciales sin autorización
• Cualquier vulneración de los derechos de la Farmacia sobre los contenidos

El usuario se compromete a respetar los derechos de propiedad intelectual e industrial de la Farmacia.""",
                      ),

                      _buildSection(
                        title: "5. Exclusión de garantías y responsabilidad",
                        content: """
La Farmacia no se hace responsable, en ningún caso, de los daños y perjuicios de cualquier naturaleza que pudieran ocasionar, a título enunciativo:

• Errores u omisiones en los contenidos
• Falta de disponibilidad del sitio web o aplicación
• Transmisión de virus o programas maliciosos en los contenidos
• Uso ilícito, negligente o fraudulento del sitio web o aplicación
• Falta de veracidad, exactitud o actualidad de los contenidos

La Farmacia se compromete a realizar los máximos esfuerzos para evitar cualquier error en los contenidos que pudieran aparecer en el sitio web o aplicación.""",
                      ),

                      _buildSection(
                        title: "6. Legislación aplicable y jurisdicción",
                        content: """
La relación entre la Farmacia y el usuario se regirá por la normativa española vigente.

Para la resolución de cualquier controversia que pudiera surgir, las partes se someten a los Juzgados y Tribunales de Cádiz, renunciando expresamente a cualquier otro fuero que pudiera corresponderles, salvo que la normativa aplicable establezca imperativamente un fuero distinto.""",
                      ),

                      _buildSection(
                        title: "7. Contacto",
                        content: """
Para cualquier duda, consulta o sugerencia sobre este Aviso Legal, puede ponerse en contacto con nosotros a través de:

• **Correo electrónico:** farmaciaguerrerocb@gmail.com
• **Teléfono:** +34 616 335 693
• **Dirección postal:** Fernández Ballesteros 7, 11009 Cádiz, España""",
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
            // ← TRADUCIDO
            AutoText(
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
                // ← TRADUCIDO
                AutoText(
                  title,
                  style: AppText.title.copyWith(
                    color: AppColors.white,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
                // ← TRADUCIDO
                AutoText(
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
          // ← TÍTULO TRADUCIDO
          AutoText(
            title,
            style: AppText.subtitle.copyWith(
              fontSize: 16,
              color: AppColors.green700,
            ),
          ),
          const SizedBox(height: 12),
          // ← CONTENIDO TRADUCIDO CON FORMATO
          AutoFormattedText(content: content),
        ],
      ),
    );
  }

  Widget _buildUpdateInfo(String text) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.green50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.green200),
      ),
      child: Row(
        children: [
          Icon(Icons.update_rounded, color: AppColors.green600, size: 18),
          const SizedBox(width: 10),
          // ← TRADUCIDO
          AutoText(
            text,
            style: AppText.small.copyWith(
              color: AppColors.green700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

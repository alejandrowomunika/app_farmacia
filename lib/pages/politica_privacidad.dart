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

class PoliticaPrivacidad extends StatefulWidget {
  const PoliticaPrivacidad({super.key});

  @override
  State<PoliticaPrivacidad> createState() => _PoliticaPrivacidadState();
}

class _PoliticaPrivacidadState extends State<PoliticaPrivacidad> {
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
                      _buildBackButton(),
                      const SizedBox(height: 20),

                      _buildPageHeader(
                        icon: Icons.shield_rounded,
                        title: "Política de Privacidad",
                        subtitle: "Protección de tus datos personales",
                      ),
                      const SizedBox(height: 24),

                      _buildSection(
                        title: "1. Responsable del tratamiento",
                        content: """
De conformidad con lo dispuesto en el Reglamento (UE) 2016/679 del Parlamento Europeo y del Consejo, de 27 de abril de 2016 (RGPD), y la Ley Orgánica 3/2018, de 5 de diciembre, de Protección de Datos Personales (LOPDGDD), le informamos que:

• **Responsable:** FARMACIA GUERRERO C.B.
• **CIF:** E67886093
• **Dirección:** Fernández Ballesteros 7, 11009 Cádiz, España
• **Correo electrónico:** farmaciaguerrerocb@gmail.com
• **Teléfono:** +34 616 335 693""",
                      ),

                      _buildSection(
                        title: "2. Finalidad del tratamiento",
                        content: """
Los datos personales que nos facilite serán tratados con las siguientes finalidades:

• **Gestión de pedidos:** Procesar y gestionar sus compras, incluyendo el envío de productos y la facturación.
• **Atención al cliente:** Responder a sus consultas, solicitudes y reclamaciones.
• **Comunicaciones comerciales:** Enviarle información sobre ofertas, promociones y novedades (solo con su consentimiento previo).
• **Cumplimiento legal:** Atender obligaciones legales y requerimientos de autoridades competentes.
• **Mejora del servicio:** Analizar el uso de nuestra web y aplicación para mejorar la experiencia del usuario.""",
                      ),

                      _buildSection(
                        title: "3. Legitimación del tratamiento",
                        content: """
La base legal para el tratamiento de sus datos es:

• **Ejecución de un contrato:** Para la gestión de pedidos y prestación de servicios solicitados.
• **Consentimiento del interesado:** Para el envío de comunicaciones comerciales y uso de cookies no esenciales.
• **Interés legítimo:** Para la mejora de nuestros servicios y prevención del fraude.
• **Cumplimiento de obligaciones legales:** Para atender requerimientos legales y fiscales.""",
                      ),

                      _buildSection(
                        title: "4. Destinatarios de los datos",
                        content: """
Sus datos podrán ser comunicados a:

• **Entidades bancarias:** Para la gestión de pagos.
• **Empresas de transporte:** Para la entrega de pedidos.
• **Administraciones públicas:** Cuando así lo exija la normativa aplicable.
• **Proveedores de servicios:** Que nos asisten en la prestación de nuestros servicios (hosting, email marketing, etc.), con los que tenemos firmados contratos de encargado del tratamiento.

No se realizarán transferencias internacionales de datos fuera del Espacio Económico Europeo, salvo obligación legal o con su consentimiento expreso.""",
                      ),

                      _buildSection(
                        title: "5. Plazo de conservación",
                        content: """
Conservaremos sus datos personales durante los siguientes plazos:

• **Datos de clientes:** Durante la relación comercial y posteriormente durante el plazo de prescripción de las acciones legales que pudieran derivarse (5 años con carácter general).
• **Datos fiscales:** 4 años según la normativa tributaria.
• **Datos de comunicaciones comerciales:** Hasta que solicite la baja o revoque su consentimiento.
• **Datos de navegación:** Según lo establecido en nuestra Política de Cookies.""",
                      ),

                      _buildSection(
                        title: "6. Derechos del interesado",
                        content: """
Usted tiene derecho a:

• **Acceso:** Conocer qué datos personales tratamos sobre usted.
• **Rectificación:** Solicitar la corrección de datos inexactos o incompletos.
• **Supresión:** Solicitar la eliminación de sus datos cuando ya no sean necesarios.
• **Oposición:** Oponerse al tratamiento de sus datos en determinadas circunstancias.
• **Limitación:** Solicitar la limitación del tratamiento en ciertos casos.
• **Portabilidad:** Recibir sus datos en un formato estructurado y transmitirlos a otro responsable.
• **Retirar el consentimiento:** En cualquier momento, sin que afecte a la licitud del tratamiento previo.

Para ejercer estos derechos, puede dirigirse a:
**farmaciaguerrerocb@gmail.com**

Asimismo, tiene derecho a presentar una reclamación ante la Agencia Española de Protección de Datos (www.aepd.es).""",
                      ),

                      _buildSection(
                        title: "7. Medidas de seguridad",
                        content: """
Hemos adoptado las medidas técnicas y organizativas necesarias para garantizar la seguridad de sus datos personales y evitar su alteración, pérdida, tratamiento o acceso no autorizado:

• Cifrado de datos sensibles
• Control de acceso a los sistemas
• Copias de seguridad periódicas
• Formación del personal en protección de datos
• Revisión periódica de las medidas de seguridad""",
                      ),

                      _buildSection(
                        title: "8. Modificaciones de la política",
                        content: """
FARMACIA GUERRERO C.B. se reserva el derecho a modificar la presente Política de Privacidad para adaptarla a novedades legislativas o jurisprudenciales, así como a prácticas de la industria.

En dichos supuestos, anunciaremos en esta página los cambios introducidos con razonable antelación a su puesta en práctica.""",
                      ),

                      _buildSection(
                        title: "9. Contacto",
                        content: """
Para cualquier cuestión relacionada con el tratamiento de sus datos personales, puede contactar con nosotros:

• **Correo electrónico:** farmaciaguerrerocb@gmail.com
• **Teléfono:** +34 616 335 693
• **Dirección postal:** Fernández Ballesteros 7, 11009 Cádiz, España""",
                      ),

                      _buildUpdateInfo("Última actualización: Enero 2025"),
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
        onScanTap: _openScanner,
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
                AutoText(
                  title,
                  style: AppText.title.copyWith(
                    color: AppColors.white,
                    fontSize: 22,
                  ),
                ),
                const SizedBox(height: 4),
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
          AutoText(
            title,
            style: AppText.subtitle.copyWith(
              fontSize: 16,
              color: AppColors.green700,
            ),
          ),
          const SizedBox(height: 12),
          // ← CAMBIO: Usar AutoFormattedText
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

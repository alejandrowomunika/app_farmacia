import 'package:flutter/material.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';

class PoliticaEnvios extends StatefulWidget {
  const PoliticaEnvios({super.key});

  @override
  State<PoliticaEnvios> createState() => _PoliticaEnviosState();
}

class _PoliticaEnviosState extends State<PoliticaEnvios> {
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
                        icon: Icons.local_shipping_rounded,
                        title: "Política de Envíos",
                        subtitle: "Información sobre entregas y devoluciones",
                      ),
                      const SizedBox(height: 24),

                      // Tarjetas de resumen
                      _buildSummaryCards(),
                      const SizedBox(height: 20),

                      _buildSection(
                        title: "1. Ámbito de envío",
                        content: """
FARMACIA GUERRERO C.B. realiza envíos a todo el territorio nacional (España peninsular, Islas Baleares, Islas Canarias, Ceuta y Melilla).

**España peninsular y Baleares:**
Entrega estándar en 24-72 horas laborables.

**Islas Canarias, Ceuta y Melilla:**
Entrega en 3-7 días laborables. Los envíos a estas zonas pueden estar sujetos a trámites aduaneros y tasas adicionales que correrán a cargo del cliente.""",
                      ),

                      _buildSection(
                        title: "2. Gastos de envío",
                        content: """
Los gastos de envío se calculan en función del peso del pedido y el destino:

**España peninsular:**
• Pedidos superiores a 49€: **ENVÍO GRATUITO**
• Pedidos inferiores a 49€: 4,95€

**Islas Baleares:**
• Pedidos superiores a 69€: **ENVÍO GRATUITO**
• Pedidos inferiores a 69€: 6,95€

**Islas Canarias, Ceuta y Melilla:**
• Gastos de envío: desde 9,95€ (según peso)
• Pueden aplicarse tasas aduaneras adicionales

Los gastos de envío definitivos se mostrarán antes de finalizar la compra.""",
                      ),

                      _buildSection(
                        title: "3. Plazos de entrega",
                        content: """
Los plazos de entrega son orientativos y comienzan a contar desde la confirmación del pedido:

• **España peninsular:** 24-72 horas laborables
• **Islas Baleares:** 48-72 horas laborables
• **Islas Canarias, Ceuta y Melilla:** 3-7 días laborables

**Importante:**
• Los pedidos realizados antes de las 14:00h (de lunes a viernes) se procesan el mismo día.
• Los pedidos realizados después de las 14:00h o en fin de semana se procesarán el siguiente día laborable.
• Durante períodos de alta demanda (rebajas, navidades, etc.) los plazos pueden verse incrementados.""",
                      ),

                      _buildSection(
                        title: "4. Seguimiento del pedido",
                        content: """
Una vez que su pedido haya sido enviado, recibirá un correo electrónico con:

• Confirmación de envío
• Número de seguimiento
• Enlace para rastrear su pedido

Podrá consultar el estado de su pedido en cualquier momento a través del enlace proporcionado o contactando con nuestro servicio de atención al cliente.""",
                      ),

                      _buildSection(
                        title: "5. Recepción del pedido",
                        content: """
**En el momento de la entrega:**

• Compruebe que el paquete está en buen estado antes de firmar
• Si el paquete presenta daños visibles, indíquelo en el albarán de entrega y contacte con nosotros en las siguientes 24 horas
• Si no puede estar presente, puede indicar una dirección alternativa o autorizar a otra persona

**Si no está en el domicilio:**
• El transportista dejará un aviso y realizará un segundo intento de entrega
• Podrá recoger el paquete en la oficina de la empresa de transporte
• Después de varios intentos fallidos, el paquete será devuelto a nuestras instalaciones""",
                      ),

                      _buildSection(
                        title: "6. Devoluciones y cambios",
                        content: """
Tiene derecho a desistir del contrato en un plazo de **14 días naturales** desde la recepción del producto, sin necesidad de justificación.

**Para realizar una devolución:**
1. Contacte con nosotros por email o teléfono
2. Le enviaremos las instrucciones de devolución
3. Embale el producto en su embalaje original
4. Envíe el producto a nuestra dirección

**Condiciones:**
• El producto debe estar sin usar y en su embalaje original
• Los gastos de devolución corren a cargo del cliente (excepto productos defectuosos)
• El reembolso se realizará en un máximo de 14 días tras recibir el producto

**Productos excluidos del derecho de desistimiento:**
• Medicamentos (por razones de protección de la salud)
• Productos precintados que hayan sido desprecintados
• Productos personalizados o hechos a medida""",
                      ),

                      _buildSection(
                        title: "7. Productos defectuosos o erróneos",
                        content: """
Si recibe un producto defectuoso o diferente al solicitado:

1. Contacte con nosotros en un plazo máximo de 48 horas
2. Envíenos fotografías del producto y del embalaje
3. Gestionaremos la recogida sin coste alguno
4. Le enviaremos el producto correcto o realizaremos el reembolso

En caso de productos defectuosos, asumiremos todos los gastos de devolución y nuevo envío.""",
                      ),

                      _buildSection(
                        title: "8. Contacto",
                        content: """
Para cualquier consulta sobre envíos y devoluciones:

• **Correo electrónico:** farmaciaguerrerocb@gmail.com
• **Teléfono:** +34 616 335 693
• **Horario de atención:** Lunes a Viernes de 9:00 a 20:00

**Dirección para devoluciones:**
FARMACIA GUERRERO C.B.
Fernández Ballesteros 7
11009 Cádiz, España""",
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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.local_shipping_outlined,
            title: "Envío gratis",
            subtitle: "Desde 49€",
            color: AppColors.green500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.access_time_rounded,
            title: "24-72h",
            subtitle: "Península",
            color: AppColors.purple500,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            icon: Icons.replay_rounded,
            title: "14 días",
            subtitle: "Devolución",
            color: Colors.orange.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: AppText.subtitle.copyWith(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppText.small.copyWith(
              color: AppColors.textDark.withOpacity(0.5),
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
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

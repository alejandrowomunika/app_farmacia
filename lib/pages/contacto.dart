import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';

class Contacto extends StatefulWidget {
  const Contacto({super.key});

  @override
  State<Contacto> createState() => _ContactoState();
}

class _ContactoState extends State<Contacto> {
  int selectedIndex = -1;
  final _formKey = GlobalKey<FormState>();

  // Controladores del formulario
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _asuntoController = TextEditingController();
  final _mensajeController = TextEditingController();

  bool _isLoading = false;
  String? _selectedMotivo;

  final List<String> _motivos = [
    'Consulta general',
    'Información sobre productos',
    'Estado de mi pedido',
    'Devolución o cambio',
    'Reclamación',
    'Sugerencia',
    'Otros',
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _asuntoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

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

  // ═══════════════════════════════════════════════════════════
  // ACCIONES DE CONTACTO
  // ═══════════════════════════════════════════════════════════
  Future<void> _llamar() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+34616335693');
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _mostrarSnackBar('No se pudo abrir el teléfono', isError: true);
    }
  }

  Future<void> _enviarEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'farmaciaguerrerocb@gmail.com',
      queryParameters: {'subject': 'Consulta desde la App'},
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _mostrarSnackBar('No se pudo abrir el email', isError: true);
    }
  }

  Future<void> _abrirWhatsApp() async {
    final Uri whatsappUri = Uri.parse(
      'https://wa.me/34616335693?text=Hola, me gustaría hacer una consulta.',
    );
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      _mostrarSnackBar('No se pudo abrir WhatsApp', isError: true);
    }
  }

  Future<void> _abrirMapa() async {
    final Uri mapsUri = Uri.parse(
      'https://maps.google.com/?q=Fernandez+Ballesteros+7,+11009+Cadiz,+Spain',
    );
    if (await canLaunchUrl(mapsUri)) {
      await launchUrl(mapsUri, mode: LaunchMode.externalApplication);
    } else {
      _mostrarSnackBar('No se pudo abrir el mapa', isError: true);
    }
  }

  void _copiarDireccion() {
    Clipboard.setData(
      const ClipboardData(text: 'Fernández Ballesteros 7, 11009 Cádiz, España'),
    );
    _mostrarSnackBar('Dirección copiada al portapapeles');
  }

  Future<void> _enviarFormulario() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMotivo == null) {
      _mostrarSnackBar(
        'Por favor, selecciona un motivo de contacto',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    // Simular envío
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isLoading = false);

    // Limpiar formulario
    _nombreController.clear();
    _emailController.clear();
    _telefonoController.clear();
    _asuntoController.clear();
    _mensajeController.clear();
    setState(() => _selectedMotivo = null);

    _mostrarSnackBar(
      '¡Mensaje enviado correctamente! Te responderemos pronto.',
    );
  }

  void _mostrarSnackBar(String mensaje, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: AppColors.white,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(mensaje)),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : AppColors.green600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
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

                      // Header
                      _buildPageHeader(),
                      const SizedBox(height: 24),

                      // Tarjetas de contacto rápido
                      _buildQuickContactCards(),
                      const SizedBox(height: 24),

                      // Información de la farmacia
                      _buildInfoCard(),
                      const SizedBox(height: 24),

                      // Horarios
                      _buildHorariosCard(),
                      const SizedBox(height: 24),

                      // Formulario de contacto
                      _buildFormularioContacto(),
                      const SizedBox(height: 24),

                      // Ubicación
                      _buildUbicacionCard(),
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

  Widget _buildPageHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.green600, AppColors.green500],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.green500.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: AppColors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "¿En qué podemos ayudarte?",
            style: AppText.title.copyWith(color: AppColors.white, fontSize: 24),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            "Estamos aquí para resolver todas tus dudas",
            style: AppText.body.copyWith(
              color: AppColors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TARJETAS DE CONTACTO RÁPIDO
  // ═══════════════════════════════════════════════════════════
  Widget _buildQuickContactCards() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickContactCard(
            icon: Icons.phone_rounded,
            label: "Llamar",
            color: AppColors.green500,
            onTap: _llamar,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickContactCard(
            icon: Icons.email_rounded,
            label: "Email",
            color: AppColors.green500,
            onTap: _enviarEmail,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickContactCard(
            icon: Icons.chat_rounded,
            label: "WhatsApp",
            color: AppColors.green500,
            onTap: _abrirWhatsApp,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickContactCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppText.small.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TARJETA DE INFORMACIÓN
  // ═══════════════════════════════════════════════════════════
  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.green100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_pharmacy_rounded,
                  color: AppColors.green600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FARMACIA GUERRERO",
                      style: AppText.subtitle.copyWith(fontSize: 16),
                    ),
                    Text(
                      "Tu farmacia de confianza",
                      style: AppText.small.copyWith(color: AppColors.green600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(
            icon: Icons.phone_outlined,
            label: "Teléfono",
            value: "+34 616 335 693",
            onTap: _llamar,
          ),
          _buildInfoRow(
            icon: Icons.email_outlined,
            label: "Email",
            value: "farmaciaguerrerocb@gmail.com",
            onTap: _enviarEmail,
          ),
          _buildInfoRow(
            icon: Icons.location_on_outlined,
            label: "Dirección",
            value: "Fernández Ballesteros 7\n11009 Cádiz, España",
            onTap: _copiarDireccion,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(bottom: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.green600, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppText.small.copyWith(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppText.body.copyWith(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TARJETA DE HORARIOS
  // ═══════════════════════════════════════════════════════════
  Widget _buildHorariosCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purple100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.schedule_rounded,
                  color: AppColors.purple600,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Text(
                "Horario de atención",
                style: AppText.subtitle.copyWith(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildHorarioRow("Lunes - Viernes", "09:00 - 21:30", isOpen: true),
          _buildHorarioRow("Sábados", "09:30 - 14:00", isOpen: true),
          _buildHorarioRow(
            "Domingos y festivos",
            "Cerrado",
            isOpen: false,
            isLast: true,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.green200),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.green600,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Para urgencias fuera de horario, consulte las farmacias de guardia.",
                    style: AppText.small.copyWith(
                      color: AppColors.green700,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorarioRow(
    String dia,
    String horario, {
    required bool isOpen,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(dia, style: AppText.body.copyWith(fontSize: 14)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isOpen ? AppColors.green100 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              horario,
              style: AppText.small.copyWith(
                color: isOpen ? AppColors.green700 : Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // FORMULARIO DE CONTACTO
  // ═══════════════════════════════════════════════════════════
  Widget _buildFormularioContacto() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    color: Colors.blue.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Envíanos un mensaje",
                        style: AppText.subtitle.copyWith(fontSize: 16),
                      ),
                      Text(
                        "Te responderemos lo antes posible",
                        style: AppText.small.copyWith(
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Nombre
            _buildTextField(
              controller: _nombreController,
              label: "Nombre completo",
              icon: Icons.person_outline_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, introduce tu nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            _buildTextField(
              controller: _emailController,
              label: "Correo electrónico",
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, introduce tu email';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Introduce un email válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Teléfono (opcional)
            _buildTextField(
              controller: _telefonoController,
              label: "Teléfono (opcional)",
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),

            // Motivo
            _buildDropdown(),
            const SizedBox(height: 16),

            // Asunto
            _buildTextField(
              controller: _asuntoController,
              label: "Asunto",
              icon: Icons.subject_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, introduce un asunto';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Mensaje
            _buildTextField(
              controller: _mensajeController,
              label: "Mensaje",
              icon: Icons.message_outlined,
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, escribe tu mensaje';
                }
                if (value.length < 10) {
                  return 'El mensaje debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Botón enviar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _enviarFormulario,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green500,
                  foregroundColor: AppColors.white,
                  disabledBackgroundColor: AppColors.green300,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: AppColors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "Enviar mensaje",
                            style: AppText.button.copyWith(fontSize: 15),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: AppText.body.copyWith(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppText.body.copyWith(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, color: AppColors.green600, size: 22),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green500, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedMotivo,
      decoration: InputDecoration(
        labelText: "Motivo de contacto",
        labelStyle: AppText.body.copyWith(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.category_outlined,
          color: AppColors.green600,
          size: 22,
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.green500, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      items: _motivos.map((motivo) {
        return DropdownMenuItem(
          value: motivo,
          child: Text(motivo, style: AppText.body.copyWith(fontSize: 15)),
        );
      }).toList(),
      onChanged: (value) {
        setState(() => _selectedMotivo = value);
      },
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.green600,
      ),
      dropdownColor: AppColors.white,
      borderRadius: BorderRadius.circular(12),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TARJETA DE UBICACIÓN
  // ═══════════════════════════════════════════════════════════
  Widget _buildUbicacionCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Mapa placeholder
          GestureDetector(
            onTap: _abrirMapa,
            child: Container(
              height: 180,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                gradient: LinearGradient(
                  colors: [AppColors.green100, AppColors.green50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Stack(
                children: [
                  // Patrón decorativo
                  Positioned.fill(
                    child: CustomPaint(painter: _MapPatternPainter()),
                  ),
                  // Contenido central
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green500.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.green600,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "Ver en Google Maps",
                                style: AppText.small.copyWith(
                                  color: AppColors.green700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                color: AppColors.green600,
                                size: 16,
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
          ),
          // Información de ubicación
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nuestra ubicación",
                        style: AppText.subtitle.copyWith(fontSize: 15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Fernández Ballesteros 7, 11009 Cádiz",
                        style: AppText.small.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _abrirMapa,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green500,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: Text(
                    "Cómo llegar",
                    style: AppText.small.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PAINTER: PATRÓN DECORATIVO DEL MAPA
// ═══════════════════════════════════════════════════════════════════════════════
class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.green200.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Líneas horizontales
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Líneas verticales
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Círculos decorativos
    final circlePaint = Paint()
      ..color = AppColors.green300.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.3),
      20,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.7),
      15,
      circlePaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.6, size.height * 0.2),
      10,
      circlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

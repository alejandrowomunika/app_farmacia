import 'package:flutter/material.dart';

import '../widgets/header.dart';
import '../widgets/footer.dart';
import '../theme/app_theme.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> with SingleTickerProviderStateMixin {
  int selectedIndex = 2;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Ejemplos de preguntas que se podrán hacer
  final List<Map<String, dynamic>> exampleQuestions = [
    {
      "icon": Icons.medication_outlined,
      "question": "¿Qué puedo tomar para el dolor de cabeza?",
    },
    {
      "icon": Icons.baby_changing_station_outlined,
      "question": "¿Qué crema es mejor para la dermatitis del bebé?",
    },
    {
      "icon": Icons.sunny,
      "question": "¿Qué protector solar me recomiendas?",
    },
    {
      "icon": Icons.local_pharmacy_outlined,
      "question": "¿Cuál es el horario de la farmacia?",
    },
  
  ];

  @override
  void initState() {
    super.initState();
    
    // Animación de pulso para el icono
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void onFooterTap(int index) {
    setState(() => selectedIndex = index);

    if (index == 0) Navigator.pushReplacementNamed(context, '/');
    if (index == 1) Navigator.pushReplacementNamed(context, '/tienda');
    if (index == 2) Navigator.pushReplacementNamed(context, '/chat');
    if (index == 3) Navigator.pushReplacementNamed(context, '/carrito');
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
                    children: [
                      const SizedBox(height: 30),
                      
                      // ═══════════════════════════════════════════
                      // ICONO PRINCIPAL CON ANIMACIÓN
                      // ═══════════════════════════════════════════
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppColors.green600,
                                AppColors.green400,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green500.withOpacity(0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.smart_toy_outlined,
                            size: 60,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // ═══════════════════════════════════════════
                      // TÍTULO Y DESCRIPCIÓN
                      // ═══════════════════════════════════════════
                      Text(
                        "Asistente Farmacéutico",
                        style: AppText.title.copyWith(fontSize: 26),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      // Badge "Próximamente" - PURPLE como detalle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple100.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.purple300.withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 16,
                              color: AppColors.purple600,
                            ),
                            SizedBox(width: 6),
                            Text(
                              "Próximamente",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.purple600,
                                fontFamily: 'Mulish',
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          "Estamos desarrollando un asistente inteligente que te ayudará con todas tus consultas sobre medicamentos, productos y servicios de la farmacia.",
                          textAlign: TextAlign.center,
                          style: AppText.body.copyWith(
                            color: AppColors.textDark.withOpacity(0.7),
                            height: 1.5,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // ═══════════════════════════════════════════
                      // SECCIÓN: PODRÁS PREGUNTAR
                      // ═══════════════════════════════════════════
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Podrás preguntar cosas como:",
                          style: AppText.subtitle.copyWith(fontSize: 16),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Lista de ejemplos
                      ...exampleQuestions.map((item) => _buildExampleQuestion(
                        icon: item["icon"],
                        question: item["question"],
                      )),
                      
                      const SizedBox(height: 40),
                      
                      // ═══════════════════════════════════════════
                      // CARACTERÍSTICAS
                      // ═══════════════════════════════════════════
                      _buildFeatureCard(
                        icon: Icons.psychology_outlined,
                        title: "Inteligencia Artificial",
                        description: "Respuestas precisas basadas en información farmacéutica actualizada",
                        color: AppColors.purple500,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildFeatureCard(
                        icon: Icons.access_time_outlined,
                        title: "Disponible 24/7",
                        description: "Consulta tus dudas en cualquier momento del día",
                        color: AppColors.green500,
                      ),
                      
                      const SizedBox(height: 12),
                      
                      _buildFeatureCard(
                        icon: Icons.verified_user_outlined,
                        title: "Información Fiable",
                        description: "Supervisado por profesionales farmacéuticos",
                        color: AppColors.green600,
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // ═══════════════════════════════════════════
                      // INPUT DESHABILITADO (PREVIEW)
                      // ═══════════════════════════════════════════
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(20),
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
                            // Mensaje de ejemplo del bot
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: AppColors.green500,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.smart_toy_outlined,
                                    color: AppColors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: AppColors.green50,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      "¡Hola! Soy el asistente virtual de Farmacia Guerrero. Pronto estaré disponible para ayudarte con tus consultas. 👋",
                                      style: AppText.body.copyWith(
                                        fontSize: 14,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Input deshabilitado
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.lock_outline,
                                    color: Colors.grey.shade400,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      "Escribe tu consulta...",
                                      style: AppText.body.copyWith(
                                        color: Colors.grey.shade400,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade300,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.send_rounded,
                                      color: Colors.grey.shade500,
                                      size: 20,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 30),
                      
                      // ═══════════════════════════════════════════
                      // CONTACTO ALTERNATIVO
                      // ═══════════════════════════════════════════
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.green50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.green200,
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.phone_in_talk_outlined,
                              color: AppColors.green600,
                              size: 32,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "¿Necesitas ayuda ahora?",
                              style: AppText.subtitle.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "Mientras tanto, puedes contactarnos por teléfono",
                              textAlign: TextAlign.center,
                              style: AppText.small.copyWith(
                                color: AppColors.textDark.withOpacity(0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                // TODO: Abrir teléfono
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text("Llamando a la farmacia..."),
                                    backgroundColor: AppColors.green600,
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.green500,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              icon: const Icon(Icons.call, size: 20),
                              label: Text(
                                "Llamar a la farmacia",
                                style: AppText.button.copyWith(fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
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

  // ═══════════════════════════════════════════════════════════
  // WIDGET: PREGUNTA DE EJEMPLO
  // ═══════════════════════════════════════════════════════════
  Widget _buildExampleQuestion({
    required IconData icon,
    required String question,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.green100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: AppColors.green600,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "\"$question\"",
              style: AppText.body.copyWith(
                fontSize: 14,
                color: AppColors.textDark.withOpacity(0.7),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: TARJETA DE CARACTERÍSTICA
  // ═══════════════════════════════════════════════════════════
  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppText.subtitle.copyWith(fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppText.small.copyWith(
                    color: AppColors.textDark.withOpacity(0.6),
                    height: 1.3,
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
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppHeader extends StatelessWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.92), // Fondo suave con un toque moderno
          border: Border(
            bottom: BorderSide(
              color: AppColors.purple200, // Línea inferior sutil
              width: 1,
            ),
          ),
        ),

        child: Column(

          mainAxisSize: MainAxisSize.min,
          children: [
            // -----------------------------------------------------------
            // ✅ FILA SUPERIOR → Logo + Nombre centrados juntos
            // -----------------------------------------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.center,   // ✅ CENTRA TODO
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔹 Logo farmacia (ocupa toda la altura, sin hacer crecer el header)
                GestureDetector(
                  
                  onTap: () => Navigator.pushNamed(context, '/'),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 30,
                       // ALTURA MÁXIMA DEL LOGO (toca esto para subir/bajar el header)
                       
                    ),
                    child: Image.asset(
                      "assets/logcompleto.png",
                      fit: BoxFit.fitHeight, // AJUSTE: llena la altura manteniendo proporción
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 6), // ESPACIO entre filas

            // -----------------------------------------------------------
            // ✅ BARRA DE BÚSQUEDA (igual que tu diseño)
            // -----------------------------------------------------------
            Container(
              width:270, // ANCHO: ajusta aquí (ej. 180–240). Responsive: usa MediaQuery si quieres %
              height: 30, // ALTO: ajusta aquí (antes 38)
              //margen abajo
              margin: const EdgeInsets.only(bottom: 4), // <-- margen inferior para separar del carrusel
              decoration: BoxDecoration(
                color: AppColors.white.withOpacity(0.82), // FONDO: color + transparencia
                borderRadius: BorderRadius.circular(18), // ESQUINAS: radio del borde
                border: Border.all(
                  color: AppColors.purple500, // BORDE: color
                  width: 1.0, // BORDE: grosor
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8), // PADDING IZQUIERDA

                  Icon(
                    Icons.search,
                    size: 18, // ICONO: tamaño
                    color: AppColors.purple500, // ICONO: color
                  ),

                  const SizedBox(width: 6), // ESPACIO entre icono y campo

                  Expanded(
                    child: TextField(
                      style: AppText.small.copyWith(
                        fontSize: 12, // TEXTO: tamaño
                        color: Colors.black87, // TEXTO: color
                      ),
                      decoration: const InputDecoration(
                        hintText: "Buscar...", // PLACEHOLDER
                        border: InputBorder.none, // SIN borde interno
                        isDense: true, // CAMPO compacto
                        contentPadding: EdgeInsets.symmetric(vertical: 2), // PADDING vertical del texto
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (q) {
                        // ACCIÓN DE BÚSQUEDA: cambia por tu navegación/consulta real
                        print("Buscando: $q");
                      },
                    ),
                  ),

                  const SizedBox(width: 8), // PADDING DERECHA
                ],
              ),
            )
            
          ],
        ),
      ),
    );
  }
}

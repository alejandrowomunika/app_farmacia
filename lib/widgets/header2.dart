import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AppHeader2 extends StatelessWidget {
  const AppHeader2({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: const BoxDecoration(
          color: AppColors.white, 
        ),

        child: Column(

          mainAxisSize: MainAxisSize.min,
          children: [
            // FILA SUPERIOR → Logo + Nombre centrados juntos
            Row(
              mainAxisAlignment: MainAxisAlignment.center,  
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo farmacia
                GestureDetector(
                  
                  onTap: () => Navigator.pushNamed(context, '/'),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 30,
                    ),
                    child: Image.asset(
                      "assets/logcompleto.png",
                      fit: BoxFit.fitHeight,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                )
              ],
            ),
            const SizedBox(height: 6), // ESPACIO entre filas

            // BARRA DE BÚSQUEDA
            Container(
              width:270, 
              height: 30,
              margin: const EdgeInsets.only(bottom: 4), 
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 7, 0, 0).withOpacity(0.82), 
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.purple500,
                  width: 1.0, 
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 8), 

                  Icon(
                    Icons.search,
                    size: 18, 
                    color: AppColors.purple500, 
                  ),

                  const SizedBox(width: 6), 

                  Expanded(
                    child: TextField(
                      style: AppText.small.copyWith(
                        fontSize: 12, 
                        color: Colors.black87, 
                      ),
                      decoration: const InputDecoration(
                        hintText: "Buscar...", 
                        border: InputBorder.none, 
                        isDense: true, 
                        contentPadding: EdgeInsets.symmetric(vertical: 2), 
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (q) {
                        print("Buscando: $q");
                      },
                    ),
                  ),

                ],
              ),
            )
            
          ],
        ),
      ),
    );
  }
}
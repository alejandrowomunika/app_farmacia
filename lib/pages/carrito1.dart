import 'package:app_farmacia/widgets/footer.dart';
import 'package:flutter/material.dart';
import '../data/cart.dart'; // Tu modelo de datos local
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:xml/xml.dart' as xml;

class CarritoPage extends StatefulWidget {
  const CarritoPage({super.key});

  @override
  State<CarritoPage> createState() => _CarritoPageState();
}

class _CarritoPageState extends State<CarritoPage> {
  int selectedIndex = 3;
  bool isLoading = false; // Para mostrar carga al pulsar finalizar

  final String apiKey = "CGVBYEAKW3KG46ZY4JQWT8Q8433F6YBS";

  @override
  void initState() {
    super.initState();
    // Cargamos el carrito guardado en el móvil al iniciar
    Cart.loadCart().then((_) => setState(() {}));
  }

  void onFooterTap(int index) {
    if (index == selectedIndex) return;

    if (index == 0) {
      Navigator.pushReplacementNamed(context, '/');
    } else if (index == 1) {
      Navigator.pushReplacementNamed(context, '/tienda');
    } else if (index == 2) {
      Navigator.pushReplacementNamed(context, '/chat');
    }
  }

  // ======================================================
  // FUNCIÓN CLAVE: CREAR Y LLENAR CARRITO EN PRESTASHOP
  // (Usa el método de 2 pasos: POST + PUT para fiabilidad)
  // ======================================================
  Future<int?> createPrestashopCart(List<CartItem> cart) async {
    
    // --- PASO 1: CREAR EL CONTENEDOR (CARRITO VACÍO) ---
    final urlCreate = Uri.parse(
        "https://www.farmaciaguerrerozieza.com/api/carts?ws_key=$apiKey");

    // id_customer 7 es tu usuario por defecto/invitado para la app
    final xmlCreate = """
<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <cart>
    <id_currency>1</id_currency>
    <id_lang>1</id_lang>
    <id_customer>7</id_customer>
    <id_shop_group>1</id_shop_group>
    <id_shop>1</id_shop>
  </cart>
</prestashop>
""";

    try {
      final resCreate = await http.post(
        urlCreate,
        headers: {"Content-Type": "application/xml"},
        body: xmlCreate,
      );

      if (resCreate.statusCode != 201 && resCreate.statusCode != 200) {
        print("Error paso 1 (Crear): ${resCreate.body}");
        return null;
      }

      // Extraemos el ID del nuevo carrito
      final parsedCreate = xml.XmlDocument.parse(resCreate.body);
      final idCart = parsedCreate.findAllElements('id').first.text;
      print("Carrito creado con ID: $idCart. Ahora añadiendo productos...");

      // --- PASO 2: METER LOS PRODUCTOS (PUT) ---
      final urlUpdate = Uri.parse(
        "https://www.farmaciaguerrerozieza.com/api/carts/$idCart?ws_key=$apiKey"
      );

      // Generamos el XML de los productos
      String cartRows = "";
      for (final item in cart) {
        cartRows += """
        <cart_row>
          <id_product>${item.id}</id_product>
          <id_product_attribute>0</id_product_attribute>
          <quantity>${item.quantity}</quantity>
        </cart_row>
        """;
      }

      // XML Completo para la actualización
      final xmlUpdate = """
<?xml version="1.0" encoding="UTF-8"?>
<prestashop xmlns:xlink="http://www.w3.org/1999/xlink">
  <cart>
    <id>$idCart</id>
    <id_currency>1</id_currency>
    <id_lang>1</id_lang>
    <id_customer>7</id_customer>
    <id_shop_group>1</id_shop_group>
    <id_shop>1</id_shop>
    <associations>
      <cart_rows>
        $cartRows
      </cart_rows>
    </associations>
  </cart>
</prestashop>
""";

      final resUpdate = await http.put(
        urlUpdate,
        headers: {"Content-Type": "application/xml"},
        body: xmlUpdate,
      );

      if (resUpdate.statusCode == 200) {
        return int.parse(idCart);
      } else {
        print("Error paso 2 (Productos): ${resUpdate.body}");
        return null;
      }

    } catch (e) {
      print("Excepción de conexión: $e");
      return null;
    }
  }

  // ======================================================
  // UI DEL CARRITO
  // ======================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Carrito")),
      body: Column(
        children: [
          Expanded(
            child: Cart.items.isEmpty
                ? const Center(child: Text("Tu carrito está vacío"))
                : ListView.builder(
                    itemCount: Cart.items.length,
                    itemBuilder: (context, index) {
                      final item = Cart.items[index];

                      return Card(
                        child: ListTile(
                          leading: Image.network(
                            item.image, 
                            width: 60,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                          ),
                          title: Text(item.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${item.quantity} x ${item.priceTaxIncl.toStringAsFixed(2)} € = ${(item.quantity * item.priceTaxIncl).toStringAsFixed(2)} €",
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // BOTÓN MENOS
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                    onPressed: () {
                                      setState(() {
                                        if (item.quantity > 1) {
                                          item.quantity--;
                                        } else {
                                          Cart.removeItem(item.id);
                                        }
                                      });
                                      // Guardamos localmente en el móvil
                                      Cart.saveCart();
                                    },
                                  ),
                                  Text(
                                    item.quantity.toString(),
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  // BOTÓN MÁS
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                    onPressed: () {
                                      setState(() {
                                        item.quantity++;
                                      });
                                      // Guardamos localmente en el móvil
                                      Cart.saveCart();
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),

          // BOTÓN FINALIZAR PEDIDO
          if (Cart.items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
                  ),
                  onPressed: isLoading ? null : () async {
                    setState(() => isLoading = true);

                    // 1. Creamos el carrito en el servidor y le metemos los productos
                    final idCart = await createPrestashopCart(Cart.items);

                    if (idCart != null) {
                      // 2. Si todo fue bien, abrimos la URL especial de la APP
                      final url = "https://www.farmaciaguerrerozieza.com/app-carrito?id_cart=$idCart";
                      
                      print("Abriendo checkout: $url");
                      
                      await launchUrl(
                        Uri.parse(url),
                        mode: LaunchMode.externalApplication // Abre navegador externo para cookies/pagos seguros
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Error al conectar con la tienda. Inténtalo de nuevo.'))
                      );
                    }
                    
                    setState(() => isLoading = false);
                  },
                  child: isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text(
                        "Finalizar Pedido",
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: AppFooter(
        currentIndex: selectedIndex,
        onTap: onFooterTap,
      ),
    );
  }
}
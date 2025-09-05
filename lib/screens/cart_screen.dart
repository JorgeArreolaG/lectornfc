import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'saldo_screen.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Map<int, int> cart;
  final VoidCallback onClear;
  final Function(int) onRemove;

  const CartScreen({
    required this.products,
    required this.cart,
    required this.onClear,
    required this.onRemove,
  });

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  String nfcStatus = "Desconocido";
  String bloqueHex = ""; // <-- aquí guardamos los bytes

  @override
  void initState() {
    super.initState();
    checkNFC();
  }

  Future<void> readBlock(int block) async {
    try {
      NFCTag tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 20));
      String apduAuth =
          "FF860000050100${block.toRadixString(16).padLeft(2, '0')}6000";
      await FlutterNfcKit.transceive(apduAuth);

      String apduRead =
          "FFCA00${block.toRadixString(16).padLeft(2, '0')}00";
      String response = await FlutterNfcKit.transceive(apduRead);

      List<int> bytes = [];
      for (int i = 0; i < response.length; i += 2) {
        bytes.add(int.parse(response.substring(i, i + 2), radix: 16));
      }

      setState(() {
        bloqueHex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
      });

      await FlutterNfcKit.finish();
    } catch (e) {
      setState(() {
        bloqueHex = "Error leyendo bloque: $e";
      });
    }
  }

  Future<void> pagar() async {
    final total = widget.cart.entries.fold<int>(
        0,
            (sum, item) =>
        sum + (widget.products[item.key]['price'] as int) * item.value);

    try {
      // 1️⃣ Poll NFC
      NFCTag tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 20));

      // 2️⃣ Leer saldo (bloque 4)
      String apduRead = "FFCA000400"; // bloque 4
      String saldoHex = await FlutterNfcKit.transceive(apduRead);

      // Convertir a int
      List<int> bytes = [];
      for (int i = 0; i < saldoHex.length; i += 2) {
        bytes.add(int.parse(saldoHex.substring(i, i + 2), radix: 16));
      }
      int currentBalance = bytes[0] + (bytes[1] << 8); // ejemplo para 2 bytes

      if (currentBalance < total) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Saldo insuficiente: \$${currentBalance}")),
        );
        await FlutterNfcKit.finish();
        return;
      }

      // 3️⃣ Autenticación bloque 4
      String apduAuth = "FF860000050100046000";
      await FlutterNfcKit.transceive(apduAuth);

      // 4️⃣ Actualizar saldo
      int newBalance = currentBalance - total;
      List<int> newBytes = [newBalance & 0xFF, (newBalance >> 8) & 0xFF] + List.filled(14, 0);
      String dataHex = newBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      String apduWrite = "FFD60004010$newBytes"; // ajustar APDU según la longitud correcta
      await FlutterNfcKit.transceive(apduWrite);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pago realizado ✅ Nuevo saldo: \$${newBalance}")),
      );
      widget.onClear();
      Navigator.pop(context);

      await FlutterNfcKit.finish();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error procesando pago: $e")),
      );
    }
  }


  Future<void> checkNFC() async {
    try {
      NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
      setState(() {
        switch (availability) {
          case NFCAvailability.available:
            nfcStatus = "Activo ✅";
            break;
          case NFCAvailability.disabled:
            nfcStatus = "Desactivado ❌";
            break;
          case NFCAvailability.not_supported:
            nfcStatus = "No soportado 📵";
            break;
          default:
            nfcStatus = "Desconocido";
        }
      });
    } catch (e) {
      setState(() {
        nfcStatus = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = widget.cart.entries.toList();
    final total = widget.cart.entries.fold<int>(
        0,
            (sum, item) =>
        sum + (widget.products[item.key]['price'] as int) * item.value);

    return Scaffold(
      appBar: AppBar(
        title: Text('Carrito de compras'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: widget.onClear,
            tooltip: 'Vaciar carrito',
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton.icon(
            onPressed: nfcStatus == "Activo ✅" ? pagar : null,

            icon: Icon(Icons.nfc),
            label: Text('Leer saldo tarjeta NFC'),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Text('Estado NFC: $nfcStatus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          Container(
            padding: EdgeInsets.all(8),
            color: Colors.grey.shade200,
            width: double.infinity,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Text('Bloque 4 (hex): $bloqueHex',
                  style: TextStyle(fontSize: 14, color: Colors.black87)),
            ),
          ),
          Expanded(
            child: cartItems.isEmpty
                ? Center(child: Text('El carrito está vacío 🛒'))
                : ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                final entry = cartItems[index];
                final product = widget.products[entry.key];
                final count = entry.value;

                return ListTile(
                  leading: Icon(product['icon'], color: Colors.blue),
                  title: Text(product['name']),
                  subtitle: Text(
                      'Cantidad: $count  •  Subtotal: \$${product['price'] * count}'),
                  trailing: IconButton(
                    icon: Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => widget.onRemove(entry.key),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: \$$total',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: nfcStatus == "Activo ✅"
                      ? () async {
                    try {
                      final uri = Uri.parse(
                          'https://prueba.creategati.net/pay');

                      final response = await http.post(
                        uri,
                        headers: {'Content-Type': 'application/json'},
                        body: jsonEncode({'amount': total}),
                      );

                      final data = jsonDecode(response.body);

                      if (data['success'] == true) {
                        int newBalance = data['balance'];
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Pago realizado ✅ Nuevo saldo: \$${newBalance}')),
                        );
                        widget.onClear();
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: ${data['error']}')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                            Text('Error procesando pago: $e')),
                      );
                    }
                  }
                      : null,
                  icon: Icon(Icons.shopping_cart_checkout),
                  label: Text('Pagar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

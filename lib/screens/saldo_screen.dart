import 'package:flutter/material.dart';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart';
import 'package:vibration/vibration.dart';

class NfcSaldoScreen extends StatefulWidget {
  const NfcSaldoScreen({super.key});

  @override
  _NfcSaldoScreenState createState() => _NfcSaldoScreenState();
}

class _NfcSaldoScreenState extends State<NfcSaldoScreen>
    with SingleTickerProviderStateMixin {
  String nfcStatus = "Desconocido";
  double saldoReal = 0;
  String bloqueHex = "";
  bool leyendo = false;

  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    checkNFC();

    // Animación de parpadeo
    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 1));
    _animation = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut))
      ..addListener(() {
        setState(() {});
      });
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> checkNFC() async {
    try {
      NFCAvailability availability = await FlutterNfcKit.nfcAvailability;
      setState(() {
        switch (availability) {
          case NFCAvailability.available:
            nfcStatus = "Activo ✅";
            startPolling();
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

  Future<void> startPolling() async {
    if (leyendo) return;
    leyendo = true;

    while (mounted) {
      try {
        NFCTag tag = await FlutterNfcKit.poll(timeout: Duration(seconds: 20));

        // Autenticación del bloque 4
        String apduAuth = "FF860000050100040600";
        await FlutterNfcKit.transceive(apduAuth);

        // Leer bloque 4
        String apduRead = "FFCA000400";
        String response = await FlutterNfcKit.transceive(apduRead);

        // Convertir a bytes
        List<int> bytes = [];
        for (int i = 0; i < response.length; i += 2) {
          bytes.add(int.parse(response.substring(i, i + 2), radix: 16));
        }

        // Guardar bytes y calcular saldo
        setState(() {
          bloqueHex =
              bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(' ');
          int saldoRaw = bytes[0] | (bytes[1] << 8);
          saldoReal = saldoRaw * 0.736; // Ajusta factor según tu tarjeta
        });

        // Vibrar al detectar tarjeta
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 200);
        }

        await FlutterNfcKit.finish();
        await Future.delayed(Duration(seconds: 1));
      } catch (e) {
        await FlutterNfcKit.finish();
        await Future.delayed(Duration(seconds: 1));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Saldo NFC')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Estado NFC: $nfcStatus',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Text('Bloque 4 (hex): $bloqueHex', style: TextStyle(fontSize: 14)),
            SizedBox(height: 32),
            Text('Saldo real: \$${saldoReal.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 32),
            Opacity(
              opacity: _animation.value,
              child: Text(
                'Acerca la tarjeta NFC al teléfono',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'La lectura comenzará automáticamente cuando la tarjeta esté cerca.',
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

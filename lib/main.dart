import 'package:flutter/material.dart';
import 'screens/shop_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NfcReader',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: ShopScreen(), // Pantalla inicial ahora es la del supermercado
    );
  }
}

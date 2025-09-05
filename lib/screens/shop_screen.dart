import 'package:flutter/material.dart';
import '../screens//product_card.dart';
import 'cart_screen.dart';

class ShopScreen extends StatefulWidget {
  @override
  _ShopScreenState createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final List<Map<String, dynamic>> products = [
    {'name': 'Manzana', 'price': 10, 'icon': Icons.apple},
    {'name': 'Pan', 'price': 15, 'icon': Icons.bakery_dining},
    {'name': 'Leche', 'price': 20, 'icon': Icons.local_drink},
    {'name': 'Huevos', 'price': 25, 'icon': Icons.egg},
    {'name': 'Queso', 'price': 30, 'icon': Icons.food_bank},
    {'name': 'Arroz', 'price': 12, 'icon': Icons.rice_bowl},
    {'name': 'Frijoles', 'price': 18, 'icon': Icons.grain},
    {'name': 'Aceite', 'price': 22, 'icon': Icons.oil_barrel},
    {'name': 'Tomate', 'price': 8, 'icon': Icons.local_florist},
  ];

  Map<int, int> cart = {};

  void addToCart(int index) {
    setState(() {
      cart[index] = (cart[index] ?? 0) + 1;
    });
  }

  void removeFromCart(int index) {
    setState(() {
      if ((cart[index] ?? 0) > 1) {
        cart[index] = cart[index]! - 1;
      } else {
        cart.remove(index);
      }
    });
  }

  void clearCart() {
    setState(() {
      cart.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Supermercado'),
        actions: [
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Text('Carrito: ${cart.values.fold(0, (a, b) => a + b)}'),
            ),
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CartScreen(
                    products: products,
                    cart: cart,
                    onClear: clearCart,
                    onRemove: removeFromCart,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: GridView.builder(
        padding: EdgeInsets.all(10),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemBuilder: (context, index) {
          final product = products[index];
          final count = cart[index] ?? 0;
          return ProductCard(
            name: product['name'],
            price: product['price'],
            icon: product['icon'],
            count: count,
            onAdd: () => addToCart(index),
            onRemove: count > 0 ? () => removeFromCart(index) : null,
          );
        },
      ),
    );
  }
}
